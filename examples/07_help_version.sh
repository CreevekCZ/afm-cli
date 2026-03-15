#!/usr/bin/env bash
# Help and version commands
AFM="${1:-afm-cli}"
echo "=== Example 7: Help ==="
"$AFM" --help
echo
echo "=== Example 7: Version ==="
"$AFM" --version
