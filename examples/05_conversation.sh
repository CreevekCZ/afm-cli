#!/usr/bin/env bash
# Conversation file: save/load multi-turn chat
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONV_FILE="${SCRIPT_DIR}/.example_conversation.json"
AFM="${1:-afm-cli}"
echo "=== Example 5: Conversation (-c file) ==="
rm -f "$CONV_FILE"
echo "Turn 1: $AFM -c $CONV_FILE \"What is the capital of France?\""
"$AFM" -c "$CONV_FILE" "What is the capital of France?"
echo
echo "Turn 2: $AFM -c $CONV_FILE \"What is the population of that city?\""
"$AFM" -c "$CONV_FILE" "What is the population of that city?"
echo
rm -f "$CONV_FILE"
