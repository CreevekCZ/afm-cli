//
//  Command.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation

protocol Command {
    func execute(_ parsed: ParsedCommand) -> Int32
}
