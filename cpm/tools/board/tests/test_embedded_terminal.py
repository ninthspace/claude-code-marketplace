"""Unit tests for the embedded PTY terminal widget's pure helpers (spike — A).

Key translation and colour mapping are Textual-mount-free, so they're asserted
directly. The widget's PTY lifecycle (fork/exec, reader, teardown) is exercised
through the board in `test_embedded_launch.py`.
"""

from __future__ import annotations

import pyte
from textual import events

from embedded_terminal import _cell_style, _colour, key_to_bytes


def key(name: str, character: str | None = None) -> events.Key:
    return events.Key(name, character)


# --- key translation ---------------------------------------------------------


def test_printable_characters_forward_as_utf8():
    assert key_to_bytes(key("a", "a")) == b"a"
    assert key_to_bytes(key("£", "£")) == "£".encode("utf-8")


def test_named_keys_map_to_terminal_sequences():
    assert key_to_bytes(key("enter")) == b"\r"
    assert key_to_bytes(key("backspace")) == b"\x7f"
    assert key_to_bytes(key("escape")) == b"\x1b"
    assert key_to_bytes(key("tab")) == b"\t"


def test_arrow_keys_map_to_ansi_cursor_sequences():
    assert key_to_bytes(key("up")) == b"\x1b[A"
    assert key_to_bytes(key("down")) == b"\x1b[B"
    assert key_to_bytes(key("right")) == b"\x1b[C"
    assert key_to_bytes(key("left")) == b"\x1b[D"


def test_ctrl_letter_maps_to_control_byte():
    assert key_to_bytes(key("ctrl+c")) == b"\x03"
    assert key_to_bytes(key("ctrl+a")) == b"\x01"
    assert key_to_bytes(key("ctrl+z")) == b"\x1a"


def test_unforwardable_key_returns_none():
    # A non-printable, unmapped key (e.g. a function key) is not sent to the child.
    assert key_to_bytes(key("f5")) is None


# --- colour mapping ----------------------------------------------------------


def test_colour_maps_default_named_and_hex():
    assert _colour("default") is None
    assert _colour("red") == "#cd0000"
    assert _colour("green") == "#00cd00"
    assert _colour("brown") == "#cdcd00"  # pyte's name for yellow
    assert _colour("00ff88") == "#00ff88"  # a 256/true-colour cell


def test_colour_maps_bright_variants_and_never_returns_a_raw_token():
    # Regression: pyte emits bright names like "brightblue"; returning them raw
    # made Rich raise ColorParseError on every render. They must resolve to hex,
    # and any unknown token must fall back to default (None), never a raw string.
    assert _colour("brightblue") == "#5c5cff"
    assert _colour("brightblack") == "#7f7f7f"
    assert _colour("brightwhite") == "#ffffff"
    assert _colour("not-a-real-colour") is None
    assert _colour("") is None


def test_cell_style_reads_pyte_attributes():
    screen = pyte.Screen(4, 1)
    stream = pyte.ByteStream(screen)
    # Bold red on default, then a plain char.
    stream.feed(b"\x1b[1;31mX\x1b[0mY")
    row = screen.buffer[0]

    bold_red = _cell_style(row[0])
    assert bold_red.bold is True
    assert _colour(row[0].fg) == "#cd0000"

    plain = _cell_style(row[1])
    assert plain.bold is False
    assert _colour(row[1].fg) is None  # default
