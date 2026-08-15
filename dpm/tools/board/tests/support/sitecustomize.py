"""Installs the network guard in a *spawned* interpreter, before its script runs.

``site`` imports ``sitecustomize`` at interpreter startup whenever this directory is on the child's
``PYTHONPATH``, which is the only hook that reaches a board the test starts as a subprocess. An
in-process ``monkeypatch`` constrains the test runner and says nothing at all about the process the
user actually runs.
"""

from netguard import install

install()
