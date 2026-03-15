//
//  JSONSchemaTests.swift
//  afm-cli-unit-tests
//

import Foundation
import Testing

// MARK: - Argument parsing: --schema / --json-schema

struct SchemaArgumentParserTests {
    @Test("--schema option stores inline JSON")
    func schemaOptionInlineJSON() {
        let schema = #"{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}"#
        let result = ArgumentParser.parse(["--schema", schema, "Rate Swift"])
        #expect(result?.command == .generate)
        #expect(result?.options["schema"] == schema)
    }

    @Test("--json-schema alias stores inline JSON")
    func jsonSchemaAliasInlineJSON() {
        let schema = #"{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}"#
        let result = ArgumentParser.parse(["--json-schema", schema, "Rate Python"])
        #expect(result?.command == .generate)
        #expect(result?.options["json-schema"] == schema)
    }

    @Test("--schema option stores file path")
    func schemaOptionFilePath() {
        let result = ArgumentParser.parse(["--schema", "/tmp/schema.json", "prompt"])
        #expect(result?.options["schema"] == "/tmp/schema.json")
    }

    @Test("--schema combined with --system-prompt")
    func schemaCombinedWithSystemPrompt() {
        let schema = #"{"type":"object","properties":{"answer":{"type":"string"}},"required":["answer"]}"#
        let result = ArgumentParser.parse([
            "--system-prompt", "You are a concise assistant.",
            "--schema", schema,
            "What is 2+2?"
        ])
        #expect(result?.options["system-prompt"] == "You are a concise assistant.")
        #expect(result?.options["schema"] == schema)
        #expect(result?.command == .generate)
    }
}

// MARK: - SchemaResolver tests

#if canImport(AppleFoundationModels) || canImport(FoundationModels)
struct SchemaResolverTests {
    // Test 1 / Test 2 equivalent: inline JSON is parsed
    @Test("Resolve inline JSON object")
    func resolveInlineJSONObject() throws {
        let schema = #"{"type":"object","properties":{"name":{"type":"string"},"score":{"type":"number"}},"required":["name","score"]}"#
        let dict = try SchemaResolver.resolve(from: schema)
        #expect(dict["type"] as? String == "object")
        let props = dict["properties"] as? [String: Any]
        #expect(props?["name"] != nil)
        #expect(props?["score"] != nil)
    }

    @Test("Resolve inline JSON array schema")
    func resolveInlineJSONArray() throws {
        let schema = #"{"type":"array","items":{"type":"string"},"minItems":3,"maxItems":3}"#
        let dict = try SchemaResolver.resolve(from: schema)
        #expect(dict["type"] as? String == "array")
        #expect(dict["minItems"] as? Int == 3)
        #expect(dict["maxItems"] as? Int == 3)
    }

    // Test 3 equivalent: schema loaded from file
    @Test("Resolve schema from file path")
    func resolveFromFilePath() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_schema_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let schemaContent = """
        {
          "type": "object",
          "title": "Person",
          "properties": {
            "firstName": { "type": "string" },
            "lastName":  { "type": "string" },
            "age":       { "type": "integer" }
          },
          "required": ["firstName", "lastName", "age"]
        }
        """
        try schemaContent.write(to: tempURL, atomically: true, encoding: .utf8)

        let dict = try SchemaResolver.resolve(from: tempURL.path)
        #expect(dict["type"] as? String == "object")
        #expect(dict["title"] as? String == "Person")
        let props = dict["properties"] as? [String: Any]
        #expect(props?["firstName"] != nil)
        #expect(props?["lastName"] != nil)
        #expect(props?["age"] != nil)
    }

    // Test 8 equivalent: non-existent file throws fileNotFound
    @Test("Resolve non-existent file throws fileNotFound")
    func resolveNonExistentFileThrows() {
        #expect(throws: JSONSchemaError.self) {
            _ = try SchemaResolver.resolve(from: "/tmp/does_not_exist_afm_test.json")
        }
    }

    @Test("Resolve whitespace-padded inline JSON")
    func resolveWhitespacePaddedJSON() throws {
        let schema = "  { \"type\": \"string\" }  "
        let dict = try SchemaResolver.resolve(from: schema)
        #expect(dict["type"] as? String == "string")
    }
}

// MARK: - JSONSchemaConverter tests

struct JSONSchemaConverterTests {
    // Test 7 equivalent: invalid/missing "type" field is rejected
    @Test("Convert schema missing type field throws")
    func convertMissingTypeThrows() {
        let schema: [String: Any] = ["not": "valid json schema"]
        #expect(throws: JSONSchemaError.self) {
            _ = try JSONSchemaConverter.convert(schema)
        }
    }

    @Test("Convert unsupported type throws")
    func convertUnsupportedTypeThrows() {
        let schema: [String: Any] = ["type": "null"]
        #expect(throws: JSONSchemaError.self) {
            _ = try JSONSchemaConverter.convert(schema)
        }
    }

    @Test("Convert string type")
    func convertStringType() throws {
        let schema: [String: Any] = ["type": "string"]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    @Test("Convert integer type")
    func convertIntegerType() throws {
        let schema: [String: Any] = ["type": "integer"]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    @Test("Convert number type")
    func convertNumberType() throws {
        let schema: [String: Any] = ["type": "number"]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    @Test("Convert boolean type")
    func convertBooleanType() throws {
        let schema: [String: Any] = ["type": "boolean"]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    // Test 1 equivalent: object with required fields
    @Test("Convert object with required properties")
    func convertObjectWithRequiredProperties() throws {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "score": ["type": "number"]
            ],
            "required": ["name", "score"]
        ]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    // Test 3 equivalent: object with title
    @Test("Convert object with title")
    func convertObjectWithTitle() throws {
        let schema: [String: Any] = [
            "type": "object",
            "title": "Person",
            "properties": [
                "firstName": ["type": "string", "description": "First name"],
                "lastName": ["type": "string", "description": "Last name"],
                "age": ["type": "integer", "description": "Age in years"]
            ],
            "required": ["firstName", "lastName", "age"]
        ]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    // Test 4 equivalent: array schema
    @Test("Convert array of strings with min/maxItems")
    func convertArrayOfStrings() throws {
        let schema: [String: Any] = [
            "type": "array",
            "items": ["type": "string"],
            "minItems": 3,
            "maxItems": 3
        ]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    @Test("Convert array missing items field throws")
    func convertArrayMissingItemsThrows() {
        let schema: [String: Any] = ["type": "array"]
        #expect(throws: JSONSchemaError.self) {
            _ = try JSONSchemaConverter.convert(schema)
        }
    }

    // Test 5 equivalent: nested object
    @Test("Convert nested object")
    func convertNestedObject() throws {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "title": ["type": "string"],
                "author": [
                    "type": "object",
                    "properties": ["name": ["type": "string"]],
                    "required": ["name"]
                ]
            ],
            "required": ["title", "author"]
        ]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    @Test("Convert object with optional and required properties")
    func convertObjectMixedRequired() throws {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "required_field": ["type": "string"],
                "optional_field": ["type": "integer"]
            ],
            "required": ["required_field"]
        ]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }

    @Test("Convert object with no properties")
    func convertEmptyObject() throws {
        let schema: [String: Any] = ["type": "object"]
        let result = try JSONSchemaConverter.convert(schema)
        try JSONSchemaConverter.validateForGenerationSchema(result)
    }
}
#endif
