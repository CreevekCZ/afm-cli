//
//  JSONSchemaConverter.swift
//  afm-cli
//
//  Created by Claude on 14.03.2026.
//

import Foundation
#if canImport(AppleFoundationModels)
import AppleFoundationModels
#elseif canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(AppleFoundationModels) || canImport(FoundationModels)

// MARK: - JSONSchemaError

enum JSONSchemaError: Error, LocalizedError {
    case invalidJSON(String)
    case missingTypeField
    case unsupportedType(String)
    case missingItems
    case fileNotFound(String)
    case fileReadError(String, Error)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let input):
            return "The value '\(input)' is neither valid JSON nor a readable file path."
        case .missingTypeField:
            return "Schema is missing the required \"type\" field. Composition keywords (allOf, anyOf, oneOf, $ref) are not supported."
        case .unsupportedType(let type):
            return "Schema type \"\(type)\" is not supported. Supported types: string, integer, number, boolean, object, array."
        case .missingItems:
            return "Array schema is missing the required \"items\" field."
        case .fileNotFound(let path):
            return "Schema file not found: \(path)"
        case .fileReadError(let path, let error):
            return "Failed to read schema file '\(path)': \(error.localizedDescription)"
        }
    }
}

// MARK: - SchemaResolver

struct SchemaResolver {
    /// Resolves a schema string to a JSON dictionary.
    /// Tries inline JSON first; falls back to treating the string as a file path.
    static func resolve(from input: String) throws -> [String: Any] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try inline JSON first
        if let data = trimmed.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data),
           let dict = parsed as? [String: Any] {
            return dict
        }

        // Fall back to file path
        guard FileManager.default.fileExists(atPath: trimmed) else {
            throw JSONSchemaError.fileNotFound(trimmed)
        }

        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: trimmed))
        } catch {
            throw JSONSchemaError.fileReadError(trimmed, error)
        }

        guard let parsed = try? JSONSerialization.jsonObject(with: data),
              let dict = parsed as? [String: Any] else {
            throw JSONSchemaError.fileReadError(trimmed, NSError(
                domain: "JSONSchemaConverter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "File does not contain valid JSON object"]
            ))
        }

        return dict
    }
}

// MARK: - JSONSchemaConverter

struct JSONSchemaConverter {
    /// Recursively converts a JSON Schema dictionary to a DynamicGenerationSchema.
    static func convert(_ schema: [String: Any]) throws -> DynamicGenerationSchema {
        guard let typeValue = schema["type"] as? String else {
            throw JSONSchemaError.missingTypeField
        }

        switch typeValue {
        case "string":
            return DynamicGenerationSchema(type: String.self)

        case "integer":
            return DynamicGenerationSchema(type: Int.self)

        case "number":
            return DynamicGenerationSchema(type: Double.self)

        case "boolean":
            return DynamicGenerationSchema(type: Bool.self)

        case "array":
            guard let itemsDict = schema["items"] as? [String: Any] else {
                throw JSONSchemaError.missingItems
            }
            let itemSchema = try convert(itemsDict)
            let minElements = schema["minItems"] as? Int
            let maxElements = schema["maxItems"] as? Int
            return DynamicGenerationSchema(
                arrayOf: itemSchema,
                minimumElements: minElements,
                maximumElements: maxElements
            )

        case "object":
            let title = schema["title"] as? String ?? "Output"
            let propertiesDict = schema["properties"] as? [String: Any] ?? [:]
            let requiredList = schema["required"] as? [String] ?? []

            let properties: [DynamicGenerationSchema.Property] = propertiesDict.compactMap { (key, value) in
                guard let subDict = value as? [String: Any] else {
                    CLIUtilities.eprint("Warning: Skipping property '\(key)' — schema value is not a JSON object.")
                    return nil
                }
                guard let subSchema = try? convert(subDict) else {
                    CLIUtilities.eprint("Warning: Skipping property '\(key)' — could not convert its schema.")
                    return nil
                }
                let description = subDict["description"] as? String ?? ""
                let optionality: DynamicGenerationSchema.Property.Optionality =
                    requiredList.contains(key) ? .required : .possiblyNull
                return DynamicGenerationSchema.Property(
                    name: key,
                    description: description,
                    schema: subSchema,
                    optionality: optionality
                )
            }

            return DynamicGenerationSchema(name: title, properties: properties)

        default:
            throw JSONSchemaError.unsupportedType(typeValue)
        }
    }
}

#endif
