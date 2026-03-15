//
//  GenerateCommand.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation
#if canImport(AppleFoundationModels)
    import AppleFoundationModels
#elseif canImport(FoundationModels)
    import FoundationModels
#endif

struct GenerateCommand: Command {
    func execute(_ parsed: ParsedCommand) -> Int32 {
        #if canImport(AppleFoundationModels) || canImport(FoundationModels)
            return executeWithFramework(parsed)
        #else
            return executeWithoutFramework(parsed)
        #endif
    }

    #if canImport(AppleFoundationModels) || canImport(FoundationModels)
        private func executeWithFramework(_ parsed: ParsedCommand) -> Int32 {
            // Check system requirements
            guard SystemChecker.checkAllRequirements() else {
                return 1
            }

            // Get prompt from various sources
            guard let userPrompt = extractPrompt(from: parsed) else {
                CLIUtilities.eprint("Error: No prompt provided.")
                CLIUtilities.eprint("Usage:")
                CLIUtilities.eprint("  \(CLIConfig.programName) \"Your question here\"")
                CLIUtilities.eprint("  \(CLIConfig.programName) --prompt \"Your question\"")
                CLIUtilities.eprint("  \(CLIConfig.programName) --file prompt.txt")
                CLIUtilities.eprint("  echo \"Your question\" | \(CLIConfig.programName)")
                return 1
            }

            // Get system prompt/pre-prompt if provided
            let systemPrompt = extractSystemPrompt(from: parsed)

            // Handle conversation save/load
            let conversationFile = parsed.options["conversation"] ?? parsed.options["c"]
            var conversation: Conversation?

            if let conversationFile = conversationFile {
                // Try to load existing conversation
                if let loadedConversation = ConversationManager.loadConversation(from: conversationFile) {
                    conversation = loadedConversation
                } else {
                    // If file doesn't exist or is invalid, create new conversation
                    // (loadConversation returns nil for non-existent files, which is fine)
                    conversation = Conversation()
                }
            }

            // Build final prompt (with conversation history if available)
            var basePrompt: String
            if let conversation = conversation {
                basePrompt = ConversationManager.buildPromptFromConversation(conversation, newPrompt: userPrompt)
            } else {
                basePrompt = userPrompt
            }

            // Store conversation file path for later use
            let conversationFilePath = conversationFile

            // Use a semaphore to wait for async completion
            let semaphore = DispatchSemaphore(value: 0)
            var exitCode: Int32 = 0
            let schemaString = extractSchemaString(from: parsed)

            Task {
                do {
                    let outputText = try await respondHandlingOverflow(
                        basePrompt: basePrompt,
                        systemPrompt: systemPrompt,
                        schemaString: schemaString,
                        conversation: conversation,
                        userPrompt: userPrompt
                    )

                    // Save conversation if conversation file is specified
                    if let conversationFilePath = conversationFilePath, var conversation = conversation {
                        // Add user message
                        ConversationManager.addMessage(
                            ConversationMessage(role: "user", content: userPrompt),
                            to: &conversation
                        )
                        // Add assistant response
                        ConversationManager.addMessage(
                            ConversationMessage(role: "assistant", content: outputText),
                            to: &conversation
                        )
                        // Save conversation
                        if ConversationManager.saveConversation(conversation, to: conversationFilePath) {
                            // Optionally print confirmation (but don't clutter output)
                        }
                    }

                    print(outputText)

                    exitCode = 0
                } catch {
                    handleError(error)
                    exitCode = 1
                }

                semaphore.signal()
            }

            // Wait for the async task to complete
            semaphore.wait()
            return exitCode
        }

        // MARK: - Response Helpers

        /// Performs a model respond call, with automatic retry on context window overflow.
        /// When the conversation history causes the prompt to exceed the 4096-token context window,
        /// the oldest messages are dropped and the request is retried with only the most recent
        /// exchanges. If no conversation history is present, the error is rethrown.
        private func respondHandlingOverflow(
            basePrompt: String,
            systemPrompt: String?,
            schemaString: String?,
            conversation: Conversation?,
            userPrompt: String
        ) async throws -> String {
            let session = LanguageModelSession(instructions: systemPrompt)
            do {
                return try await performRespond(to: basePrompt, session: session, schemaString: schemaString)
            } catch let genError as LanguageModelSession.GenerationError {
                guard case .exceededContextWindowSize = genError else { throw genError }

                // Without conversation history there is nothing to truncate — rethrow
                guard let conversation = conversation else { throw genError }

                CLIUtilities.eprint("Warning: Context window exceeded. Retrying with recent conversation history only...")
                let (truncatedPrompt, _) = ConversationManager.buildTruncatedPromptFromConversation(
                    conversation, newPrompt: userPrompt
                )
                let newSession = LanguageModelSession(instructions: systemPrompt)
                return try await performRespond(to: truncatedPrompt, session: newSession, schemaString: schemaString)
            }
        }

        /// Executes a single model respond call, choosing between plain-text and structured-output paths.
        private func performRespond(to prompt: String, session: LanguageModelSession, schemaString: String?) async throws -> String {
            if let schemaString = schemaString {
                let schemaDict = try SchemaResolver.resolve(from: schemaString)
                let dynamicSchema = try JSONSchemaConverter.convert(schemaDict)
                let generationSchema = try GenerationSchema(root: dynamicSchema, dependencies: [])
                let response = try await session.respond(to: prompt, schema: generationSchema)
                return serializeDynamicOutput(response.content)
            } else {
                let response = try await session.respond(to: prompt)
                return response.content
            }
        }

        private func extractPrompt(from parsed: ParsedCommand) -> String? {
            // Priority order:
            // 1. --file or -f option (explicit file)
            // 2. --prompt or -p option (explicit prompt)
            // 3. stdin (pipe input)
            // 4. positional arguments (default prompt)

            // Try --file or -f option first (highest priority for explicit file)
            if let filePath = parsed.options["file"] ?? parsed.options["f"] {
                return readAndValidateFile(filePath: filePath)
            }

            // Try --prompt or -p option
            if let promptOpt = parsed.options["prompt"] ?? parsed.options["p"] {
                return promptOpt
            }

            // Try stdin (pipe input)
            if let stdin = CLIUtilities.readStdin(), !stdin.isEmpty {
                return stdin.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Try positionals (default - treat as prompt)
            if !parsed.positionals.isEmpty {
                return parsed.positionals.joined(separator: " ")
            }

            return nil
        }

        /// Extract JSON schema string (file path or inline JSON) from parsed command
        private func extractSchemaString(from parsed: ParsedCommand) -> String? {
            parsed.options["schema"] ?? parsed.options["json-schema"]
        }

        /// Serialize a GeneratedContent to a JSON string
        private func serializeDynamicOutput(_ output: GeneratedContent) -> String {
            return output.jsonString
        }

        /// Extract system prompt/pre-prompt from parsed command
        private func extractSystemPrompt(from parsed: ParsedCommand) -> String? {
            // Try --system-prompt or --pre-prompt option
            if let systemPrompt = parsed.options["system-prompt"] ?? parsed.options["pre-prompt"] {
                return systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Try short form -s for system-prompt
            if let systemPrompt = parsed.options["s"] {
                return systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return nil
        }

        // MARK: - File Validation

        /// Maximum file size for prompts (1 MB)
        private let maxFileSize: Int64 = 1 * 1024 * 1024

        /// Maximum percentage of non-printable characters allowed (5%)
        private let maxNonPrintablePercentage: Double = 5.0

        /// Validates file size; returns false and prints error if invalid.
        private func validateFileSize(filePath: String) -> Bool {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                guard let fileSize = attributes[.size] as? Int64 else { return true }
                if fileSize > maxFileSize {
                    CLIUtilities.eprint("Error: File is too large (\(formatFileSize(fileSize))). Maximum size is \(formatFileSize(maxFileSize)).")
                    CLIUtilities.eprint("Large files may cause issues with the foundation model.")
                    return false
                }
                if fileSize == 0 {
                    CLIUtilities.eprint("Error: File is empty: \(filePath)")
                    return false
                }
                return true
            } catch {
                CLIUtilities.eprint("Error: Cannot read file attributes: \(filePath) - \(error.localizedDescription)")
                return false
            }
        }

        /// Validates that content does not have excessive non-printable characters; returns false and prints error if invalid.
        private func validatePrintableContent(_ content: String, filePath: String) -> Bool {
            var acceptableCharacters = CharacterSet()
            acceptableCharacters.formUnion(.alphanumerics)
            acceptableCharacters.formUnion(.punctuationCharacters)
            acceptableCharacters.formUnion(.symbols)
            acceptableCharacters.formUnion(.whitespacesAndNewlines)
            acceptableCharacters.formUnion(.decomposables)
            let nonPrintableCount = content.unicodeScalars.filter { !acceptableCharacters.contains($0) }.count
            let totalCharacters = content.unicodeScalars.count
            guard totalCharacters > 0 else { return true }
            let nonPrintablePercentage = (Double(nonPrintableCount) / Double(totalCharacters)) * 100.0
            if nonPrintablePercentage > maxNonPrintablePercentage {
                CLIUtilities.eprint("Error: File contains too many non-printable characters (\(String(format: "%.1f", nonPrintablePercentage))%): \(filePath)")
                CLIUtilities.eprint("The file may be binary or corrupted. Only text files are supported.")
                return false
            }
            return true
        }

        /// Read and validate a file for use as a prompt
        private func readAndValidateFile(filePath: String) -> String? {
            let url = URL(fileURLWithPath: filePath)
            guard FileManager.default.fileExists(atPath: filePath) else {
                CLIUtilities.eprint("Error: File does not exist: \(filePath)")
                return nil
            }
            guard validateFileSize(filePath: filePath) else { return nil }
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                CLIUtilities.eprint("Error: Cannot read file: \(filePath) - \(error.localizedDescription)")
                return nil
            }
            guard let content = String(data: data, encoding: .utf8) else {
                CLIUtilities.eprint("Error: File is not valid UTF-8 text: \(filePath)")
                CLIUtilities.eprint("The file may be binary or use an unsupported encoding.")
                return nil
            }
            if data.contains(0) {
                CLIUtilities.eprint("Error: File contains binary data (null bytes): \(filePath)")
                CLIUtilities.eprint("Only text files are supported.")
                return nil
            }
            guard validatePrintableContent(content, filePath: filePath) else { return nil }
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedContent.isEmpty {
                CLIUtilities.eprint("Error: File contains only whitespace: \(filePath)")
                return nil
            }
            return trimmedContent
        }

        /// Format file size in human-readable format
        private func formatFileSize(_ bytes: Int64) -> String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: bytes)
        }

        private func handleError(_ error: Error) {
            // Check for schema conversion errors first
            if let schemaError = error as? JSONSchemaError {
                CLIUtilities.eprint("Error: Invalid schema — \(schemaError.localizedDescription)")
                return
            }

            // Check for context window overflow
            if let genError = error as? LanguageModelSession.GenerationError,
               case .exceededContextWindowSize = genError
            {
                CLIUtilities.eprint("Error: Context window exceeded (model limit: 4096 tokens).")
                CLIUtilities.eprint("Your prompt is too long. Try:")
                CLIUtilities.eprint("  - Using a shorter prompt")
                CLIUtilities.eprint("  - Breaking your request into smaller parts")
                CLIUtilities.eprint("  - Using --conversation to manage context across calls")
                return
            }

            let errorDescription = error.localizedDescription
            let nsError = error as NSError

            // Check for common error scenarios
            if errorDescription.contains("not available") ||
                errorDescription.contains("unavailable") ||
                errorDescription.contains("not supported")
            {
                CLIUtilities.eprint("Error: Apple Intelligence is not available on this system.")
                CLIUtilities.eprint("This may be because:")
                CLIUtilities.eprint("  - Apple Intelligence is not enabled in System Settings")
                CLIUtilities.eprint("  - The required models are not downloaded")
                CLIUtilities.eprint("  - Your Mac does not meet the hardware requirements")
            } else if nsError.domain == "com.apple.foundationmodels" ||
                errorDescription.contains("foundation model")
            {
                CLIUtilities.eprint("Error: Unable to access Apple Intelligence foundation model.")
                CLIUtilities.eprint("Details: \(errorDescription)")
                CLIUtilities.eprint("")
                CLIUtilities.eprint("Please ensure:")
                CLIUtilities.eprint("  - macOS 26.0 (Tahoe) or later is installed")
                CLIUtilities.eprint("  - Apple Intelligence is enabled in System Settings > Apple Intelligence")
                CLIUtilities.eprint("  - You have an Apple Silicon Mac (M1/M2/M3/M4)")
            } else {
                CLIUtilities.eprint("Error generating response: \(errorDescription)")
                if nsError.code != 0 {
                    CLIUtilities.eprint("Error code: \(nsError.code), Domain: \(nsError.domain)")
                }
            }
        }
    #endif

    private func executeWithoutFramework(_: ParsedCommand) -> Int32 {
        CLIUtilities.eprint("Error: AppleFoundationModels or FoundationModels framework is not available.")
        CLIUtilities.eprint("")
        CLIUtilities.eprint("This feature requires:")
        CLIUtilities.eprint("  - macOS 26.0 (Tahoe) or later")
        CLIUtilities.eprint("  - Apple Silicon Mac (M1, M2, M3, M4, or later)")
        CLIUtilities.eprint("  - Apple Intelligence enabled in System Settings")
        CLIUtilities.eprint("")
        CLIUtilities.eprint("The framework was not found during compilation, which means:")
        CLIUtilities.eprint("  - You may be using an older Xcode version")
        CLIUtilities.eprint("  - You may be compiling on an older macOS version")
        CLIUtilities.eprint("  - The framework is not available in your SDK")
        return 1
    }
}
