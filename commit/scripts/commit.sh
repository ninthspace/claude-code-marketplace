#!/bin/bash
# Run the commit skill non-interactively from a terminal.
# Usage: commit.sh [optional-custom-title]
if [ -z "$1" ]; then
    COMMAND="/commit"
else
    COMMAND="/commit $1"
fi
claude -p "$COMMAND" --allowedTools Bash,Read,Grep,Glob
