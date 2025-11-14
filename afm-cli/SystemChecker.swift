//
//  SystemChecker.swift
//  afm-cli
//
//  Created by Jan Kožnárek on 14.11.2025.
//

import Foundation
import Darwin

struct SystemChecker {
    /// Check if the system meets macOS version requirements
    static func checkMacOSVersion() -> Bool {
        if #available(macOS 26.0, *) {
            return true
        }
        CLIUtilities.eprint("Error: Apple Intelligence foundation models require macOS 26.0 (Tahoe) or later.")
        CLIUtilities.eprint("Your system is running an older version of macOS.")
        return false
    }
    
    /// Check if running on Apple Silicon (required for Apple Intelligence)
    static func checkAppleSilicon() -> Bool {
        var isAppleSilicon = false
        var size = 0
        
        // Check CPU architecture using sysctlbyname
        sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
        if size > 0 {
            var value: Int32 = 0
            sysctlbyname("hw.optional.arm64", &value, &size, nil, 0)
            isAppleSilicon = (value != 0)
        }
        
        // Fallback: Check CPU brand string for Apple Silicon indicators
        if !isAppleSilicon {
            size = 0
            sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
            if size > 0 {
                var brandString = [CChar](repeating: 0, count: size)
                sysctlbyname("machdep.cpu.brand_string", &brandString, &size, nil, 0)
                let brand = String(cString: brandString).lowercased()
                isAppleSilicon = brand.contains("apple")
            }
        }
        
        if !isAppleSilicon {
            CLIUtilities.eprint("Error: Apple Intelligence requires an Apple Silicon Mac (M1, M2, M3, M4, M5 or later).")
            CLIUtilities.eprint("Your Mac does not have the required hardware.")
            return false
        }
        
        return true
    }
    
    /// Check all system requirements for Apple Intelligence
    static func checkAllRequirements() -> Bool {
        guard checkMacOSVersion() else { return false }
        guard checkAppleSilicon() else { return false }
        return true
    }
}

