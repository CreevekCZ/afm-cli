#!/usr/bin/env bash
# Prompt from file (--file / -f)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AFM="${1:-afm-cli}"
PROMPT_FILE="${SCRIPT_DIR}/.example_prompt.txt"
printf "Summarize what Swift programming language is in two sentences.\n" > "$PROMPT_FILE"
echo "=== Example 8: File input (-f) ==="
echo "Command: $AFM --file $PROMPT_FILE"
echo
"$AFM" --file "$PROMPT_FILE"
echo
rm -f "$PROMPT_FILE"
