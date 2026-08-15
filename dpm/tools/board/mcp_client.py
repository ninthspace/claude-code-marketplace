"""The board's connection to a dpm server (AD2).

Everything the board knows about a project it learns by spawning ``bin/dpm-mcp.js`` and asking it
(FR2) — there is no second reader of the database, and no parser of dpm's markdown. This module
holds that conversation: where the executable is, the framing, the client, and the pool of one
server per project (AD4).

**Where the server is, resolved three ways** (ENV3), in this order:

1. ``$DPM_MCP_SERVER``, an explicit path, for when it is neither of the other two.
2. Beside this script — ``../../bin/dpm-mcp.js`` — which is both the checkout case and the
   installed case, because the board ships *inside* the plugin and this relative path resolves to
   whichever copy the running ``board.py`` belongs to.
3. The installed plugin cache, for the copy of ``board.py`` that was taken on its own: it is a PEP
   723 single-file script, so a user who copies just that file onto their ``PATH`` has no sibling
   ``bin/`` and every reason to expect the installed server to answer.

**The override is first, and a broken override is fatal rather than a fallback.** A developer with
both a checkout and an installed plugin is the ordinary case, and the whole reason to set the
variable is that the resolution order was about to pick the other one. A missing override that
quietly fell through to a *working* server would answer every query correctly from the wrong tree —
which is a confusion that survives a whole afternoon, because nothing looks broken.
"""

from __future__ import annotations

import asyncio
import json
import os
from collections import defaultdict, deque
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

# What makes a directory a dpm project, imported rather than restated: the pre-spawn check and the
# registry's `add` have to be asking the same question, or a project can be registrable and
# unreadable at once.
from registry import DATABASE
from cache import MISS, Cache, Stamp, stamp_of

#: Environment variable holding an explicit path to the server executable.
SERVER_OVERRIDE = "DPM_MCP_SERVER"

#: The server executable, relative to the dpm root that contains it.
SERVER_EXECUTABLE = Path("bin") / "dpm-mcp.js"

#: Where Claude Code installs plugins, relative to the user's home directory.
PLUGIN_CACHE = Path(".claude") / "plugins" / "cache"

#: The plugin directory holding dpm inside a marketplace's cache.
PLUGIN_NAME = "dpm"

#: The MCP revision the board opens with.
#:
#: dpm negotiates by *echoing* a revision it knows and answering anything else with its own newest,
#: so a stale value here is not a failure — it is a silent downgrade. The suite asserts this string
#: appears in `src/server/mcp.js`'s `SUPPORTED_PROTOCOLS`, which is the only thing that makes the
#: two agree rather than merely interoperate.
PROTOCOL_VERSION = "2025-06-18"

#: How the board identifies itself in the handshake.
CLIENT_INFO = {"name": "dpm-board", "version": "0.1.0"}

#: Where the server reports the schema it writes, inside the handshake's ``serverInfo`` (FR13, AD6).
#:
#: The handshake is the only place it can arrive: the connection is not open when ``initialize`` is
#: answered, and no read tool reports it. The board needs it because a cached answer produced under
#: an earlier schema is stale however untouched the database file is.
SCHEMA_VERSION = "schemaVersion"

#: dpm's read-only switch, set on every server the board spawns (AD1, ENVX3).
READ_ONLY = "DPM_READ_ONLY"

#: dpm's override for where the database lives — removed from a spawned server's environment.
DATABASE_OVERRIDE = "DPM_DATABASE"

#: FR11's name for a project with no database. Rendered with its remedy by 48-06.
NO_DATABASE = "no-database"

#: The state a project acquires when its server does not serve the tools the board calls (NFR5).
SURFACE_MISMATCH = "tool-surface-mismatch"

#: FR11's name for a server that starts and then cannot answer — a database it will not open, a
#: schema it does not understand. 48-06 renders it; it is named here because Story 6's `list` is
#: already able to reach it, and an unnamed one would be a traceback.
SERVER_FAILED = "server-failed"

#: FR11's name for a board that cannot find dpm at all. Board-level rather than per-project, and
#: it is a row state anyway: the browser reads each project in a worker of its own (NFR3), and the
#: only alternative to naming this is a traceback out of a worker with no screen to land on.
SERVER_MISSING = "no-dpm-server"

#: FR11's name for a database written by a newer dpm than the server reading it.
#:
#: **The server does not refuse it** — it serves the database read-only and says so on stderr, so
#: without this state the project renders as an ordinary success whose columns are missing whatever
#: the newer schema holds. That is the same observable as a project with no work in it.
SCHEMA_AHEAD = "schema-ahead"

#: FR11's name for a Node below dpm's floor (ENV2). Distinct from :data:`SERVER_FAILED` although the
#: observable is the same — the executable refuses and exits — because the remedies are unrelated:
#: one is "upgrade Node", the other is "read what the server said".
NODE_TOO_OLD = "node-below-floor"

#: What the board looks for in a server's stderr, and the state each signature names (FR11, ENV2).
#:
#: **This is the only place stderr is read for meaning, and it never becomes data** (NFR6). A
#: signature match names a *state*; it never contributes a row, a count or a title, and the line
#: itself is kept verbatim as a diagnostic beside it. The alternative was no alternative: nothing
#: crosses the protocol channel for either case. A schema-ahead server answers every read normally
#: (`src/server/index.js` logs the skew and serves read-only), and a Node below the floor never
#: speaks protocol at all — `bin/dpm-mcp.js` writes the refusal to stderr and exits 1, precisely so
#: it does not put a non-JSON-RPC byte on stdout.
#:
#: Each signature is a fragment of a message dpm builds in one place, and the suite reconciles them
#: against dpm's own source rather than trusting the copy here (Task 1.4).
DIAGNOSTIC_STATES: tuple[tuple[str, str], ...] = (
    ("is ahead of this server", SCHEMA_AHEAD),
    ("dpm requires Node >=", NODE_TOO_OLD),
)

#: What to do about each state (FR11), keyed on the state and stated once.
#:
#: **A state without its remedy is a slightly better error message**, and the six here have nothing
#: in common: create a database, update the plugin, upgrade Node, read what the server said. The
#: table is keyed rather than built at each raise site so that a state added to this module with no
#: remedy fails a test (Task 1.3) instead of rendering a row that names a problem and stops there.
#:
#: The *context* — which path, which tools disagreed, what the server actually said — is the
#: ``detail`` on :class:`Unreadable`, because it belongs to the occurrence rather than to the state.
#: **Each is short enough to survive its column.** A project row is one of three Miller columns and
#: a terminal clips rather than wraps, so a remedy written as a sentence arrives as its first half —
#: which is the same as no remedy for the user reading it, and worse for the one who thinks they
#: read it. What does not fit goes in the ``detail``, where the CLI's full-width row shows it.
REMEDIES: dict[str, str] = {
    NO_DATABASE: "run a dpm skill there",
    SCHEMA_AHEAD: "update the dpm plugin",
    NODE_TOO_OLD: "upgrade Node",
    SERVER_FAILED: "check its stderr",
    SERVER_MISSING: "install the dpm plugin",
    SURFACE_MISMATCH: "update board or plugin",
}

#: How long the failure path waits for the rest of a dead server's stderr.
#:
#: Bounded rather than unbounded: the drain ends at EOF and a process that has exited closes its
#: pipes, so this expires only if the exit is a lie — and a board that hung on a project's row
#: would be a worse answer than one that named the state it could see.
DRAIN_TIMEOUT = 2.0

#: Lines of the server's stderr kept per session.
#:
#: Bounded because a server lives as long as the board does (AD4), and an unbounded list of every
#: warning a long session produced is a leak that only shows up in the sessions people leave open.
DIAGNOSTIC_LINES = 200


def state_of(diagnostic: str) -> str | None:
    """The FR11 state one line of a server's stderr names, or ``None`` for an ordinary diagnostic.

    A function rather than an inline scan because both the *live* server and the one that died
    before it spoke go through it, and because a classification that only exists inside a method is
    a rule a test can reach only by standing a server up.
    """
    for signature, state in DIAGNOSTIC_STATES:
        if signature in diagnostic:
            return state

    return None


class ServerNotFound(RuntimeError):
    """No ``bin/dpm-mcp.js`` at any of the three locations, or an override pointing at nothing."""


class Framer:
    """Newline-delimited JSON out of a byte stream that knows nothing about messages (NFR6).

    A chunk is however many bytes were available when the read returned. It can hold half a
    message, three messages, or the tail of one and the head of the next, and the last of those is
    what makes a carry buffer necessary rather than tidy: a framer that waits for a newline and
    then parses everything it holds is correct until two responses land in one read.

    The buffer carries **bytes**, and each completed line is decoded on its own, so a multi-byte
    character split across the boundary is reassembled rather than half-decoded.
    """

    def __init__(self) -> None:
        self._carry = b""

    def feed(self, chunk: bytes) -> list[dict]:
        """Every message completed by ``chunk``, in order. The remainder is kept for the next one."""
        self._carry += chunk
        *complete, self._carry = self._carry.split(b"\n")

        return [self._parse(line) for line in complete if line.strip()]

    @staticmethod
    def _parse(line: bytes) -> dict:
        """One line of the protocol channel, or a refusal naming what arrived instead.

        Unparseable bytes on stdout are not noise to be skipped: stdout is the protocol channel and
        nothing else writes to it (diagnostics go to stderr, FR2). Anything else there means this
        is not the server we think it is, and dropping it silently leaves the board waiting for a
        reply that has already been ruined.
        """
        try:
            return json.loads(line)
        except json.JSONDecodeError as broken:
            raise ValueError(f"not JSON-RPC on the server's stdout: {line!r}") from broken


class ServerFailed(RuntimeError):
    """The server answered with a JSON-RPC error, or stopped answering at all."""

    def __init__(self, message: str, *, code: int | None = None, data: Any = None) -> None:
        super().__init__(message)
        self.code = code
        self.data = data


class MCPClient:
    """One conversation with one spawned ``bin/dpm-mcp.js``, over its stdio pipes (FR2).

    **Every read the board performs goes through :meth:`call`.** That is the point of routing it
    all through one object rather than letting each screen build its own query: FR2's "observable
    as a ``tools/call``" is then a property of a transcript this client can be asked for, not a
    claim about the code that a reviewer has to re-establish by reading every call site.

    Spawn parameters — ``cwd`` and ``env`` — belong to the caller rather than to this class. The
    pool (Story 4) is what decides that a server is launched at a project root and in read-only
    mode, and it can only be held to that if this does not quietly impose it as well.
    """

    def __init__(
        self,
        server: Path,
        *,
        cwd: Path,
        env: dict[str, str] | None = None,
        node: str = "node",
        on_diagnostic: Callable[[str], None] | None = None,
    ) -> None:
        self.server = server
        self.cwd = cwd
        self.env = env
        self.node = node
        self.protocol: str | None = None
        self.server_info: dict | None = None
        #: The last few lines the server wrote to stderr — surfaced, never parsed.
        self.diagnostics: deque[str] = deque(maxlen=DIAGNOSTIC_LINES)
        #: The FR11 state this server's diagnostics name, once one of them has (see
        #: :data:`DIAGNOSTIC_STATES`), and never re-decided after that. **First match wins**: the
        #: line that named a cause is the cause, and a later warning is noise arriving second — a
        #: last-wins rule would let an unrelated deprecation notice rename the state a user is
        #: reading. The line itself stays in ``diagnostics``, which is what the row renders beside
        #: the state.
        self.named_state: str | None = None
        self._on_diagnostic = on_diagnostic
        self._process: asyncio.subprocess.Process | None = None
        self._draining: asyncio.Task | None = None
        self._framer = Framer()
        self._unmatched: list[dict] = []
        self._next_id = 0
        #: Held by whichever request is reading stdout — see :meth:`_receive`.
        self._reading = asyncio.Lock()

    @property
    def pid(self) -> int | None:
        """The spawned server's process id, or ``None`` once it has been reaped.

        Exposed because "the process is gone" is a criterion (FR3) and the only way to check it is
        to have kept its id — a test that asked the client whether it *thinks* it closed would pass
        against a `close()` that returned without doing anything.
        """
        return None if self._process is None else self._process.pid

    async def start(self) -> MCPClient:
        """Spawn the server and complete the handshake; returns self, so a caller can chain."""
        self._process = await asyncio.create_subprocess_exec(
            self.node,
            str(self.server),
            cwd=str(self.cwd),
            env=self.env,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        # Started before the handshake, not after. A pipe nobody reads fills, and a server blocked
        # writing to stderr stops writing to stdout as well — so a server that complains loudly
        # enough during startup would hang the board before it ever answered `initialize`, with no
        # error anywhere and nothing to look at but a spinner.
        self._draining = asyncio.create_task(self._drain(self._process.stderr))

        handshake = await self._request(
            "initialize",
            {
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {},
                "clientInfo": CLIENT_INFO,
            },
        )

        self.protocol = handshake.get("protocolVersion")
        self.server_info = handshake.get("serverInfo")

        # A notification, so nothing comes back and nothing is waited for. MCP requires it after
        # the handshake, and a server that replied to it would be putting a stray message on the
        # protocol channel — which is why it is sent rather than skipped as a formality.
        await self._notify("notifications/initialized")

        return self

    async def call(self, tool: str | Call, arguments: dict | None = None) -> Any:
        """Invoke a tool and return its value, unwrapped from MCP's ``CallToolResult``.

        Takes a declared :class:`Call` or a bare name. Board code passes the declaration — that is
        what keeps the pinned surface (NFR5) derived from the call sites — and the bare name stays
        for the tests, which have to be able to ask for a tool the board would never declare.
        """
        name = tool.name if isinstance(tool, Call) else tool
        result = await self._request("tools/call", {"name": name, "arguments": arguments or {}})

        return self._unwrap(result)

    async def drained(self, timeout: float = DRAIN_TIMEOUT) -> None:
        """Wait for the rest of a dead server's stderr, so its state is classified and not raced.

        **The failure path only.** The drain ends at EOF, so on a server that is still running this
        would wait for the whole session; on one that refused and exited — a Node below the floor
        (ENV2) — the refusal is already in the pipe and this is what makes reading it deterministic
        rather than a matter of which task the loop happened to resume.

        Waits rather than awaits: :func:`asyncio.wait` returns on the timeout without cancelling
        and without raising, and a board that hung on one row would be a worse answer than one that
        named the state from what it had.
        """
        if self._draining is not None:
            await asyncio.wait({self._draining}, timeout=timeout)

    async def advertised(self) -> list[dict]:
        """The server's own ``tools/list``, for reconciling the declared surface against."""
        listing = await self._request("tools/list", {})

        return listing.get("tools", [])

    async def close(self) -> None:
        """Close stdin and let the server exit; kill it if it will not.

        Closing stdin is the polite half — the server's read loop ends and it shuts itself down.
        The wait is bounded because a hung child would otherwise hold the board open on the way
        out, which is the one moment a user cannot see a spinner and interpret it.
        """
        if self._process is None:
            return

        process, self._process = self._process, None

        if process.returncode is None:
            process.stdin.close()

            try:
                await asyncio.wait_for(process.wait(), timeout=5)
            except (asyncio.TimeoutError, TimeoutError):
                process.kill()
                await process.wait()

        if self._draining is not None:
            draining, self._draining = self._draining, None
            draining.cancel()

            # Awaited after cancelling, so a drain that is mid-read is finished with rather than
            # left as a pending task for the loop to complain about at shutdown.
            try:
                await draining
            except asyncio.CancelledError:
                pass

    async def _drain(self, stream: asyncio.StreamReader) -> None:
        """Read stderr for as long as the server writes it, and never parse a byte of it.

        **This deliberately does not use :class:`Framer`,** though it is the same split on the same
        delimiter. The two streams are different in kind: stdout is the protocol channel and its
        contents are messages; stderr is whatever Node, a warning, or a stack trace felt like
        emitting, and the day these share an implementation is the day a deprecation notice becomes
        a malformed reply.

        Read in chunks rather than by ``readline`` because a ``StreamReader`` raises past its line
        limit, and a single enormous stack trace would end the drain — reintroducing the very
        blockage the drain exists to prevent, at the worst possible moment.
        """
        carry = b""

        while True:
            chunk = await stream.read(4096)

            if not chunk:
                break

            *lines, carry = (carry + chunk).split(b"\n")

            for line in lines:
                self._diagnose(line)

        self._diagnose(carry)

    def _diagnose(self, line: bytes) -> None:
        """Record one line of diagnostics. ``errors="replace"`` because this is not a data path."""
        text = line.decode(errors="replace").rstrip()

        if not text:
            return

        self.diagnostics.append(text)

        if self.named_state is None:
            self.named_state = state_of(text)

        if self._on_diagnostic is not None:
            self._on_diagnostic(text)

    @staticmethod
    def _unwrap(result: dict) -> Any:
        """The tool's own value out of the protocol's envelope.

        ``structuredContent`` is the machine-readable copy and is preferred; the text block is the
        same value for a client on a revision that predates it. Reading the text as JSON rather
        than as a string matters — it is ``JSON.stringify`` output, and a board that treated it as
        display text would render a serialised object at the user.
        """
        if "structuredContent" in result:
            return result["structuredContent"]

        for block in result.get("content", []):
            if block.get("type") == "text":
                return json.loads(block["text"])

        return None

    async def _request(self, method: str, params: dict) -> dict:
        """Send a request and wait for the reply carrying its id."""
        self._next_id += 1
        identifier = self._next_id

        await self._send({"jsonrpc": "2.0", "id": identifier, "method": method, "params": params})

        reply = await self._receive(identifier)

        if "error" in reply:
            error = reply["error"]
            data = error.get("data")

            # Both halves, joined. JSON-RPC's `message` is the *category* — "Invalid params",
            # "Method not found" — and dpm puts what actually went wrong in `data.message`. A
            # surface that rendered only the first would tell a user their call was invalid and
            # never say which argument, which is the whole content of the complaint.
            detail = data.get("message") if isinstance(data, dict) else None
            category = error.get("message", "the server refused")

            raise ServerFailed(
                f"{category}: {detail}" if detail else category,
                code=error.get("code"),
                data=data,
            )

        return reply.get("result", {})

    async def _notify(self, method: str, params: dict | None = None) -> None:
        """Send a notification — no id, so no reply is expected and none is waited for."""
        await self._send({"jsonrpc": "2.0", "method": method, "params": params or {}})

    async def _send(self, message: dict) -> None:
        if self._process is None:
            raise ServerFailed(f"the server at {self.server} was not started")

        self._process.stdin.write(json.dumps(message).encode() + b"\n")
        await self._process.stdin.drain()

    async def _receive(self, identifier: int) -> dict:
        """Read until the reply to ``identifier`` arrives, keeping anything else that turns up.

        Replies are matched by id rather than taken in order because the protocol permits a server
        to answer out of order and to interleave notifications of its own. Nothing unmatched is
        discarded: a message this board did not ask for is still evidence about what the server is
        doing, and Story 3's transcript is only complete if it holds all of it.

        **One reader at a time, because a pipe has one.** Two requests can be in flight together —
        the browser builds an epic's preview and a story's in separate workers over one project's
        server — and ``StreamReader.read()`` refuses a second waiter outright. So the id matching
        above is not enough on its own: the coroutine holding the lock reads *everyone's* replies
        into ``_unmatched``, and the ones waiting find theirs there when their turn comes. It is
        deadlock-free because the holder only keeps reading until its own reply arrives, and a
        request that already has one never takes the lock at all.
        """
        while True:
            for position, message in enumerate(self._unmatched):
                if message.get("id") == identifier:
                    return self._unmatched.pop(position)

            async with self._reading:
                # Whoever held the lock may have read this reply while we waited for it, in which
                # case reading again would block on a server that has already answered.
                if any(message.get("id") == identifier for message in self._unmatched):
                    continue

                chunk = await self._process.stdout.read(65536)

                if not chunk:
                    raise ServerFailed(
                        f"the server at {self.server} closed its stdout before "
                        f"answering {identifier}"
                    )

                self._unmatched.extend(self._framer.feed(chunk))


def _dpm_root() -> Path:
    """The dpm tree this file belongs to — ``dpm/tools/board/mcp_client.py`` → ``dpm/``."""
    return Path(__file__).resolve().parents[2]


def _plugin_cache_root() -> Path:
    """The plugin cache root under the user's home directory."""
    return Path.home() / PLUGIN_CACHE


def _version_key(directory: Path) -> tuple[int, ...]:
    """Sort key for an installed version directory, so ``0.10.0`` outranks ``0.9.0``.

    A non-numeric component sorts below every numeric one rather than raising: the cache is not
    ours, and a directory named something unexpected should lose the comparison, not break the
    board for the versions beside it.
    """
    return tuple(int(part) if part.isdigit() else -1 for part in directory.name.split("."))


def installed_servers(cache_root: Path | None = None) -> list[Path]:
    """Every ``bin/dpm-mcp.js`` in the plugin cache, newest version first.

    Returned as a list rather than reduced here so that the caller — and a test — can see *which*
    installations were found. Marketplaces are searched together and versions compared across them,
    because two marketplaces carrying dpm is a packaging accident, not a choice the user made.
    """
    root = cache_root if cache_root is not None else _plugin_cache_root()

    if not root.is_dir():
        return []

    installs = [
        version
        for marketplace in root.iterdir()
        if (marketplace / PLUGIN_NAME).is_dir()
        for version in (marketplace / PLUGIN_NAME).iterdir()
        if (version / SERVER_EXECUTABLE).is_file()
    ]

    return [version / SERVER_EXECUTABLE for version in sorted(installs, key=_version_key, reverse=True)]


def server_path(
    *,
    override: str | None = None,
    dpm_root: Path | None = None,
    cache_root: Path | None = None,
) -> Path:
    """The ``bin/dpm-mcp.js`` this board will spawn (ENV3).

    Each source is injectable so a test can build all three and assert on the order, rather than
    asserting on whichever one the machine running the suite happens to have.

    Raises ``ServerNotFound`` when nothing resolves — naming every place that was looked, because
    the answer to "it says it can't find the server" is always which paths it tried.
    """
    explicit = override if override is not None else os.environ.get(SERVER_OVERRIDE)

    if explicit:
        chosen = Path(explicit).expanduser()

        if chosen.is_file():
            return chosen

        raise ServerNotFound(
            f"{SERVER_OVERRIDE} is set to {chosen}, and there is no server there. "
            "Unset it to fall back to the installed plugin or a checkout."
        )

    cache = cache_root if cache_root is not None else _plugin_cache_root()
    beside = (dpm_root if dpm_root is not None else _dpm_root()) / SERVER_EXECUTABLE

    if beside.is_file():
        return beside

    installed = installed_servers(cache)

    if installed:
        return installed[0]

    raise ServerNotFound(
        f"no {SERVER_EXECUTABLE} found: not beside this script ({beside}), "
        f"not in the plugin cache ({cache}), and {SERVER_OVERRIDE} is unset."
    )


@dataclass(frozen=True)
class Call:
    """One tool the board depends on, declared where it is called (NFR5).

    Holds the arguments the board *passes*, not the arguments the tool accepts. The reconciliation
    is one-directional for that reason: a server growing an argument is not a problem for a board
    that never sends it, and a server dropping one the board sends is.
    """

    name: str
    arguments: frozenset[str] = frozenset()


#: Every call the board declares, by tool name. Populated by :func:`declare` at import.
SURFACE: dict[str, Call] = {}


def declare(name: str, *arguments: str) -> Call:
    """Declare a call at the site that makes it, and return it to be used there.

    **The declaration and the call are the same object**, which is the whole point (NFR5). A
    hand-maintained list somewhere central is the failure this prevents one level up: it agrees
    perfectly with `tools/list` while the code that runs has drifted away from both.
    """
    call = Call(name, frozenset(arguments))
    SURFACE[name] = call

    return call


def reconcile(declared: dict[str, Call], advertised: list[dict]) -> list[str]:
    """Complaints about the board's declared surface against a server's ``tools/list`` (NFR5).

    Returns complaints rather than raising, so that the caller decides what a mismatch means — a
    test fails on it, a running board renders it as a state — and so that all of them are reported
    at once. A release that renamed three tools should say so three times, not stop at the first.

    **The floor comes first, and it is what makes the rest mean anything.** Two empty sets agree
    perfectly: a reconciliation with nothing declared, or against a server that advertised nothing,
    is a passing check that inspected nothing at all, and it looks exactly like a working one.
    """
    if not declared:
        return ["the board declares no tools at all, so there is nothing to reconcile"]

    if not advertised:
        return ["the server advertised no tools at all, so any declaration would pass"]

    served = {tool["name"]: tool for tool in advertised}
    complaints = []

    for call in declared.values():
        if call.name not in served:
            complaints.append(f"the board calls {call.name}, which this server does not serve")
            continue

        accepted = set(served[call.name].get("inputSchema", {}).get("properties", {}))
        missing = sorted(call.arguments - accepted)

        if missing:
            complaints.append(
                f"{call.name} does not accept {', '.join(missing)} — it accepts "
                f"{', '.join(sorted(accepted)) or 'nothing'}"
            )

    return complaints


class Unreadable(RuntimeError):
    """A project the board cannot read as it stands — a *named state*, not a crash (FR11).

    Carries the state's name and its remedy rather than a sentence, because the board renders it in
    a row beside projects that are fine and the two parts land in different places.

    **The remedy comes from :data:`REMEDIES` and is never passed in.** A remedy written at the raise
    site is a remedy per occurrence: the same state acquires slightly different advice depending on
    which code path reached it, and no test can hold the set to FR11's enumeration. What varies by
    occurrence is ``detail`` — the path, the complaints, what the server said — which is context and
    not advice.
    """

    def __init__(self, state: str, detail: str | None = None) -> None:
        remedy = REMEDIES.get(state, "")
        super().__init__(f"{state}: {remedy}" + (f" ({detail})" if detail else ""))
        self.state = state
        self.remedy = remedy
        self.detail = detail


class ServerPool:
    """One long-lived server per project, spawned on first read and reaped on exit (AD4, FR3).

    Startup is a process, a connection and a handshake. Paying that per query would put it on the
    interaction path, so a server is kept for the board's lifetime — and keyed on the **resolved**
    project root, so two registry entries reaching the same tree by different paths share one
    process rather than opening the same database twice.

    Used as an async context manager, which is what makes FR3's teardown criterion hold on the path
    that matters: not the clean exit, but the exception on the way out. A board that crashed with
    servers still running would leave one process per project holding a database open, and the
    user's next run would spawn another beside each of them.
    """

    def __init__(
        self,
        server: Path | None = None,
        *,
        env: dict[str, str] | None = None,
        node: str = "node",
        surface: dict[str, Call] | None = None,
        cache: Cache | None = None,
    ) -> None:
        self.server = server if server is not None else server_path()
        self.node = node
        #: The freshness cache, or ``None`` for a pool that always asks (FR13). Consulted *before*
        #: :meth:`client`, which is the whole point of it: a hit answers without spawning anything,
        #: and a cold board over a dozen projects starts one server rather than twelve.
        self.cache = cache
        #: The schema version the servers in this pool write, learned from the first handshake and
        #: the same for every project — it is a property of the executable, not of a database.
        #: ``None`` until one server has started, which is what makes an entry unservable until
        #: then rather than servable against a guess (AD6).
        self.schema: int | None = None
        # The declared surface as it stands when the pool is built, not read live on every spawn:
        # a test needs to substitute one, and every server in a pool should be held to the same
        # contract even if something imports a new call site halfway through a session.
        self.surface = dict(SURFACE if surface is None else surface)
        self._env = env if env is not None else read_only_environment()
        self._clients: dict[Path, MCPClient] = {}
        # A lock per root, created on demand. `defaultdict` is safe here because building a Lock
        # does not await, so no two coroutines can arrive at the same key and get different ones.
        self._spawning: dict[Path, asyncio.Lock] = defaultdict(asyncio.Lock)

    async def client(self, root: Path) -> MCPClient:
        """The server for ``root``, spawning it the first time and reusing it after.

        The lock covers the check *and* the spawn: a check that released before spawning would let
        two coroutines past for the same root and leave one of the two processes owned by nobody.
        Two projects rendering at once is the ordinary case for this board, not an edge.

        **One lock per root, not one for the pool** (NFR3). A single lock is held across the spawn,
        the handshake and the surface reconciliation, so a board opening on a dozen projects starts
        their servers strictly one after another — every project waiting on the startup time of
        every project registered before it. The rule being enforced is about one root at a time;
        anything wider than that is a queue.
        """
        key = root.resolve()

        async with self._spawning[key]:
            if key not in self._clients:
                self._refuse_without_a_database(key)

                client = MCPClient(self.server, cwd=key, env=self._env, node=self.node)

                try:
                    await client.start()
                    self._learn_schema(client)
                    await self._reconcile_or_refuse(client, key)
                except ServerFailed as refusal:
                    # A server that never spoke protocol, or stopped between the handshake and its
                    # tool list. Which failure it was is on its stderr and nowhere else — below
                    # dpm's floor the executable writes the refusal and exits 1, deliberately
                    # putting nothing on stdout (ENV2) — so the rest of that stream is read out
                    # before the state is named.
                    await client.drained()
                    # Closed before it is named, for the same reason the surface mismatch closes:
                    # this project renders a state for the rest of the session and a process that
                    # is somehow still up would hold its database open on behalf of a row that
                    # says the server failed.
                    await client.close()

                    raise self._named(client, refusal) from refusal

                self._clients[key] = client

        return self._clients[key]

    async def read(
        self, root: Path, tool: str, arguments: dict | None = None, *, fresh: bool = False
    ) -> Any:
        """One read of one project: the pool's whole interface for everything above it.

        **Every read is also where a running server's state is noticed** (FR11). A schema-ahead
        database is the case that needs it: the server serves it read-only and says so on stderr,
        so nothing about the reply distinguishes it from a project that simply holds less work.
        Checked after the call rather than before, because the diagnostic is written when the
        database is first opened — which is the first ``tools/call``, not the handshake.

        ``fresh`` bypasses the cache for this read and refreshes what it holds (FR13). It does not
        empty the cache — the entry is replaced by what the server just said, which is what a user
        pressing refresh is asking for.
        """
        name = tool.name if isinstance(tool, Call) else tool
        stamp = self._stamp(root)

        if self.cache is not None and not fresh:
            cached = self.cache.get(root, name, arguments, stamp)

            if cached is not MISS:
                return cached

        client = await self.client(root)

        try:
            answer = await client.call(tool, arguments)
        except ServerFailed as refusal:
            raise self._named(client, refusal) from refusal

        if client.named_state is not None:
            raise self._named(client, None)

        if self.cache is not None:
            # Stamped *after* the read, and with the schema this pool has now certainly learned:
            # the stamp taken above may have been ``None`` because nothing had started yet, and an
            # answer recorded under no stamp is an answer that can never be served.
            self.cache.put(root, name, arguments, self._stamp(root), answer)

        return answer

    def _stamp(self, root: Path) -> Stamp | None:
        """What a cached answer for ``root`` would be true of, as things stand (AD6)."""
        return stamp_of(root, self.schema)

    def _learn_schema(self, client: MCPClient) -> None:
        """Take the schema version from a completed handshake (FR13, AD6).

        A server that does not report one leaves this at ``None``, which is a cache that never
        serves rather than one that serves against a guess: an older dpm has an older derivation
        and is exactly the case the stamp exists for.
        """
        reported = (client.server_info or {}).get(SCHEMA_VERSION)

        if isinstance(reported, int):
            self.schema = reported

    @staticmethod
    def _named(client: MCPClient, refusal: ServerFailed | None) -> Unreadable:
        """The state a client is in, from what its stderr named or from the refusal itself.

        The fallback is :data:`SERVER_FAILED` rather than a raised exception: a server that failed
        for a reason nothing here has a signature for is still one of FR11's four states, and it is
        the one whose remedy is to read what the server said.

        **The detail is the server's own line where there is one** (ENV2). Below dpm's floor the
        executable writes a sentence naming both versions and exits; what the client saw of *that*
        is "the server closed its stdout", which is true and is not the reason. Captured here so
        the state carries the refusal it was classified from rather than the symptom.
        """
        state = client.named_state or SERVER_FAILED
        said = next((line for line in reversed(client.diagnostics) if state_of(line) == state), None)

        return Unreadable(state, detail=said or (str(refusal) if refusal is not None else None))

    async def close(self) -> None:
        """Reap every server. Failures are collected, not raised, so one bad exit reaps the rest."""
        clients, self._clients = list(self._clients.values()), {}

        for client in clients:
            await client.close()

        # The cache is written here rather than per read (FR13). One file for the whole session, and
        # the pool is the thing that knows the session is over — the app is handed a `clear` and
        # nothing else, so it never has to remember to flush what it never opened.
        if self.cache is not None:
            self.cache.save()

    async def _reconcile_or_refuse(self, client: MCPClient, root: Path) -> None:
        """Check the declared surface against this server, once, before anything is read (NFR5).

        A mismatch becomes a *state*, not a degradation. The observable behaviour of a renamed tool
        is an empty column, and an empty column is exactly what a project with no epics looks like
        — so a board that carried on would be reporting, in good faith, that there is no work
        anywhere. Refusing the project names the cause instead.

        The server is closed on the way out. It cannot answer what this board asks, and leaving it
        running would hold a database open for the rest of the session on behalf of a project that
        renders an error.
        """
        complaints = reconcile(self.surface, await client.advertised())

        if not complaints:
            return

        await client.close()

        raise Unreadable(
            SURFACE_MISMATCH,
            f"the server at {root} does not serve what this board calls: " + "; ".join(complaints),
        )

    @staticmethod
    def _refuse_without_a_database(root: Path) -> None:
        """FR3's guard: no database, no process.

        Deliberately a *second* refusal, duplicating what a read-only server would do on its own
        (48-01, spec 49): that one is what happens when the database disappears between this check
        and the open, and it cannot be relied on here because relying on it means spawning a
        process, waiting for a handshake, and asking a question whose answer was on disk all along.
        """
        if not (root / DATABASE).is_file():
            raise Unreadable(NO_DATABASE, f"no {DATABASE} in {root}")

    async def __aenter__(self) -> ServerPool:
        return self

    async def __aexit__(self, *_exception) -> None:
        await self.close()


def read_only_environment(base: dict[str, str] | None = None) -> dict[str, str]:
    """The environment every board-spawned server gets (FR3, ENVX3).

    Two settings, and the second is the one that is easy to leave out. ``DPM_READ_ONLY`` is the
    point of the exercise: the board is an observer and must not migrate, seed or create anything
    in a project it was only asked to look at.

    ``DPM_DATABASE`` is *removed*. It is dpm's own override for where the database lives, it is
    plausibly set in the shell a user starts the board from, and inherited it would point every
    spawned server at one database regardless of which project it was launched in — so every row on
    the board would render, identically, the status of whichever project that variable named.
    """
    environment = dict(os.environ if base is None else base)
    environment.pop(DATABASE_OVERRIDE, None)
    environment[READ_ONLY] = "1"

    return environment
