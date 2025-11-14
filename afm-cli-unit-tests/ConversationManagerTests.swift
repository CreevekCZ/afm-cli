//
//  ConversationManagerTests.swift
//  afm-cli-unit-tests
//
//  Created by Jan Kožnárek on 15.11.2025.
//

import Foundation
import Testing

struct ConversationManagerTests {
	@Test("Create empty conversation")
	func createEmptyConversation() {
		let conversation = Conversation()
		#expect(conversation.messages.isEmpty == true)
	}
    
	@Test("Create conversation with messages")
	func createConversationWithMessages() {
		let message1 = ConversationMessage(role: "user", content: "Hello")
		let message2 = ConversationMessage(role: "assistant", content: "Hi there!")
		let conversation = Conversation(messages: [message1, message2])
		#expect(conversation.messages.count == 2)
	}
    
	@Test("Add message to conversation")
	func testAddMessage() {
		var conversation = Conversation()
		let message = ConversationMessage(role: "user", content: "Test")
		ConversationManager.addMessage(message, to: &conversation)
		#expect(conversation.messages.count == 1)
		#expect(conversation.messages.first?.role == "user")
		#expect(conversation.messages.first?.content == "Test")
	}
    
	@Test("Build prompt from empty conversation")
	func buildPromptFromEmptyConversation() {
		let conversation = Conversation()
		let prompt = ConversationManager.buildPromptFromConversation(conversation, newPrompt: "New prompt")
		#expect(prompt == "New prompt")
	}
    
	@Test("Build prompt from conversation with history")
	func buildPromptFromConversationWithHistory() {
		let message1 = ConversationMessage(role: "user", content: "Hello")
		let message2 = ConversationMessage(role: "assistant", content: "Hi!")
		let conversation = Conversation(messages: [message1, message2])
		let prompt = ConversationManager.buildPromptFromConversation(conversation, newPrompt: "How are you?")
        
		#expect(prompt.contains("User: Hello") == true)
		#expect(prompt.contains("Assistant: Hi!") == true)
		#expect(prompt.contains("User: How are you?") == true)
	}
    
	@Test("Save and load conversation")
	func saveAndLoadConversation() throws {
		let tempDir = FileManager.default.temporaryDirectory
		let testFile = tempDir.appendingPathComponent("test_conversation_\(UUID().uuidString).json")
		defer {
			try? FileManager.default.removeItem(at: testFile)
		}
        
		let message1 = ConversationMessage(role: "user", content: "Hello")
		let message2 = ConversationMessage(role: "assistant", content: "Hi!")
		var conversation = Conversation(messages: [message1, message2])
        
		let saved = ConversationManager.saveConversation(conversation, to: testFile.path)
		#expect(saved == true)
        
		let loaded = ConversationManager.loadConversation(from: testFile.path)
		#expect(loaded != nil)
		#expect(loaded?.messages.count == 2)
		#expect(loaded?.messages[0].content == "Hello")
		#expect(loaded?.messages[1].content == "Hi!")
	}
    
	@Test("Load non-existent conversation returns nil")
	func loadNonExistentConversation() {
		let result = ConversationManager.loadConversation(from: "/nonexistent/path/conversation.json")
		#expect(result == nil)
	}
    
	@Test("Save conversation updates timestamps")
	func saveConversationUpdatesTimestamps() throws {
		let tempDir = FileManager.default.temporaryDirectory
		let testFile = tempDir.appendingPathComponent("test_timestamps_\(UUID().uuidString).json")
		defer {
			try? FileManager.default.removeItem(at: testFile)
		}
        
		let originalDate = Date(timeIntervalSince1970: 1000)
		var conversation = Conversation(messages: [], createdAt: originalDate, updatedAt: originalDate)
        
		// Add a message which should update updatedAt
		Thread.sleep(forTimeInterval: 0.1) // Small delay to ensure timestamp difference
		let message = ConversationMessage(role: "user", content: "Test")
		ConversationManager.addMessage(message, to: &conversation)
        
		#expect(conversation.updatedAt > originalDate)
	}
    
	@Test("Build prompt preserves message order")
	func buildPromptPreservesOrder() {
		let messages = [
			ConversationMessage(role: "user", content: "First"),
			ConversationMessage(role: "assistant", content: "Second"),
			ConversationMessage(role: "user", content: "Third")
		]
		let conversation = Conversation(messages: messages)
		let prompt = ConversationManager.buildPromptFromConversation(conversation, newPrompt: "Fourth")
        
		let firstIndex = prompt.range(of: "First")?.lowerBound
		let secondIndex = prompt.range(of: "Second")?.lowerBound
		let thirdIndex = prompt.range(of: "Third")?.lowerBound
		let fourthIndex = prompt.range(of: "Fourth")?.lowerBound
        
		#expect(firstIndex != nil)
		#expect(secondIndex != nil)
		#expect(thirdIndex != nil)
		#expect(fourthIndex != nil)
        
		if let first = firstIndex, let second = secondIndex, let third = thirdIndex, let fourth = fourthIndex {
			#expect(first < second)
			#expect(second < third)
			#expect(third < fourth)
		}
	}
}

// MARK: - ConversationMessage Tests

struct ConversationMessageTests {
	@Test("ConversationMessage initializes with role and content")
	func conversationMessageInitialization() {
		let message = ConversationMessage(role: "user", content: "Hello")
		#expect(message.role == "user")
		#expect(message.content == "Hello")
		#expect(message.timestamp != nil)
	}
    
	@Test("ConversationMessage with custom timestamp")
	func conversationMessageWithTimestamp() {
		let timestamp = Date(timeIntervalSince1970: 1000)
		let message = ConversationMessage(role: "assistant", content: "Hi", timestamp: timestamp)
		#expect(message.timestamp == timestamp)
	}
    
	@Test("ConversationMessage is Codable")
	func conversationMessageIsCodable() throws {
		let message = ConversationMessage(role: "user", content: "Test")
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		let data = try encoder.encode(message)
        
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		let decoded = try decoder.decode(ConversationMessage.self, from: data)
        
		#expect(decoded.role == message.role)
		#expect(decoded.content == message.content)
	}
}

