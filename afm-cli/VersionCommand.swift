//
//  VersionCommand.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation

struct VersionCommand: Command {
    func execute(_: ParsedCommand) -> Int32 {
        print("\(CLIConfig.programName) \(CLIConfig.programVersion)")
        return 0
    }
}
