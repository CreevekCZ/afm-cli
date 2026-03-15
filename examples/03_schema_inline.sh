#!/usr/bin/env bash
# Inline JSON schema for structured output
AFM="${1:-afm-cli}"
SCHEMA='{"type":"object","properties":{"name":{"type":"string"},"score":{"type":"number"}},"required":["name","score"]}'
echo "=== Example 3: Inline JSON schema ==="
echo "Command: $AFM --schema '<object schema>' \"Rate Swift as a language with name and score\""
echo
"$AFM" --schema "$SCHEMA" "Rate Swift as a language with a name and numeric score from 0 to 10"
echo
