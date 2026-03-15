//
//  Conversation.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 17.11.2025.
//

import Foundation

struct Conversation: Codable {
    var messages: [ConversationMessage]
    var createdAt: Date
    var updatedAt: Date

    init(messages: [ConversationMessage] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
