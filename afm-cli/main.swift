//
//  main.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation

// MARK: - Entry Point

func main() -> Int32 {
    var args = CommandLine.arguments
    // Drop executable path
    args.removeFirst()

    // If no arguments, show help
    if args.isEmpty {
        let helpCommand = HelpCommand()
        return helpCommand.execute(ParsedCommand(command: .help))
    }

    let parsed = ArgumentParser.parse(args) ?? ParsedCommand(command: .help)

    // Global flags
    if parsed.flags.contains("help") || parsed.flags.contains("h") {
        let helpCommand = HelpCommand()
        return helpCommand.execute(parsed)
    }
    if parsed.flags.contains("version") || parsed.flags.contains("v") {
        let versionCommand = VersionCommand()
        return versionCommand.execute(parsed)
    }

    // Execute the appropriate command
    let command: Command
    switch parsed.command {
    case .help:
        command = HelpCommand()
    case .version:
        command = VersionCommand()
    case .generate:
        command = GenerateCommand()
    }
    
    return command.execute(parsed)
}

CLIUtilities.exitWith(main())
