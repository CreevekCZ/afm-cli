//
//  ArgumentParserTests.swift
//  afm-cli-unit-tests
//
//  Created by Jan Kožnárek on 15.11.2025.
//

import Foundation
import Testing

struct ArgumentParserTests {
    @Test("Parse empty arguments returns help command")
    func parseEmptyArgs() {
        let result = ArgumentParser.parse([])
        #expect(result?.command == .help)
    }

    @Test("Parse help command")
    func parseHelp() {
        let result = ArgumentParser.parse(["help"])
        #expect(result?.command == .help)
    }

    @Test("Parse help with -h flag")
    func parseHelpShort() {
        let result = ArgumentParser.parse(["-h"])
        #expect(result?.command == .help)
    }

    @Test("Parse help with --help flag")
    func parseHelpLong() {
        let result = ArgumentParser.parse(["--help"])
        #expect(result?.command == .help)
    }

    @Test("Parse version command")
    func parseVersion() {
        let result = ArgumentParser.parse(["version"])
        #expect(result?.command == .version)
    }

    @Test("Parse version with -v flag")
    func parseVersionShort() {
        let result = ArgumentParser.parse(["-v"])
        #expect(result?.command == .version)
    }

    @Test("Parse version with --version flag")
    func parseVersionLong() {
        let result = ArgumentParser.parse(["--version"])
        #expect(result?.command == .version)
    }

    @Test("Parse default generate command")
    func parseGenerateDefault() {
        let result = ArgumentParser.parse(["What is Swift?"])
        #expect(result?.command == .generate)
        // The first token "What is Swift?" becomes the first positional in default case
        #expect(result?.positionals.contains("What is Swift?") == true)
    }

    @Test("Parse positional arguments")
    func parsePositionals() {
        let result = ArgumentParser.parse(["hello", "world"])
        #expect(result?.command == .generate)
        #expect(result?.positionals == ["hello", "world"])
    }

    @Test("Parse flags")
    func parseFlags() {
        let result = ArgumentParser.parse(["--debug", "--prompt", "value"])
        #expect(result?.command == .generate)
        #expect(result?.flags.contains("debug") == true)
        #expect(result?.options["prompt"] == "value")
    }

    @Test("Parse short flags cluster")
    func parseShortFlagsCluster() {
        let result = ArgumentParser.parse(["-abc"])
        #expect(result?.flags.contains("a") == true)
        #expect(result?.flags.contains("b") == true)
        #expect(result?.flags.contains("c") == true)
    }

    @Test("Parse option with value")
    func parseOptionWithValue() {
        let result = ArgumentParser.parse(["--file", "test.txt"])
        #expect(result?.options["file"] == "test.txt")
    }

    @Test("Parse option with equals")
    func parseOptionWithEquals() {
        let result = ArgumentParser.parse(["--file=test.txt"])
        #expect(result?.options["file"] == "test.txt")
    }

    @Test("Parse short option with value")
    func parseShortOptionWithValue() {
        let result = ArgumentParser.parse(["-f", "test.txt"])
        #expect(result?.options["f"] == "test.txt")
    }

    @Test("Parse prompt option")
    func parsePromptOption() {
        let result = ArgumentParser.parse(["--prompt", "Hello world"])
        #expect(result?.options["prompt"] == "Hello world")
    }

    @Test("Parse short prompt option")
    func parseShortPromptOption() {
        let result = ArgumentParser.parse(["-p", "Hello"])
        #expect(result?.options["p"] == "Hello")
    }

    @Test("Parse system prompt option")
    func parseSystemPromptOption() {
        let result = ArgumentParser.parse(["--system-prompt", "Be helpful"])
        #expect(result?.options["system-prompt"] == "Be helpful")
    }

    @Test("Parse short system prompt option")
    func parseShortSystemPromptOption() {
        let result = ArgumentParser.parse(["-s", "Be helpful"])
        #expect(result?.options["s"] == "Be helpful")
    }

    @Test("Parse conversation option")
    func parseConversationOption() {
        let result = ArgumentParser.parse(["--conversation", "conv.json"])
        #expect(result?.options["conversation"] == "conv.json")
    }

    @Test("Parse short conversation option")
    func parseShortConversationOption() {
        let result = ArgumentParser.parse(["-c", "conv.json"])
        #expect(result?.options["c"] == "conv.json")
    }

    @Test("Parse everything after -- as positional")
    func parseDoubleDash() {
        let result = ArgumentParser.parse(["generate", "--", "--flag", "value"])
        #expect(result?.positionals.contains("--flag") == true)
        #expect(result?.positionals.contains("value") == true)
    }

    @Test("Parse complex command")
    func parseComplexCommand() {
        let result = ArgumentParser.parse([
            "--prompt", "Hello",
            "--system-prompt", "Be friendly",
            "--verbose",
            "--file", "test.txt"
        ])
        #expect(result?.options["prompt"] == "Hello")
        #expect(result?.options["system-prompt"] == "Be friendly")
        #expect(result?.flags.contains("verbose") == true)
        #expect(result?.options["file"] == "test.txt")
    }

    @Test("Parse flag after option value")
    func parseFlagAfterOption() {
        let result = ArgumentParser.parse(["--file", "test.txt", "--verbose"])
        #expect(result?.options["file"] == "test.txt")
        #expect(result?.flags.contains("verbose") == true)
    }
}

// MARK: - ParsedCommand Tests

struct ParsedCommandTests {
    @Test("ParsedCommand initializes with command")
    func parsedCommandInitialization() {
        let parsed = ParsedCommand(command: .generate)
        #expect(parsed.command == .generate)
        #expect(parsed.flags.isEmpty == true)
        #expect(parsed.options.isEmpty == true)
        #expect(parsed.positionals.isEmpty == true)
    }

    @Test("ParsedCommand stores flags")
    func parsedCommandStoresFlags() {
        var parsed = ParsedCommand(command: .help)
        parsed.flags.insert("debug")
        parsed.flags.insert("verbose")
        #expect(parsed.flags.contains("debug") == true)
        #expect(parsed.flags.contains("verbose") == true)
        #expect(parsed.flags.count == 2)
    }

    @Test("ParsedCommand stores options")
    func parsedCommandStoresOptions() {
        var parsed = ParsedCommand(command: .generate)
        parsed.options["file"] = "test.txt"
        parsed.options["prompt"] = "Hello"
        #expect(parsed.options["file"] == "test.txt")
        #expect(parsed.options["prompt"] == "Hello")
        #expect(parsed.options.count == 2)
    }

    @Test("ParsedCommand stores positionals")
    func parsedCommandStoresPositionals() {
        var parsed = ParsedCommand(command: .generate)
        parsed.positionals = ["arg1", "arg2", "arg3"]
        #expect(parsed.positionals.count == 3)
        #expect(parsed.positionals[0] == "arg1")
        #expect(parsed.positionals[1] == "arg2")
        #expect(parsed.positionals[2] == "arg3")
    }

    @Test("ParsedCommand command enum cases")
    func parsedCommandEnumCases() {
        let help = ParsedCommand.Command.help
        let version = ParsedCommand.Command.version
        let generate = ParsedCommand.Command.generate

        #expect(help != version)
        #expect(version != generate)
        #expect(generate != help)
    }
}
