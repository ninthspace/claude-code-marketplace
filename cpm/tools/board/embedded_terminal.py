"""An embedded PTY terminal widget for Textual (spike — option A).

Runs a child process (`claude …`) in a pseudo-terminal and renders its live
output *inside* a Textual widget, so a session can run in a pane covering the
epics + stories columns while the board stays mounted. This is the hard path the
design notes flagged: nesting a full-screen child TUI inside a sub-region of the
board's own TUI.

How it works:

- ``pty.openpty()`` gives a master/slave fd pair; the child is spawned with the
  slave as its stdio (so ``isatty()`` is true and it renders as a real terminal).
- ``pyte`` is the terminal *emulator*: master-fd bytes are fed to a
  :class:`pyte.Screen`, which maintains the cell grid, colours, and cursor. The
  widget paints that grid in :meth:`render_line`.
- Keystrokes are translated to terminal byte sequences and written to the master
  fd, so the child sees them as terminal input.
- The reader is registered on the event loop with ``add_reader`` — no threads.
  EOF (child exited) posts :class:`EmbeddedTerminal.Exited` so the host can close
  the pane.

Scope of the spike: correct on the common path (colours, cursor, keys, resize,
alt-screen). It is POSIX-only (``pty``/``termios``) and deliberately compact —
not a hardened terminal emulator.
"""

from __future__ import annotations

import fcntl
import os
import re
import signal
import struct
import termios
from typing import Callable

import pyte
from rich.segment import Segment
from rich.style import Style
from textual import events
from textual.message import Message
from textual.strip import Strip
from textual.widget import Widget

# --- key translation ---------------------------------------------------------

#: Textual key name → the bytes a terminal sends for it. Printable characters are
#: handled separately via ``event.character``; this covers the non-printables.
_KEY_BYTES: dict[str, bytes] = {
    "enter": b"\r",
    "tab": b"\t",
    "backspace": b"\x7f",
    "escape": b"\x1b",
    "space": b" ",
    "up": b"\x1b[A",
    "down": b"\x1b[B",
    "right": b"\x1b[C",
    "left": b"\x1b[D",
    "home": b"\x1b[H",
    "end": b"\x1b[F",
    "delete": b"\x1b[3~",
    "insert": b"\x1b[2~",
    "pageup": b"\x1b[5~",
    "pagedown": b"\x1b[6~",
}


def key_to_bytes(event: events.Key) -> bytes | None:
    """Translate a Textual key event to the bytes a real terminal would send.

    Returns ``None`` for a key we deliberately don't forward (so the caller can
    let it fall through — e.g. the close chord is handled before this).
    """
    if event.key in _KEY_BYTES:
        return _KEY_BYTES[event.key]
    # Ctrl+<letter> → control byte 0x01..0x1a (ctrl+a == 1).
    if event.key.startswith("ctrl+") and len(event.key) == 6 and event.key[5].isalpha():
        return bytes([ord(event.key[5].lower()) - ord("a") + 1])
    if event.character is not None and event.character.isprintable():
        return event.character.encode("utf-8")
    return None


# --- colour mapping ----------------------------------------------------------

#: pyte's named ANSI colours → hex. pyte reports colours as one of these names,
#: one of the eight ``bright*`` variants, the sentinel "default", or a 6-digit hex
#: string (256/true colour). Anything not covered here maps to default — Rich
#: rejects unknown names (e.g. "brightblue") with a ColorParseError, so this map
#: must be total over what pyte emits and the fallback must never pass a raw token
#: through.
_ANSI_HEX: dict[str, str] = {
    "black": "000000",
    "red": "cd0000",
    "green": "00cd00",
    "brown": "cdcd00",  # pyte's name for yellow
    "blue": "0000ee",
    "magenta": "cd00cd",
    "cyan": "00cdcd",
    "white": "e5e5e5",
    "brightblack": "7f7f7f",
    "brightred": "ff0000",
    "brightgreen": "00ff00",
    "brightbrown": "ffff00",  # bright yellow
    "brightyellow": "ffff00",
    "brightblue": "5c5cff",
    "brightmagenta": "ff00ff",
    "brightcyan": "00ffff",
    "brightwhite": "ffffff",
}

_HEX6 = re.compile(r"^[0-9a-fA-F]{6}$")


def _colour(name: str) -> str | None:
    """Map a pyte colour token to a Rich colour string, or ``None`` for default.

    Total by construction: a named colour resolves via ``_ANSI_HEX``, a 6-hex-digit
    token is a 256/true-colour cell, and anything else (including "default" and any
    name Rich can't parse) falls back to default so a render can never raise.
    """
    if name in _ANSI_HEX:
        return f"#{_ANSI_HEX[name]}"
    if _HEX6.match(name):
        return f"#{name}"
    return None


def _cell_style(char: "pyte.screens.Char") -> Style:
    """Build a Rich Style from a pyte cell's attributes."""
    return Style(
        color=_colour(char.fg),
        bgcolor=_colour(char.bg),
        bold=char.bold,
        italic=char.italics,
        underline=char.underscore,
        strike=char.strikethrough,
        reverse=char.reverse,
    )


class EmbeddedTerminal(Widget, can_focus=True):
    """A Textual widget that runs and renders a child process in a PTY."""

    DEFAULT_CSS = """
    EmbeddedTerminal {
        background: #101010;
    }
    """

    #: The one key the terminal does *not* forward — the escape hatch that closes
    #: the pane. F10 is chosen because interactive CLIs rarely bind it.
    CLOSE_KEY = "f10"

    class Exited(Message):
        """Posted when the child process ends (EOF on the PTY master)."""

        def __init__(self, terminal: "EmbeddedTerminal", exit_code: int | None) -> None:
            self.terminal = terminal
            self.exit_code = exit_code
            super().__init__()

    def __init__(
        self,
        argv: list[str],
        *,
        cwd: str,
        spawn: Callable[..., int] | None = None,
        id: str | None = None,
    ) -> None:
        """``spawn(argv, cwd, fd)`` forks/execs the child on the slave ``fd`` and
        returns its pid; injectable so the fork/exec is stubbable in tests."""
        super().__init__(id=id)
        self._argv = argv
        self._cwd = cwd
        self._spawn = spawn or _spawn_in_pty
        self._master_fd: int | None = None
        self._pid: int | None = None
        self._screen = pyte.Screen(80, 24)
        self._stream = pyte.ByteStream(self._screen)
        self._reader_registered = False

    # --- lifecycle -----------------------------------------------------------

    def on_mount(self) -> None:
        master_fd, slave_fd = os.openpty()
        self._master_fd = master_fd
        self._resize_pty()
        self._pid = self._spawn(self._argv, self._cwd, slave_fd)
        os.close(slave_fd)  # the child holds its own copy now
        os.set_blocking(master_fd, False)
        self.loop.add_reader(master_fd, self._on_readable)
        self._reader_registered = True
        self.focus()

    @property
    def loop(self):
        import asyncio

        return asyncio.get_event_loop()

    def _teardown(self, exit_code: int | None) -> None:
        if self._master_fd is not None:
            if self._reader_registered:
                self.loop.remove_reader(self._master_fd)
                self._reader_registered = False
            os.close(self._master_fd)
            self._master_fd = None
        if self._pid is not None:
            try:
                os.kill(self._pid, signal.SIGHUP)
                os.waitpid(self._pid, os.WNOHANG)
            except OSError:
                pass
            self._pid = None
        self.post_message(self.Exited(self, exit_code))

    def on_unmount(self) -> None:
        # Closing the pane (host removed us) must not leak the child or the reader.
        if self._master_fd is not None:
            self._teardown(None)

    # --- pty io --------------------------------------------------------------

    def _on_readable(self) -> None:
        assert self._master_fd is not None
        try:
            data = os.read(self._master_fd, 65536)
        except OSError:
            data = b""
        if not data:  # EOF → child exited
            code = self._reap()
            self._teardown(code)
            return
        self._stream.feed(data)
        self.refresh()

    def _reap(self) -> int | None:
        if self._pid is None:
            return None
        try:
            _, status = os.waitpid(self._pid, os.WNOHANG)
        except ChildProcessError:
            return None
        return os.waitstatus_to_exitcode(status) if status else 0

    def _resize_pty(self) -> None:
        if self._master_fd is None:
            return
        rows = max(self.size.height, 1)
        cols = max(self.size.width, 1)
        self._screen.resize(rows, cols)
        winsize = struct.pack("HHHH", rows, cols, 0, 0)
        fcntl.ioctl(self._master_fd, termios.TIOCSWINSZ, winsize)
        if self._pid is not None:
            try:
                os.kill(self._pid, signal.SIGWINCH)
            except ProcessLookupError:
                pass

    def on_resize(self, event: events.Resize) -> None:
        self._resize_pty()
        self.refresh()

    # --- input ---------------------------------------------------------------

    def on_key(self, event: events.Key) -> None:
        # Capture everything and forward to the child — the board's own bindings
        # must not fire while the terminal has focus. The sole exception is the
        # close chord, the escape hatch back to the board.
        event.stop()
        event.prevent_default()
        if event.key == self.CLOSE_KEY:
            self._teardown(self._reap())
            return
        data = key_to_bytes(event)
        if data is not None and self._master_fd is not None:
            os.write(self._master_fd, data)

    # --- render --------------------------------------------------------------

    def render_line(self, y: int) -> Strip:
        buffer = self._screen.buffer
        if y >= self._screen.lines:
            return Strip.blank(self.size.width)
        row = buffer[y]
        # Draw pyte's cursor as a reverse-video block on its cell, but only while
        # the pane has focus — a child app hides its own cursor, so without this
        # there's nothing to show where typing lands. Hidden when unfocused so a
        # stale block doesn't linger after you tab away.
        cursor = self._screen.cursor
        cursor_x = cursor.x if (not cursor.hidden and cursor.y == y and self.has_focus) else -1
        segments: list[Segment] = []
        for x in range(self._screen.columns):
            char = row[x]
            style = _cell_style(char)
            if x == cursor_x:
                style += Style(reverse=True)
            segments.append(Segment(char.data or " ", style))
        return Strip(segments, self._screen.columns)


def _spawn_in_pty(argv: list[str], cwd: str, slave_fd: int) -> int:
    """Fork/exec ``argv`` with ``slave_fd`` as its controlling terminal.

    Returns the child pid. The child gets its own session (``setsid``) and makes
    the slave its controlling tty, so full-screen terminal apps behave.
    """
    pid = os.fork()
    if pid == 0:  # child
        os.setsid()
        fcntl.ioctl(slave_fd, termios.TIOCSCTTY, 0)
        os.dup2(slave_fd, 0)
        os.dup2(slave_fd, 1)
        os.dup2(slave_fd, 2)
        if slave_fd > 2:
            os.close(slave_fd)
        os.chdir(cwd)
        env = dict(os.environ, TERM="xterm-256color")
        try:
            os.execvpe(argv[0], argv, env)
        except OSError:
            os._exit(127)
    return pid
