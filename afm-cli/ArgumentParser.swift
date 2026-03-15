//
//  ArgumentParser.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation

enum ArgumentParser {
    static func parse(_ args: [String]) -> ParsedCommand? {
        // args excludes the executable path
        var iterator = args.makeIterator()
        guard let first = iterator.next() else { return ParsedCommand(command: .help) }

        func applyLongOption(_ key: String, it: inout IndexingIterator<[String]>, pc: inout ParsedCommand) -> String? {
            if let eqIndex = key.firstIndex(of: "=") {
                let optionKey = String(key[..<eqIndex])
                let optionVal = String(key[key.index(after: eqIndex)...])
                pc.options[optionKey] = optionVal
                return nil
            }
            let peek = it.next()
            if let peek = peek, !peek.hasPrefix("-") {
                pc.options[key] = peek
                return nil
            }
            pc.flags.insert(key)
            return peek
        }

        func parseRest(into pc: inout ParsedCommand, startingWith current: String?, using it: inout IndexingIterator<[String]>) {
            var currentToken = current
            while true {
                guard let token = currentToken ?? it.next() else { break }
                if token == "--" {
                    while let rest = it.next() {
                        pc.positionals.append(rest)
                    }
                    break
                } else if token.hasPrefix("--") {
                    let key = String(token.dropFirst(2))
                    currentToken = applyLongOption(key, it: &it, pc: &pc)
                    if currentToken != nil { continue }
                } else if token.hasPrefix("-") {
                    let shorts = token.dropFirst()
                    if shorts.count > 1 {
                        shorts.forEach { pc.flags.insert(String($0)) }
                    } else if let shortChar = shorts.first {
                        let key = String(shortChar)
                        let peek = it.next()
                        if let peek = peek, !peek.hasPrefix("-") {
                            pc.options[key] = peek
                        } else {
                            pc.flags.insert(key)
                            currentToken = peek
                            continue
                        }
                    }
                } else {
                    pc.positionals.append(token)
                }
                currentToken = nil
            }
        }

        switch first.lowercased() {
        case "help", "-h", "--help":
            var pc = ParsedCommand(command: .help)
            var it = Array(iterator).makeIterator()
            parseRest(into: &pc, startingWith: nil, using: &it)
            return pc
        case "version", "-v", "--version":
            var pc = ParsedCommand(command: .version)
            var it = Array(iterator).makeIterator()
            parseRest(into: &pc, startingWith: nil, using: &it)
            return pc
        default:
            // Default to generate command - treat first token as prompt if it's not a flag
            var pc = ParsedCommand(command: .generate)
            var rest = [first]
            while let nextToken = iterator.next() {
                rest.append(nextToken)
            }
            var it = rest.makeIterator()
            parseRest(into: &pc, startingWith: nil, using: &it)
            return pc
        }
    }
}
