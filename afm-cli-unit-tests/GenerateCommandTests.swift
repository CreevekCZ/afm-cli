//
//  GenerateCommandTests.swift
//  afm-cli-unit-tests
//
//  Created by Jan Kožnárek on 15.11.2025.
//

import Foundation
import Testing

struct GenerateCommandTests {
    // Create a testable version of GenerateCommand for testing private methods
    // We'll test the public interface and create test files for validation

    @Test("Generate command handles missing prompt")
    func generateCommandMissingPrompt() {
        let parsed = ParsedCommand(command: .generate)
        #expect(parsed.command == .generate)
        #expect(parsed.positionals.isEmpty)
        #expect(parsed.options.isEmpty)
    }

    @Test("Generate command accepts prompt in positionals")
    func generateCommandWithPositionals() {
        var parsed = ParsedCommand(command: .generate)
        parsed.positionals = ["What", "is", "Swift?"]
        #expect(parsed.positionals.joined(separator: " ") == "What is Swift?")
    }

    @Test("Generate command accepts prompt option")
    func generateCommandWithPromptOption() {
        var parsed = ParsedCommand(command: .generate)
        parsed.options["prompt"] = "Hello world"
        #expect(parsed.options["prompt"] == "Hello world")
    }

    @Test("Generate command accepts file option")
    func generateCommandWithFileOption() {
        var parsed = ParsedCommand(command: .generate)
        parsed.options["file"] = "test.txt"
        #expect(parsed.options["file"] == "test.txt")
    }
}

// MARK: - File Validation Tests

struct FileValidationTests {
    @Test("Create valid test text file")
    func createValidTextFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).txt")
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        let content = "This is a test file with valid UTF-8 text."
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: testFile.path) == true)

        let readContent = try String(contentsOf: testFile, encoding: .utf8)
        #expect(readContent == content)
    }

    @Test("Create valid JSON file")
    func createValidJSONFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        let json: [String: Any] = ["key": "value", "number": 42]
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try jsonData.write(to: testFile)

        #expect(FileManager.default.fileExists(atPath: testFile.path) == true)

        let loadedData = try Data(contentsOf: testFile)
        let loadedJson = try JSONSerialization.jsonObject(with: loadedData) as? [String: Any]
        #expect(loadedJson?["key"] as? String == "value")
    }

    @Test("Create valid JSONL file")
    func createValidJSONLFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).jsonl")
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        let lines = try [
            JSONSerialization.data(withJSONObject: ["id": 1, "name": "First"]),
            JSONSerialization.data(withJSONObject: ["id": 2, "name": "Second"]),
        ]
        let content = lines.compactMap { String(data: $0, encoding: .utf8) }.joined(separator: "\n")
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: testFile.path) == true)
    }

    @Test("File size check")
    func fileSizeCheck() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_size_\(UUID().uuidString).txt")
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        // Create a small file
        let smallContent = "Small file"
        try smallContent.write(to: testFile, atomically: true, encoding: .utf8)

        let attributes = try FileManager.default.attributesOfItem(atPath: testFile.path)
        guard let fileSize = attributes[.size] as? Int64 else { return }
        #expect(fileSize > 0)
        #expect(fileSize < 1024 * 1024) // Less than 1 MB
    }
}
