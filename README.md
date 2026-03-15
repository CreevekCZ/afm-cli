# afm-cli

A Swift command-line interface tool for interacting with macOS Apple Intelligence foundation models.

## Features

- **Generate text** using Apple Intelligence foundation models
- **Structured JSON output** via `--schema` flag using `DynamicGenerationSchema`
- **Multiple input methods**: command-line arguments, files, or stdin (pipe)
- **File validation** to ensure compatible input
- **System prompt** support for controlling response style and format
- **Conversation management** with automatic context window overflow recovery
- **Help** and **Version** commands
- Comprehensive error handling for unsupported systems

## Requirements

- macOS 26.0 (Tahoe) or later
- Apple Silicon Mac (M1, M2, M3, M4, M5 or later)
- Apple Intelligence enabled in System Settings
- Xcode 26.0 or later (only required for building from source)

## Installation

### Homebrew (Recommended)

Install using Homebrew from the custom tap:

```bash
brew tap CreevekCZ/tap
brew install afm-cli
```

Or install in one command:

```bash
brew install CreevekCZ/tap/afm-cli
```

This will:
1. Add the custom tap repository
2. Download and install the pre-built binary
3. Make it available in your PATH

To update to the latest version:

```bash
brew upgrade afm-cli
```

### From Source

Run the install script from the project root:

```bash
./install.sh
```

This will:
1. Build the project in Release mode
2. Install the executable to `/usr/local/bin/afm-cli` (or `~/bin/` if sudo is not available)
3. Make it executable and verify the installation

## Usage

### Help

```bash
afm-cli --help
# or
afm-cli -h
```

### Version

```bash
afm-cli --version
# or
afm-cli -v
```

### Generate Text (Default Behavior)

Generate text using Apple Intelligence foundation models. The `generate` command is the default behavior:

```bash
# Basic usage - prompt as positional argument
afm-cli "What is Swift?"

# Explicit prompt option
afm-cli --prompt "Explain machine learning"

# From file
afm-cli --file prompt.txt

# From stdin (pipe)
echo "What is Apple Intelligence?" | afm-cli

# Multiple words as prompt
afm-cli "Write a short story about a robot learning to paint"

# With system prompt/pre-prompt to define response style
afm-cli --system-prompt "Respond in JSON format" --prompt "List 3 colors"
afm-cli -s "Write as a haiku" "Describe the ocean"
afm-cli --system-prompt "Use technical language" "Explain quantum computing"

# With conversation save/load
afm-cli -c conversation.json "Start a conversation"
afm-cli -c conversation.json "Continue our discussion"
```

### Structured JSON Output

Use `--schema` (or `--json-schema`) to request structured output conforming to a JSON Schema. The model uses Apple's `DynamicGenerationSchema` API to guarantee the output matches the requested shape.

**Supported JSON Schema types:** `string`, `integer`, `number`, `boolean`, `object`, `array`

```bash
# Inline JSON schema
afm-cli --schema '{"type":"object","properties":{"name":{"type":"string"},"population":{"type":"integer"}},"required":["name","population"]}' \
  "Tell me about Tokyo"

# Schema from a file
afm-cli --schema schema.json "List three Swift features"

# Nested schema (object with array property)
afm-cli --schema '{"type":"object","properties":{"items":{"type":"array","items":{"type":"string"}}}}' \
  "List five fruits"

# Combined with system prompt
afm-cli -s "You are a JSON API" --schema schema.json "Rate Swift as a language"
```

**Example `schema.json`:**
```json
{
  "title": "LanguageRating",
  "type": "object",
  "properties": {
    "name":        { "type": "string",  "description": "Language name" },
    "score":       { "type": "number",  "description": "Score from 0 to 10" },
    "pros":        { "type": "array",   "items": { "type": "string" } },
    "recommended": { "type": "boolean" }
  },
  "required": ["name", "score"]
}
```

Output is always pretty-printed JSON with sorted keys:
```json
{
  "name": "Swift",
  "pros": ["Safe", "Fast", "Expressive"],
  "recommended": true,
  "score": 9.2
}
```

**Options:**
- `--schema PATH_OR_JSON` — File path or inline JSON schema string
- `--json-schema PATH_OR_JSON` — Alias for `--schema`

### System Prompt (Pre-Prompt)

You can optionally provide a system prompt to guide the model's response style, format, or tone:

```bash
# Define response format
afm-cli --system-prompt "Respond in JSON format" --prompt "List 3 colors"

# Define writing style
afm-cli -s "Write as a haiku" "Describe the ocean"

# Define tone/approach
afm-cli --system-prompt "Use technical language" "Explain quantum computing"
afm-cli --system-prompt "Explain like I'm 5 years old" "What is gravity?"
```

The system prompt is prepended to your user prompt and helps guide how the model should respond. This is useful for:
- Defining output format (JSON, XML, markdown, etc.)
- Setting writing style (poetry, technical, casual, etc.)
- Specifying tone (professional, friendly, educational, etc.)
- Providing context or constraints

**Options:**
- `-s, --system-prompt TEXT` - Provide system prompt directly
- `--pre-prompt TEXT` - Alias for `--system-prompt`

### Conversation Management

Save and load conversation history using JSON files:

```bash
# Start a new conversation (creates file if it doesn't exist)
afm-cli -c conversation.json "Hello, I'm learning Swift"

# Continue the conversation (loads previous messages)
afm-cli -c conversation.json "Can you explain closures?"

# The conversation file stores the full history
cat conversation.json
```

**How it works:**
- If the file doesn't exist, a new conversation is created
- If the file exists, previous messages are loaded and included in the context
- Each exchange (user prompt + assistant response) is automatically saved
- The conversation maintains full context for multi-turn dialogues

**Context window overflow recovery:**
The on-device model has a 4096-token context window. When a long conversation
exceeds this limit, the tool automatically retries the request keeping only the
most recent 6 messages (3 exchanges). A warning is printed to stderr so you
know truncation occurred. The full conversation file is never modified — only
the in-memory context sent to the model is trimmed.

**Options:**
- `-c, --conversation PATH` - Path to JSON file for saving/loading conversation

### File Input Limitations

When using the `--file` option, the following restrictions apply:

- **Maximum file size**: 1 MB
- **Encoding**: UTF-8 text only
- **Format**: Plain text files only (binary files are rejected)
- **Content validation**:
  - File must not be empty
  - File must contain actual text (not just whitespace)
  - File must not contain null bytes (binary data)
  - File must contain mostly printable characters (≤5% non-printable allowed)

**Examples of invalid files:**
- Binary files (images, executables, etc.)
- Files larger than 1 MB
- Empty files or files with only whitespace
- Files with unsupported encodings (non-UTF-8)

**Error messages** will clearly indicate why a file was rejected.

## Building

### Using Xcode

1. Open `afm-cli.xcodeproj` in Xcode
2. Select the `afm-cli` scheme
3. Build (⌘B) or Run (⌘R)

### Using Command Line

```bash
# Debug build
xcodebuild -project afm-cli.xcodeproj -scheme afm-cli -configuration Debug build

# Release build
xcodebuild -project afm-cli.xcodeproj -scheme afm-cli -configuration Release build
```

## Error Handling

The tool provides detailed error messages for various scenarios:

### System Requirements
- **Framework not available**: Clear message about requirements
- **macOS version too old**: Version check error
- **Not Apple Silicon**: Hardware check error
- **Apple Intelligence not enabled**: Runtime error with guidance
- **Models not downloaded**: Runtime error with troubleshooting steps

### Context Window
The on-device model supports up to **4096 tokens** for the combined total of
instructions, conversation history, prompt, and response. When this limit is hit:

- **With `--conversation`**: The oldest messages are automatically dropped and
  the request is retried. A warning is printed to stderr.
- **Without `--conversation`**: An error is shown with advice to shorten your
  prompt or split the request into smaller parts.

### Schema Errors (`--schema`)
- **Invalid JSON / file not found**: Clear error identifying the input
- **Missing `"type"` field**: Explains that composition keywords (`$ref`, `allOf`, etc.) are not supported
- **Unsupported type**: Lists the supported types
- **Array schema missing `"items"`**: Points to the required field

### File Input Validation
- **File does not exist**: Clear error with file path
- **File too large**: Shows actual size and maximum allowed (1 MB for prompts)
- **Invalid encoding**: Indicates UTF-8 requirement
- **Binary file detected**: Identifies null bytes or excessive non-printable characters
- **Empty file**: Rejects files with no content or only whitespace
- **File read errors**: Provides specific error details

### Usage Errors
- **No prompt provided**: Shows usage examples
- **Invalid options**: Clear error messages for malformed arguments

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Created by Jan Kožnárek on 14.11.2025.
