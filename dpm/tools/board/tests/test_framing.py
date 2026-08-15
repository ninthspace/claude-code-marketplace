"""Story 3, NFR6 — newline framing with a carry buffer `[tdd]`.

A chunk from a pipe is not a message. It is however many bytes happened to be available when the
read returned, which is the one thing about a subprocess transport that no amount of local testing
against a fast, small server will ever exercise: a message and a chunk coincide right up until the
day a project has enough documents that a response crosses the pipe buffer.

The split message is the obvious case. **The one this file exists for is the second**: a chunk
carrying the tail of one message and the head of the next. A framer that buffers until it sees a
newline and then parses everything it has passes the first case and silently mangles the second.
"""

from __future__ import annotations

import json

import pytest

from mcp_client import Framer


def encode(*messages: dict) -> bytes:
    """The wire form: one compact JSON object per line, newline-terminated.

    ``ensure_ascii=False`` because the server is Node and ``JSON.stringify`` emits raw UTF-8 rather
    than ``\\uXXXX`` escapes — which is the entire reason a multi-byte character can straddle a
    chunk boundary at all. Encoding these fixtures the Python default way would remove the hazard
    from the test and leave it in the wire.
    """
    return "".join(json.dumps(message, ensure_ascii=False) + "\n" for message in messages).encode()


def test_a_message_split_across_two_chunks_is_parsed_once_and_whole():
    message = {"jsonrpc": "2.0", "id": 1, "result": {"content": [{"type": "text", "text": "hi"}]}}
    wire = encode(message)
    framer = Framer()

    first = framer.feed(wire[:12])
    second = framer.feed(wire[12:])

    assert first == [], f"a partial message was parsed as though it were complete: {first}"
    assert second == [message]


def test_a_chunk_carrying_one_message_s_tail_and_the_next_message_s_head():
    """The case a naive buffer-until-newline framer gets wrong.

    Chunk two ends *inside* the second message, so the framer has to hand back the first message
    and keep the remainder — rather than parse what it has, or wait for a newline that has already
    gone past.
    """
    first = {"jsonrpc": "2.0", "id": 1, "result": {"tools": []}}
    second = {"jsonrpc": "2.0", "id": 2, "result": {"content": []}}
    wire = encode(first, second)
    boundary = len(json.dumps(first)) + 1 + 5  # the newline, then five bytes of the second message

    framer = Framer()

    assert framer.feed(wire[:boundary]) == [first], "the completed message was held back"
    assert framer.feed(wire[boundary:]) == [second], "the message straddling the boundary was lost"


def test_several_messages_in_one_chunk_all_arrive_in_order():
    messages = [{"jsonrpc": "2.0", "id": index, "result": {}} for index in range(1, 4)]

    assert Framer().feed(encode(*messages)) == messages


def test_a_multi_byte_character_split_across_the_boundary_survives():
    """Decoding per completed line rather than per chunk — the carry buffer holds bytes.

    A response describing a document titled with an em dash is not exotic, and a framer that
    decodes each chunk as it arrives raises `UnicodeDecodeError` on the half of the character it
    got, for a message that is perfectly well-formed.
    """
    message = {"jsonrpc": "2.0", "id": 1, "result": {"title": "Spec 48 — the board"}}
    wire = encode(message)
    dash = wire.index("—".encode())
    framer = Framer()

    assert framer.feed(wire[: dash + 1]) == []
    assert framer.feed(wire[dash + 1 :]) == [message]


def test_blank_lines_between_messages_are_not_messages():
    """A server that writes an extra newline is not sending an empty object."""
    message = {"jsonrpc": "2.0", "id": 1, "result": {}}

    assert Framer().feed(b"\n\n" + encode(message) + b"\n") == [message]


def test_a_line_that_is_not_json_is_refused_by_its_own_content():
    """Rejected loudly rather than skipped: stdout is a protocol channel and nothing else.

    Anything unparseable there means the server is not the server we think it is — a wrapper's
    banner, a Node warning misrouted — and dropping it quietly leaves a board waiting for a reply
    that was already ruined.
    """
    framer = Framer()

    with pytest.raises(ValueError) as refusal:
        framer.feed(b"Debugger listening on ws://127.0.0.1:9229\n")

    assert "Debugger listening" in str(refusal.value), (
        f"the refusal does not show what arrived: {refusal.value}"
    )
