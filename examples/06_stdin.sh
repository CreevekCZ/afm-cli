#!/usr/bin/env bash
# Prompt from stdin (pipe)
AFM="${1:-afm-cli}"
echo "=== Example 6: Stdin (pipe) ==="
echo "Command: echo \"What is 2+2? Answer in one word.\" | $AFM"
echo
echo "What is 2+2? Answer in one word." | "$AFM"
echo
