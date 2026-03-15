//
//  ConversationManager.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation

enum ConversationManager {
    /// Load conversation from JSON file
    static func loadConversation(from filePath: String) -> Conversation? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            // File doesn't exist - return nil (caller will create new conversation)
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Conversation.self, from: data)
        } catch {
            CLIUtilities.eprint("Error: Cannot load conversation from \(filePath): \(error.localizedDescription)")
            CLIUtilities.eprint("Creating a new conversation instead.")
            return nil
        }
    }

    /// Save conversation to JSON file
    static func saveConversation(_ conversation: Conversation, to filePath: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(conversation)
            try data.write(to: URL(fileURLWithPath: filePath))
            return true
        } catch {
            CLIUtilities.eprint("Error: Cannot save conversation to \(filePath): \(error.localizedDescription)")
            return false
        }
    }

    /// Add a message to conversation
    static func addMessage(_ message: ConversationMessage, to conversation: inout Conversation) {
        conversation.messages.append(message)
        conversation.updatedAt = Date()
    }

    /// Build prompt from conversation history
    static func buildPromptFromConversation(_ conversation: Conversation, newPrompt: String) -> String {
        return buildPromptFromMessages(conversation.messages, newPrompt: newPrompt)
    }

    /// Build prompt from the most recent `maxMessages` messages in the conversation.
    /// Used as a fallback when the full conversation exceeds the model's context window.
    /// Returns the truncated prompt and whether truncation occurred.
    static func buildTruncatedPromptFromConversation(
        _ conversation: Conversation,
        newPrompt: String,
        maxMessages: Int = 6
    ) -> (prompt: String, wasTruncated: Bool) {
        let allMessages = conversation.messages
        guard allMessages.count > maxMessages else {
            return (buildPromptFromMessages(allMessages, newPrompt: newPrompt), false)
        }
        let recentMessages = Array(allMessages.suffix(maxMessages))
        return (buildPromptFromMessages(recentMessages, newPrompt: newPrompt), true)
    }

    private static func buildPromptFromMessages(_ messages: [ConversationMessage], newPrompt: String) -> String {
        guard !messages.isEmpty else {
            return newPrompt
        }

        var promptParts: [String] = []
        for message in messages {
            let roleLabel = message.role == "user" ? "User" : "Assistant"
            promptParts.append("\(roleLabel): \(message.content)")
        }
        promptParts.append("User: \(newPrompt)")
        return promptParts.joined(separator: "\n\n")
    }
}
