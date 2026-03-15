#!/usr/bin/env bash

VERBOSE=0
AFM="afm-cli"
while [[ "$1" == --verbose || "$1" == -v ]]; do
    VERBOSE=1
    shift
done
AFM="${1:-$AFM}"
if [[ "$1" == "$AFM" ]]; then shift; fi

PASS=0
FAIL=0
LAST_OUTPUT=""

green() { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
red()   { printf '\033[0;31m✗ %s\033[0m\n' "$*"; }

pass() { green "$*"; PASS=$((PASS + 1)); }
fail() { red   "$*"; FAIL=$((FAIL + 1)); }

run_test() {
    local name="$1"; shift
    if LAST_OUTPUT=$("$AFM" "$@" 2>&1); then
        pass "$name"
        [[ "$VERBOSE" -eq 1 ]] && echo "  [output] $LAST_OUTPUT"
    else
        fail "$name (exit code $?)"
        echo "  output: $LAST_OUTPUT"
        LAST_OUTPUT=""
    fi
}

assert_json() {
    local name="$1"
    local output="$2"
    if echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
        pass "$name — valid JSON"
    else
        fail "$name — output is not valid JSON"
        echo "  got: $output"
    fi
}

assert_field() {
    local name="$1"
    local output="$2"
    local field="$3"
    if echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert '$field' in d" 2>/dev/null; then
        pass "$name — field '$field' present"
    else
        fail "$name — field '$field' missing"
        echo "  got: $output"
    fi
}

echo "=== afm-cli --schema flag tests ==="
echo "Binary: $AFM"
[[ "$VERBOSE" -eq 1 ]] && echo "Verbose: on (showing afm-cli output)"
echo

# ── Test 1: inline JSON schema (object with required fields) ──────────────────
echo "--- Test 1: inline schema, object with required fields ---"
SCHEMA='{"type":"object","properties":{"name":{"type":"string"},"score":{"type":"number"}},"required":["name","score"]}'
run_test "inline schema — raw call" --schema "$SCHEMA" "Rate Swift as a language with a name and numeric score"
assert_json "inline schema" "$LAST_OUTPUT"
assert_field "inline schema" "$LAST_OUTPUT" "name"
assert_field "inline schema" "$LAST_OUTPUT" "score"
echo

# ── Test 2: --json-schema alias ───────────────────────────────────────────────
echo "--- Test 2: --json-schema alias ---"
run_test "--json-schema alias" --json-schema "$SCHEMA" "Rate Python as a language"
assert_json "--json-schema alias" "$LAST_OUTPUT"
echo

# ── Test 3: schema from file ──────────────────────────────────────────────────
echo "--- Test 3: schema from file ---"
SCHEMA_FILE="$(mktemp /tmp/test_schema_XXXX.json)"
cat > "$SCHEMA_FILE" <<'EOF'
{
  "type": "object",
  "title": "Person",
  "properties": {
    "firstName": { "type": "string", "description": "First name" },
    "lastName":  { "type": "string", "description": "Last name" },
    "age":       { "type": "integer", "description": "Age in years" }
  },
  "required": ["firstName", "lastName", "age"]
}
EOF
run_test "schema from file" --schema "$SCHEMA_FILE" "Invent a fictional person"
assert_json "schema from file" "$LAST_OUTPUT"
assert_field "schema from file" "$LAST_OUTPUT" "firstName"
assert_field "schema from file" "$LAST_OUTPUT" "lastName"
assert_field "schema from file" "$LAST_OUTPUT" "age"
rm -f "$SCHEMA_FILE"
echo

# ── Test 4: array schema ──────────────────────────────────────────────────────
echo "--- Test 4: array of strings ---"
ARRAY_SCHEMA='{"type":"array","items":{"type":"string"},"minItems":3,"maxItems":3}'
run_test "array schema" --schema "$ARRAY_SCHEMA" "Give me exactly 3 programming languages"
assert_json "array schema" "$LAST_OUTPUT"
echo

# ── Test 5: nested object ─────────────────────────────────────────────────────
echo "--- Test 5: nested object ---"
NESTED='{"type":"object","properties":{"title":{"type":"string"},"author":{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}},"required":["title","author"]}'
run_test "nested object" --schema "$NESTED" "Describe a book"
assert_json "nested object" "$LAST_OUTPUT"
assert_field "nested object" "$LAST_OUTPUT" "title"
assert_field "nested object" "$LAST_OUTPUT" "author"
echo

# ── Test 6: combined with --system-prompt ─────────────────────────────────────
echo "--- Test 6: --schema combined with --system-prompt ---"
run_test "--schema + --system-prompt" \
    --system-prompt "You are a concise assistant." \
    --schema '{"type":"object","properties":{"answer":{"type":"string"}},"required":["answer"]}' \
    "What is 2+2?"
assert_json "--schema + --system-prompt" "$LAST_OUTPUT"
assert_field "--schema + --system-prompt" "$LAST_OUTPUT" "answer"
echo

# ── Test 7: error case — invalid schema ───────────────────────────────────────
echo "--- Test 7: invalid schema produces error (non-zero exit) ---"
ERR_OUTPUT=$("$AFM" --schema '{"not":"valid json schema"}' "test" 2>&1); EXIT=$?
if [[ $EXIT -ne 0 ]]; then
    pass "invalid schema — correctly rejected"
    [[ "$VERBOSE" -eq 1 ]] && echo "  [output] $ERR_OUTPUT"
else
    fail "invalid schema — should have failed but did not"
fi
echo

# ── Test 8: error case — non-existent schema file ────────────────────────────
echo "--- Test 8: non-existent schema file produces error ---"
ERR_OUTPUT=$("$AFM" --schema "/tmp/does_not_exist_afm_test.json" "test" 2>&1); EXIT=$?
if [[ $EXIT -ne 0 ]]; then
    pass "missing file — correctly rejected"
    [[ "$VERBOSE" -eq 1 ]] && echo "  [output] $ERR_OUTPUT"
else
    fail "missing file — should have failed but did not"
fi
echo

# ── Summary ───────────────────────────────────────────────────────────────────
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
