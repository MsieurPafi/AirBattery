//
//  Sparkle.swift
//  AirBattery
//
//  Created by apple on 2024/6/2.
//

import SwiftUI
import Sparkle

// Updates from the fork's own appcast (appcast.xml on main), signed with the fork's EdDSA
// key (D-026, replaces D-004). Sparkle asks the user on the second launch whether to check
// automatically: nothing is checked before they agree, or click Check for Updates.
let updatesEnabled = true

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

struct UpdaterSettingsView: View {
    private let updater: SPUUpdater
    
    @State private var automaticallyChecksForUpdates: Bool
    @State private var automaticallyDownloadsUpdates: Bool
    
    init(updater: SPUUpdater) {
        self.updater = updater
        self.automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        self.automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
    }
    
    var body: some View {
        SToggle("Automatically check for updates", isOn: $automaticallyChecksForUpdates)
            .onChange(of: automaticallyChecksForUpdates) { newValue in
                updater.automaticallyChecksForUpdates = newValue
            }
        Divider().opacity(0.5)
        SToggle("Automatically download updates", isOn: $automaticallyDownloadsUpdates)
            .disabled(!automaticallyChecksForUpdates)
            .onChange(of: automaticallyDownloadsUpdates) { newValue in
                updater.automaticallyDownloadsUpdates = newValue
            }
    }
}

/// Why Sparkle can't install updates here, if it's something the user can fix (D-030).
/// A DMG downloaded with a browser leaves the app quarantined: "Open Anyway" approves the app,
/// but macOS then refuses Sparkle's installer, launched in the background, because the app
/// isn't notarized ("An error occurred while running the updater", COMPAT note 17).
enum UpdateBlocker {
    case quarantined
    case translocated

    static var current: UpdateBlocker? {
        let path = Bundle.main.bundlePath
        // Run from a read-only copy (launched from the DMG or Downloads): nothing to replace
        if path.contains("/AppTranslocation/") { return .translocated }
        if getxattr(path, "com.apple.quarantine", nil, 0, 0, XATTR_NOFOLLOW) >= 0 { return .quarantined }
        return nil
    }

    static var command: String {
        return "xattr -dr com.apple.quarantine \"\(Bundle.main.bundlePath)\""
    }
}

/// Shown in Settings › Update when updates can't be installed, with what to do. The user runs
/// the command: the app doesn't lift its own quarantine (D-030).
struct UpdateBlockerNotice: View {
    let blocker: UpdateBlocker
    @State private var copied = false

    var body: some View {
        Divider().opacity(0.5)
        VStack(alignment: .leading, spacing: 6) {
            Label(blocker == .quarantined ? "Updates can\u{2019}t be installed yet" : "Updates can\u{2019}t be installed from here",
                  systemImage: "exclamationmark.triangle")
                .font(.callout.weight(.medium))
                .foregroundColor(.orange)
            if blocker == .quarantined {
                Text("macOS keeps apps downloaded with a browser in quarantine, which blocks the updater of an app that isn\u{2019}t notarized. Run this command once in Terminal, then relaunch AirBattery Plus:")
                    .font(.footnote).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(UpdateBlocker.command)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(2)
                    Spacer()
                    Button(copied ? "Copied" : "Copy") {
                        copyToClipboard(UpdateBlocker.command)
                        copied = true
                    }
                }
            } else {
                Text("AirBattery Plus is running from a temporary copy. Move it to the Applications folder, then open it from there.")
                    .font(.footnote).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

