//
//  HelpCommandTests.swift
//  afm-cli-unit-tests
//
//  Created by Jan Kožnárek on 15.11.2025.
//

import Foundation
import Testing

struct HelpCommandTests {
    @Test("Help command returns zero exit code")
    func helpCommandExitCode() {
        let command = HelpCommand()
        let parsed = ParsedCommand(command: .help)
        let exitCode = command.execute(parsed)
        #expect(exitCode == 0)
    }
}
