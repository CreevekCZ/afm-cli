# afm-cli examples

Example scripts demonstrating different ways to use `afm-cli`.

| Script | Description |
|--------|-------------|
| `01_basic.sh` | Simple prompt (positional argument) |
| `02_system_prompt.sh` | System prompt (`-s` / `--system-prompt`) for style/format |
| `03_schema_inline.sh` | Structured JSON output with inline `--schema` |
| `04_schema_file.sh` | Structured output using a schema file (`person_schema.json`) |
| `05_conversation.sh` | Multi-turn chat with `-c` / `--conversation` |
| `06_stdin.sh` | Prompt from stdin (pipe) |
| `07_help_version.sh` | `--help` and `--version` |
| `08_file_input.sh` | Prompt from file (`--file` / `-f`) |
| `test_schema.sh` | Test suite for `--schema` / `--json-schema` (run with `--verbose` to see output) |

## Run all examples (from project root)

```bash
make run-examples
# or with custom binary:
make run-examples AFM=./build/Release/afm-cli
```

Run the schema test suite:

```bash
make test-schema
make test-schema VERBOSE=1   # show afm-cli output
```

Or run a single example:

```bash
./examples/01_basic.sh
./examples/01_basic.sh /path/to/afm-cli
```

## Requirements

- `afm-cli` on `PATH`, or pass the binary as the first argument to each script.
- macOS with Apple Intelligence enabled for generate examples; help/version work without it.
