//
//  CLIConfig.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation

struct CLIConfig {
    static let programName = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "afm-cli"
    static let programVersion = "0.1.1"
    
    static var usage: String {
        """
        Usage: \(programName) [options] [prompt]

        Generate text using Apple Intelligence foundation model.

        Options:
          -h, --help              Show this help information
          -v, --version           Show version
          -p, --prompt TEXT       Provide prompt directly (default if text provided)
          -f, --file PATH         Read prompt from file
          -s, --system-prompt TEXT   Optional pre-prompt to define response style/format
          --pre-prompt TEXT          Alias for --system-prompt
          -c, --conversation PATH Save/load conversation to/from JSON file
          --schema PATH_OR_JSON  Provide a JSON Schema for structured output.
                                 Accepts a file path (e.g. schema.json) or
                                 an inline JSON string. Output will be
                                 pretty-printed JSON matching the schema.
                                 Supported types: string, integer, number,
                                 boolean, object, array.
          --json-schema PATH_OR_JSON  Alias for --schema

        File Input Limitations (--file option):
          - Maximum file size: 1 MB
          - Encoding: UTF-8 text only
          - Format: Plain text files (no binary files)
          - Content: Must contain printable text (not empty or whitespace-only)

        Examples:
          \(programName) "What is Swift?"
          \(programName) --prompt "Explain machine learning"
          \(programName) --file prompt.txt
          echo "Tell me a story" | \(programName)
          \(programName) --system-prompt "Respond in JSON format" --prompt "List 3 colors"
          \(programName) -s "Write as a haiku" "Describe the ocean"
          \(programName) -c conversation.json "Continue our discussion"
          \(programName) --schema schema.json "List three Swift features"
          \(programName) --schema '{"type":"object","properties":{"name":{"type":"string"},"score":{"type":"number"}},"required":["name","score"]}' "Rate Swift as a language"
        """
    }
}

