"""A stand-in MCP server that writes down everything it is asked (FR2).

The real server is what the integration tests drive, and it is the only thing that proves the board
speaks a protocol dpm actually implements. It is however a poor witness: to show that *every* read
the board performs arrives as a `tools/call`, something has to record what arrived, and adding a
transcript to `bin/dpm-mcp.js` would put a test's apparatus in the shipped server.

So this answers the same handshake and records each line to a file, and the assertion becomes a
comparison against a transcript rather than a claim about code someone has read.

Configured entirely by environment, because it is spawned by the client under test and the client
takes no arguments for the server: ``RECORDING_TRANSCRIPT`` is where to append, ``RECORDING_STDERR``
is a line to emit on stderr before answering — the bait for FR2's stderr must-NOT — and
``RECORDING_SCHEMA`` is the schema version to report in the handshake, which is what the freshness
cache stamps against.

Its answers also carry the conditions it was launched under — cwd, argv, and every ``DPM_``
variable in its environment — which is what lets FR3's read-only criterion be asserted from the
spawned process rather than from the code that spawned it.
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

NOISE = os.environ.get("RECORDING_STDERR")
PROTOCOL = "2025-06-18"

#: The schema version this stand-in reports in its handshake, or none at all when unset.
#:
#: Unset by default, which is deliberately the *older* dpm: a server that reports no schema is the
#: case the cache has to treat as unservable, and making it the default means every test that does
#: not care about freshness runs against a pool that never serves an entry.
SCHEMA = os.environ.get("RECORDING_SCHEMA")

#: Seconds to wait before answering the handshake — NFR3's "before any spawned server has completed
#: its handshake", made observable.
#:
#: **The delay lives here rather than in the board.** An injection point added so a test can slow a
#: read down is production code with no production caller, and a call site can trip over it; a
#: server that is simply slow to answer is the condition NFR3 is actually about, and the board
#: cannot tell it from a real one.
DELAY = float(os.environ.get("RECORDING_DELAY", "0"))

#: What this stand-in advertises when asked for `tools/list`, overridable by `RECORDING_TOOLS`.
#:
#: Deliberately a *copy* of the shape dpm serves rather than anything derived from the board, so it
#: can be replaced with a renamed or rescoped one to plant NFR5's mismatch. That this default
#: agrees with the board proves nothing on its own — the integration test against the real
#: `bin/dpm-mcp.js` is what does that; this is here so the disagreements can be staged.
DEFAULT_TOOLS = [
    {"name": "list_epic", "inputSchema": {"properties": {"limit": {}, "offset": {}, "ready": {}}}},
    {"name": "list_story", "inputSchema": {"properties": {"limit": {}, "offset": {}, "ready": {}}}},
    {
        "name": "list_task",
        "inputSchema": {
            "properties": {"limit": {}, "offset": {}, "story_id": {}, "include_body": {}}
        },
    },
    {"name": "list_dependency", "inputSchema": {"properties": {"limit": {}, "offset": {}}}},
    {
        "name": "list_dependency_kind",
        "inputSchema": {"properties": {"limit": {}, "offset": {}, "include_retired": {}}},
    },
    {"name": "list_spec", "inputSchema": {"properties": {"limit": {}, "offset": {}}}},
    {"name": "list_retro", "inputSchema": {"properties": {"limit": {}, "offset": {}}}},
    {
        "name": "list_document_section",
        "inputSchema": {
            "properties": {"limit": {}, "offset": {}, "document_id": {}, "include_body": {}}
        },
    },
    {
        "name": "list_story_criterion",
        "inputSchema": {
            "properties": {"limit": {}, "offset": {}, "story_id": {}, "include_body": {}}
        },
    },
    # FR16's two reads. The properties are dpm's, not the board's: the board declares `limit` and
    # `offset` alone and calls both unscoped, and a stand-in advertising only what the board asks
    # for would agree with a board that had quietly stopped being able to scope them.
    {
        "name": "list_requirement",
        "inputSchema": {
            "properties": {"limit": {}, "offset": {}, "spec_id": {}, "include_body": {}}
        },
    },
    {
        "name": "list_coverage",
        "inputSchema": {
            "properties": {
                "limit": {}, "offset": {}, "requirement_id": {}, "story_criterion_id": {},
                "include_body": {},
            }
        },
    },
    # FR17's read, and the only tool on this list that takes nothing at all — dpm serves the
    # integrity report unbounded on purpose, because a truncated one is the report whose job is to
    # be trusted lying by omission.
    {"name": "check_integrity", "inputSchema": {"properties": {}}},
    # FR15's read. Paged like the list tools, and `query` is the one argument the board adds.
    {"name": "search", "inputSchema": {"properties": {"limit": {}, "offset": {}, "query": {}}}},
    # The document reads take an id and nothing else — a document has no withheld columns, so
    # there is no `include_body` on them and the board passes none.
    {"name": "read_epic", "inputSchema": {"properties": {"id": {}}}},
    {"name": "read_spec", "inputSchema": {"properties": {"id": {}}}},
    {"name": "read_retro", "inputSchema": {"properties": {"id": {}}}},
]


def transcript_of(path: Path) -> list[dict]:
    """Every message the stand-in received, in order; empty when it never started.

    Lives beside the code that writes the file so that one module owns the format — a reader kept
    in the test that happens to need it becomes two readers the moment a second test does.
    """
    if not path.exists():
        return []

    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def reply(identifier: int, result: dict) -> None:
    sys.stdout.write(json.dumps({"jsonrpc": "2.0", "id": identifier, "result": result}) + "\n")
    sys.stdout.flush()


def spawned_pids(path: Path) -> list[int]:
    """Every stand-in that ever started, by process id. Empty when none did."""
    if not path.exists():
        return []

    return [int(line) for line in path.read_text().split() if line.strip()]


def main() -> None:
    destination = os.environ["RECORDING_TRANSCRIPT"]
    register = os.environ.get("RECORDING_PIDS")

    if register:
        # Written to its own file rather than into the transcript, which carries protocol and
        # nothing else. It is what lets a test check that a *spawned* process is gone without
        # asking the pool, whose own account is the thing that would be wrong.
        with open(register, "a") as pids:
            pids.write(f"{os.getpid()}\n")

    for line in sys.stdin:
        with open(destination, "a") as transcript:
            transcript.write(line)

        message = json.loads(line)
        method = message.get("method")

        if NOISE and method == "tools/call":
            # Written before the real answer, so a client that parsed stderr would find this one
            # first and never notice it had.
            sys.stderr.write(NOISE + "\n")
            sys.stderr.flush()

        if "id" not in message:
            continue

        if method == "initialize":
            if DELAY:
                time.sleep(DELAY)

            reply(
                message["id"],
                {
                    "protocolVersion": PROTOCOL,
                    "capabilities": {"tools": {"listChanged": False}},
                    "serverInfo": {
                        "name": "recording-stand-in",
                        "version": "0",
                        **({"schemaVersion": int(SCHEMA)} if SCHEMA else {}),
                    },
                },
            )
        elif method == "tools/list":
            # `is None`, not a falsy check: an explicitly empty list is the floor's test case, and
            # it must reach the board as an empty list rather than as "no override given".
            override = os.environ.get("RECORDING_TOOLS")
            reply(
                message["id"],
                {"tools": DEFAULT_TOOLS if override is None else json.loads(override)},
            )
        elif method == "tools/call":
            # Reports its own launch conditions as data. FR3 asks that a spawned server be
            # read-only and rooted at the project, and the only witness that cannot be fooled by
            # the board's intentions is the process itself: this is its cwd, its argv, and the dpm
            # variables actually present in its environment.
            answer = {
                "from": "stdout",
                "tool": message["params"]["name"],
                # The shape dpm's `list_*` tools return, so a caller that reads the answer rather
                # than merely receiving it has something to read.
                "items": [],
                "returned": 0,
                "cwd": os.getcwd(),
                "argv": sys.argv,
                "dpm_environment": {
                    name: value for name, value in os.environ.items() if name.startswith("DPM_")
                },
            }
            reply(
                message["id"],
                {
                    "content": [{"type": "text", "text": json.dumps(answer)}],
                    "structuredContent": answer,
                },
            )
        else:
            reply(message["id"], {})


# Guarded, so that the module can be imported for `transcript_of` without a test finding itself
# serving a protocol on its own stdin.
if __name__ == "__main__":
    main()
