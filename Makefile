# afm-cli — build, lint, format, examples
# Run: make help

AFM ?= afm-cli
EXAMPLES_DIR := examples
EXAMPLES := 01_basic 02_system_prompt 03_schema_inline 04_schema_file 05_conversation 06_stdin 07_help_version 08_file_input

.PHONY: help
.PHONY: run-examples examples test-schema
.PHONY: lint swiftlint lint-fix
.PHONY: format swiftformat
.PHONY: $(EXAMPLES)

# Default: show help
help:
	@echo ""
	@echo "  afm-cli Makefile"
	@echo "  ================"
	@echo ""
	@echo "  Examples (afm-cli usage)"
	@echo "  -------------------------"
	@echo "    make run-examples     Run all example scripts (01–08)"
	@echo "    make examples        Alias for run-examples"
	@echo "    make test-schema     Run schema test suite (use VERBOSE=1 for output)"
	@echo ""
	@echo "  Linting & formatting"
	@echo "  --------------------"
	@echo "    make lint            Run SwiftLint"
	@echo "    make swiftlint       Alias for lint"
	@echo "    make lint-fix        Run SwiftLint with --fix (autocorrect)"
	@echo "    make format          Run SwiftFormat (in-place)"
	@echo "    make swiftformat     Alias for format"
	@echo ""
	@echo "  Overrides"
	@echo "  ---------"
	@echo "    AFM=/path/to/afm-cli   Use custom binary for examples"
	@echo "    VERBOSE=1              Show afm-cli output in test-schema"
	@echo ""
	@echo "  Examples:  make run-examples  |  make lint  |  make format  |  make run-examples AFM=./build/Release/afm-cli"
	@echo ""

# ── Examples ─────────────────────────────────────────────────────────────────

run-examples: $(EXAMPLES)
	@echo ""
	@echo "=== All examples completed ==="

examples: run-examples

$(EXAMPLES):
	@$(EXAMPLES_DIR)/$@.sh $(AFM)

test-schema:
	@$(EXAMPLES_DIR)/test_schema.sh $(if $(VERBOSE),--verbose,) $(AFM)

# ── SwiftLint ───────────────────────────────────────────────────────────────

lint swiftlint:
	@swiftlint

lint-fix:
	@swiftlint --fix

# ── SwiftFormat ──────────────────────────────────────────────────────────────

format swiftformat:
	@swiftformat .
