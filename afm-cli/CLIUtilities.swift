//
//  CLIUtilities.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Darwin
import Foundation

enum CLIUtilities {
    /// Exit the program with the given exit code
    static func exitWith(_ code: Int32) -> Never {
        exit(code)
    }

    /// Print to standard error
    static func eprint(_ items: Any...) {
        let message = items.map { String(describing: $0) }.joined(separator: " ")
        guard let data = (message + "\n").data(using: .utf8) else { return }
        try? FileHandle.standardError.write(contentsOf: data)
    }

    /// Read all stdin into a String (non-blocking if no stdin is piped)
    static func readStdin() -> String? {
        let stdin = FileHandle.standardInput
        // If stdin is a TTY (no pipe), return nil to indicate no input
        if isatty(STDIN_FILENO) != 0 { return nil }
        let data = try? stdin.readToEnd()
        guard let data, !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
