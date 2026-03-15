//
//  IntegrationTests.swift
//  afm-cli-unit-tests
//
//  Created by Jan Kožnárek on 15.11.2025.
//

import Foundation
import Testing

struct IntegrationTests {
    @Test("Full argument parsing workflow")
    func fullArgumentParsingWorkflow() {
        let args = ["--prompt", "Hello", "--system-prompt", "Be friendly", "--verbose"]
        let parsed = ArgumentParser.parse(args)

        #expect(parsed != nil)
        #expect(parsed?.command == .generate)
        #expect(parsed?.options["prompt"] == "Hello")
        #expect(parsed?.options["system-prompt"] == "Be friendly")
        #expect(parsed?.flags.contains("verbose") == true)
    }

    @Test("Conversation save and load roundtrip")
    func conversationRoundtrip() {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("roundtrip_\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        // Create conversation
        var conversation = Conversation()
        ConversationManager.addMessage(
            ConversationMessage(role: "user", content: "First message"),
            to: &conversation
        )
        ConversationManager.addMessage(
            ConversationMessage(role: "assistant", content: "First response"),
            to: &conversation
        )

        // Save
        let saved = ConversationManager.saveConversation(conversation, to: testFile.path)
        #expect(saved == true)

        // Load
        let loaded = ConversationManager.loadConversation(from: testFile.path)
        #expect(loaded != nil)
        #expect(loaded?.messages.count == 2)

        // Build prompt
        guard let loadedConversation = loaded else { return }
        let prompt = ConversationManager.buildPromptFromConversation(loadedConversation, newPrompt: "Second message")
        #expect(prompt.contains("First message") == true)
        #expect(prompt.contains("First response") == true)
        #expect(prompt.contains("Second message") == true)
    }

    @Test("Complex command with all options")
    func complexCommandWithAllOptions() {
        let args = [
            "--prompt", "Analyze this",
            "--system-prompt", "Be technical",
            "--verbose",
            "--conversation", "conv.json",
            "additional", "positional", "args"
        ]
        let parsed = ArgumentParser.parse(args)

        #expect(parsed?.command == .generate)
        #expect(parsed?.options["prompt"] == "Analyze this")
        #expect(parsed?.options["system-prompt"] == "Be technical")
        #expect(parsed?.options["conversation"] == "conv.json")
        #expect(parsed?.flags.contains("verbose") == true)
        // The remaining arguments become positionals
        #expect(parsed?.positionals.contains("positional") == true)
        #expect(parsed?.positionals.contains("args") == true)
    }
}
