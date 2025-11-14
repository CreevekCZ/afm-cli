//
//  ConversationMessage.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 17.11.2025.
//

import Foundation

struct ConversationMessage: Codable {
    let role: String
    let content: String
    let timestamp: Date?
    
    init(role: String, content: String, timestamp: Date? = nil) {
        self.role = role
        self.content = content
        self.timestamp = timestamp ?? Date()
    }
}
