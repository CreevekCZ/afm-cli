//
//  VersionCommandTests.swift
//  afm-cli-unit-tests
//
//  Created by Jan Kožnárek on 15.11.2025.
//

import Foundation
import Testing

struct VersionCommandTests {
    @Test("Version command returns zero exit code")
    func versionCommandExitCode() {
        let command = VersionCommand()
        let parsed = ParsedCommand(command: .version)
        let exitCode = command.execute(parsed)
        #expect(exitCode == 0)
    }
}
