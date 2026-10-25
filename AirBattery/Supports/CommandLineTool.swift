//
//  CommandLineTool.swift
//  AirBattery
//
//  Created by apple on 2025/05/19.
//

import Foundation

class CommandLineTool {
    static func runAsRoot(_ command: String, completion: (() -> Void)? = nil) {
        let script = "do shell script \"\(command)\" with administrator privileges"
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: script) {
            let _ = scriptObject.executeAndReturnError(&error)
            
            if error == nil {
                completion?()
            } else {
                Log.app.error("Command line tool script failed: \(String(describing: error), privacy: .public)")
            }
        }
    }
    
    /// The fork installs its tool as "abtp" so it never clashes with the official app's
    /// "airbattery" link (D-017).
    static let linkPath = "/usr/local/bin/abtp"
    /// Link created by fork versions up to 1.7.4.
    static let legacyLinkPath = "/usr/local/bin/airbattery"
    
    static func isInstalled() -> Bool {
        let attributes = try? fd.attributesOfItem(atPath: linkPath)
        return attributes?[.type] as? FileAttributeType == .typeSymbolicLink
    }
    
    /// The legacy link is removed only when it points into this app, never the official one.
    static func legacyLinkCleanup() -> String {
        guard let target = try? fd.destinationOfSymbolicLink(atPath: legacyLinkPath),
              target.hasSuffix("/AirBattery Plus.app/Contents/Resources/abt") else { return "" }
        return ";/bin/rm -f \(legacyLinkPath)"
    }
    
    static func install(action: (() -> Void)? = nil) {
        if let resourceURL = Bundle.main.resourceURL {
            let binPath = resourceURL.appendingPathComponent("abtp").path
            runAsRoot("/bin/mkdir -p /usr/local/bin;/bin/ln -sf '\(binPath)' \(linkPath)\(legacyLinkCleanup())") {
                action?()
            }
        }
    }
    
    static func uninstall(action: (() -> Void)? = nil) {
        runAsRoot("/bin/rm -f \(linkPath)\(legacyLinkCleanup())") { action?() }
    }
}
