#!/usr/bin/env bash
# Basic prompt — positional argument or --prompt
AFM="${1:-afm-cli}"
echo "=== Example 1: Basic prompt ==="
echo "Command: $AFM \"What is Swift in one sentence?\""
echo
"$AFM" "What is Swift in one sentence?"
echo
