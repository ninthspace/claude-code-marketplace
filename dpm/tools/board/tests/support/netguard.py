"""Make the network unavailable, and record every socket the board opens (ENVX4).

Two different assertions live here and they are not the same one.

*The network is unavailable*: an ``AF_INET``/``AF_INET6`` socket, a ``create_connection`` and a
``getaddrinfo`` all refuse. That is the environment the suite is required to pass in, and installing
it everywhere is what stops the criterion being met vacuously by a suite that simply never tried.

*Nothing is opened at all*: every construction is appended to ``record`` first, whatever the family,
so a test can assert the board opened **no** socket rather than merely no *network* socket — the
board speaks newline-framed JSON-RPC over a child process's stdio pipes and has no other channel.

Local families are recorded and then allowed rather than refused, because ``asyncio``'s selector
event loop builds an ``AF_UNIX`` ``socketpair`` for its own self-pipe when it starts. Refusing that
would fail every async test in Story 3 onwards for a reason that has nothing to do with the network.
"""

from __future__ import annotations

import socket


class NetworkUnavailable(OSError):
    """Raised in place of any call that would reach the network."""


def install(record: list[str] | None = None, setattr_=setattr) -> list[str]:
    """Guard the ``socket`` module; returns the list that receives every construction.

    ``setattr_`` is the seam for pytest's ``monkeypatch.setattr``, so an in-process install is
    undone at the end of the test while the same code, called with the builtin, installs
    permanently in a spawned interpreter.
    """
    opened = [] if record is None else record
    network = (socket.AF_INET, socket.AF_INET6)

    # A *subclass*, not a function that returns one. `ssl.py` runs `class SSLSocket(socket)` at
    # import time, and `asyncio` imports `ssl` — so a guard that leaves a plain function where the
    # class was takes down every process that touches asyncio, which by Story 6 is the board.
    class Guarded(socket.socket):
        def __init__(self, family=socket.AF_INET, *args, **kwargs):
            opened.append(str(family))

            if family in network:
                raise NetworkUnavailable(f"a network socket was opened: {family}")

            super().__init__(family, *args, **kwargs)

    def refuse(*args, **kwargs):
        raise NetworkUnavailable(f"the network was reached: {args!r}")

    setattr_(socket, "socket", Guarded)
    setattr_(socket, "create_connection", refuse)
    setattr_(socket, "getaddrinfo", refuse)

    return opened
