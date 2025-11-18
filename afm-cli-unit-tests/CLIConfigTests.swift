//
//  CLIConfigTests.swift
//  afm-cli-unit-tests
//
//  Created by Jan Kožnárek on 15.11.2025.
//

import Foundation
import Testing

struct CLIConfigTests {
	@Test("Program version is set")
	func testProgramVersion() {
		#expect(CLIConfig.programVersion == "0.1.1")
	}
    
	@Test("Program name is set")
	func testProgramName() {
		#expect(!CLIConfig.programName.isEmpty)
	}
    
	@Test("Usage contains program name")
	func usageContainsProgramName() {
		let usage = CLIConfig.usage
		#expect(usage.contains(CLIConfig.programName) == true)
	}
    
	@Test("Usage contains help information")
	func usageContainsHelp() {
		let usage = CLIConfig.usage
		#expect(usage.contains("help") == true)
		#expect(usage.contains("version") == true)
		#expect(usage.contains("prompt") == true)
	}
    
	@Test("Usage contains examples")
	func usageContainsExamples() {
		let usage = CLIConfig.usage
		#expect(usage.contains("Examples:") == true)
	}
    
	@Test("Usage contains conversation information")
	func usageContainsConversationInfo() {
		let usage = CLIConfig.usage
		#expect(usage.contains("conversation") == true)
	}
}
