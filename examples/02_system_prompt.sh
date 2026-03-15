#!/usr/bin/env bash
# System prompt (-s / --system-prompt) to control style/format
AFM="${1:-afm-cli}"
echo "=== Example 2: System prompt (haiku) ==="
echo "Command: $AFM -s \"Write as a haiku\" \"Describe the ocean\""
echo
"$AFM" -s "Write as a haiku" "Describe the ocean"
echo
