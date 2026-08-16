"""Story 3 — the MCP client against a stand-in and against the real server (FR2, ENV5).

Two kinds of test, and neither replaces the other. The stand-in records what arrived, which is the
only way to assert that a read *is* a `tools/call` rather than to assert that one happened. The
real `bin/dpm-mcp.js`, driven against a database built by dpm's own tools, is the only way to know
that the protocol this client speaks is the one dpm implements.
"""

from __future__ import annotations

import asyncio
import json
import os
import re
import sys
from pathlib import Path

import pytest

from conftest import DPM_ROOT, STAND_IN
from fixture_database import statuses, titles
from recording_server import transcript_of

from mcp_client import PROTOCOL_VERSION, MCPClient, server_path


async def stand_in(tmp_path: Path, **environment: str) -> tuple[MCPClient, Path]:
    """A started client talking to the recording stand-in, and the transcript it is filling."""
    transcript = tmp_path / "transcript.jsonl"
    client = MCPClient(
        STAND_IN,
        cwd=tmp_path,
        env={**os.environ, "RECORDING_TRANSCRIPT": str(transcript), **environment},
        node=sys.executable,
    )

    return await client.start(), transcript


async def test_every_read_arrives_at_the_server_as_a_tools_call(tmp_path):
    """FR2, as a transcript: the handshake, its notification, and then nothing but `tools/call`."""
    client, transcript = await stand_in(tmp_path)

    try:
        await client.call("list_epic")
        await client.call("list_story", {"epic_id": "e1"})
    finally:
        await client.close()

    methods = [message["method"] for message in transcript_of(transcript)]

    assert methods == [
        "initialize",
        "notifications/initialized",
        "tools/call",
        "tools/call",
    ], f"the board reached the server some other way: {methods}"


async def test_the_call_carries_the_tool_name_and_its_arguments(tmp_path):
    client, transcript = await stand_in(tmp_path)

    try:
        answer = await client.call("list_story", {"epic_id": "e1", "limit": 10})
    finally:
        await client.close()

    call = transcript_of(transcript)[-1]

    assert call["params"]["name"] == "list_story"
    assert call["params"]["arguments"] == {"epic_id": "e1", "limit": 10}
    # And the value comes back unwrapped from `CallToolResult` rather than as the envelope.
    assert answer["from"] == "stdout"
    assert answer["tool"] == "list_story"


async def test_nothing_arriving_on_stderr_is_parsed_as_data(tmp_path):
    """FR2's must-NOT, baited: the stand-in writes a *well-formed reply* to stderr, first.

    A client that read both streams into one framer would answer from this line and never know —
    it is valid JSON-RPC, it carries a plausible result, and it arrives before the real one.
    """
    bait = json.dumps({"jsonrpc": "2.0", "id": 2, "result": {"structuredContent": "from stderr"}})
    client, _ = await stand_in(tmp_path, RECORDING_STDERR=bait)

    try:
        answer = await client.call("list_epic")

        assert answer["from"] == "stdout", (
            f"the reply came from the diagnostic channel: {answer}"
        )
    finally:
        await client.close()

    # Surfaced, though — the requirement is that it is not *parsed*, not that it is thrown away.
    assert bait in "\n".join(client.diagnostics), (
        f"the stderr line was dropped rather than surfaced: {list(client.diagnostics)}"
    )


async def test_the_real_server_answers_over_stdio_against_a_built_database(fixture_project):
    """ENV5: `bin/dpm-mcp.js` itself, and a database built by dpm's own write tools."""
    client = await MCPClient(server_path(), cwd=fixture_project).start()

    try:
        epics = await client.call("list_epic")
        stories = await client.call("list_story")
    finally:
        await client.close()

    assert client.server_info["name"] == "dpm", f"that was not dpm: {client.server_info}"
    # Taken from the fixture's own content, in the order it creates them, so a later story adding
    # an epic does not turn this into an assertion about a shape the fixture no longer has.
    assert [epic["title"] for epic in epics["items"]] == titles("create_epic")
    assert {story["status"] for story in stories["items"]} == statuses("create_story")


async def test_two_reads_in_flight_at_once_each_get_their_own_answer(fixture_project):
    """One client, two overlapping calls — which is what the browser does, not a contrived case.

    A highlighted epic's preview and a highlighted story's are built in separate workers over the
    same project's server, so two coroutines reach ``_receive`` together. ``StreamReader.read()``
    refuses a second waiter with a ``RuntimeError``, and the id matching alone does not save it:
    the reply the second call is waiting for is on a pipe it is not allowed to read.

    Both halves are asserted. That neither raised is the regression; that each got *its own*
    answer is the part a lock could pass while handing both coroutines the same reply.
    """
    client = await MCPClient(server_path(), cwd=fixture_project).start()

    try:
        epics, specs = await asyncio.gather(client.call("list_epic"), client.call("list_spec"))
    finally:
        await client.close()

    assert [epic["title"] for epic in epics["items"]] == titles("create_epic")
    assert [spec["title"] for spec in specs["items"]] == titles("create_spec")


async def test_a_tool_the_server_refuses_is_raised_rather_than_returned(fixture_project):
    """The failure path over the real server, so FR11's surface (48-06) has something to render."""
    from mcp_client import ServerFailed

    client = await MCPClient(server_path(), cwd=fixture_project).start()

    try:
        with pytest.raises(ServerFailed) as refusal:
            await client.call("no_such_tool")
    finally:
        await client.close()

    assert "no_such_tool" in str(refusal.value), f"the refusal does not name the tool: {refusal}"


def test_the_protocol_version_is_one_the_server_supports():
    """The coupling that fails silently: dpm answers an unknown revision with its own newest.

    So a stale constant here is not an error at either end — it is a downgrade, invisible from both
    sides, and this is the only thing that catches it.
    """
    source = (DPM_ROOT / "src" / "server" / "mcp.js").read_text()
    declared = re.search(r"SUPPORTED_PROTOCOLS = \[(.*?)\]", source, re.S)

    assert declared, "SUPPORTED_PROTOCOLS is no longer where this test looks for it"

    supported = re.findall(r"'([^']+)'", declared.group(1))

    assert PROTOCOL_VERSION in supported, (
        f"the board opens with {PROTOCOL_VERSION}; the server supports {supported}"
    )
