#!/usr/bin/env bash
# JSON schema from file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AFM="${1:-afm-cli}"
SCHEMA_FILE="${SCRIPT_DIR}/person_schema.json"
echo "=== Example 4: Schema from file ==="
echo "Command: $AFM --schema $SCHEMA_FILE \"Invent a fictional person\""
echo
"$AFM" --schema "$SCHEMA_FILE" "Invent a short fictional person (first name, last name, age)"
echo
