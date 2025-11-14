//
//  HelpCommand.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation

struct HelpCommand: Command {
    func execute(_ parsed: ParsedCommand) -> Int32 {
        print(CLIConfig.usage)
        return 0
    }
}

