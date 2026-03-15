//
//  ParsedCommand.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 17.11.2025.
//

import Foundation

struct ParsedCommand {
    enum Command {
        case help
        case version
        case generate
    }

    var command: Command
    var flags: Set<String> = []
    var options: [String: String] = [:]
    var positionals: [String] = []
}
