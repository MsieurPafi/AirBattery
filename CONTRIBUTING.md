# Contributing to AirBattery Plus

Thanks for your interest! AirBattery Plus is a personal project first, maintained in spare time: issues and pull requests are welcome, but answers may take a while.

## Report a bug

Open an [issue](https://github.com/MsieurPafi/AirBattery-Plus/issues) with:

- your macOS version (`sw_vers`) and Mac model;
- the AirBattery Plus version (About AirBattery Plus);
- what you expected and what happened, with the device concerned;
- if you can, the app's logs from around the problem (device names and addresses are redacted):

  ```bash
  /usr/bin/log show --last 1h --predicate 'subsystem == "io.github.msieurpafi.AirBattery"'
  ```

Crash reports are in `~/Library/Logs/DiagnosticReports` (files starting with `AirBattery Plus`, `comptest` or `idevice`).

## Build the app

Requirements: a recent Xcode (the project is developed with Xcode 27 on macOS 27) and an Apple ID. A paid developer account is not needed.

1. Clone the repository and open `AirBattery.xcodeproj`. Swift packages (Sparkle, MultipeerKit, swift-argument-parser) are fetched on the first build.
2. Signing: in each target's **Signing & Capabilities**, choose your own team. The project uses the maintainer's free personal team.
3. Build the **AirBattery** scheme. From a terminal:

   ```bash
   xcodebuild -project AirBattery.xcodeproj -scheme AirBattery -configuration Debug \
     -derivedDataPath build/DerivedData build
   ```

   The app is `build/DerivedData/Build/Products/Debug/AirBattery Plus.app`. `build/` is ignored by git.

### Things to know

- **Identifiers.** Bundle IDs come from the `APP_ID_PREFIX` build setting (`io.github.msieurpafi`). If you change it, change `AppIdentifiers.prefix` in `Shared/AppIdentifiers.swift` too: the widget and the login helper find the app through it, and Debug builds stop at launch if the two differ.
- **The widget of a test build replaces the installed one.** macOS registers the widget of every copy of the app it sees, and may pick the one in `build/`. After testing, unregister the build copy:

  ```bash
  APP="build/DerivedData/Build/Products/Debug/AirBattery Plus.app"
  pluginkit -r "$APP/Contents/PlugIns/"*.appex
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$APP"
  ```

- **Run one copy at a time.** Quit the installed AirBattery Plus (and the official AirBattery) before running a build: two instances scanning Bluetooth at once give misleading results.
- **Local network access** is granted per binary: macOS asks again after each build.

### Unit tests

Pure logic lives in `Shared/Core` (Foundation only: it is compiled into every target) and is tested with Swift Package Manager:

```bash
swift test
```

Add tests in `Tests/AirBatteryCoreTests`, and move logic there when it can be tested without the app (parsing tool output, matching devices…).

### Continuous integration

Every pull request and every push to `main` runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml) on macOS 27 with Xcode 27.1:

- `scripts/ci-checks.sh`: scripts parse, property lists and String Catalogs are valid, every update in `appcast.xml` is signed, the bundle ID prefix matches `AppIdentifiers.prefix`, and `logReader.sh` reads its sample log. Run it locally before pushing.
- `swift test`.
- Debug and Release builds, unsigned.

`main` only accepts pull requests whose CI passed (a GitHub ruleset; no direct pushes, no force pushes). CI publishes nothing: releases are still built and signed on the maintainer's Mac (see [Releases](#releases)).

### Screenshots

Debug builds have a demo mode with neutral devices, for screenshots: launch the app with `-demoDevices YES` (add `-AppleLanguages "(en)"` for English). Real devices are hidden and the Mac shows as "MacBook Pro".

```bash
open "build/DerivedData/Build/Products/Debug/AirBattery Plus.app" --args -demoDevices YES -AppleLanguages "(en)"
```

- Take them on a Retina screen, so they are at 2x.
- Remove and add the widgets again: they keep their previous snapshot otherwise.
- Windows and widgets: ⌘⇧4, Space, ⌥-click (transparent background, no shadow). The light-mode popover is the exception: capture its area over a light background, then cut it out along its rounded corners. A window capture renders its glass without what's behind it, as a flat gray.
- `img/preview.png` and `img/preview_dark.png` combine the large widget, the popover, a medium and a small widget.

## Project layout

| Folder | Contents |
| --- | --- |
| `AirBattery/` | The app (SwiftUI and AppKit). Battery sources are in `BatteryInfo/`. |
| `widget/` | The widgets (WidgetKit). |
| `AirBatteryHelper/` | Launch-at-login helper. |
| `abt/` | The `abtp` command line tool. |
| `Shared/` | Code shared by all targets: identifiers, logging. |
| `scripts/` | `build-libimobiledevice.sh` rebuilds the bundled iPhone/iPad/Watch tools from pinned sources; `icon/` generates the app icon artwork. |
| `docs/guide/` | User guide. |
| `docs/dev/` | The maintainers' working notes (in French): journal, decisions, compatibility notes. |

The bundled libimobiledevice tools are built by `scripts/build-libimobiledevice.sh`; their versions are listed in `AirBattery/libimobiledevice/VERSIONS.txt`. Don't replace them with binaries built another way.

## Pull requests

- One topic per pull request, on a branch of its own, against `main` of [MsieurPafi/AirBattery-Plus](https://github.com/MsieurPafi/AirBattery-Plus).
- Code, comments and commit messages in English. Commits follow [Conventional Commits](https://www.conventionalcommits.org) (`fix:`, `feat:`, `docs:`…), and mention the upstream issue when there is one (`fixes upstream #203`).
- Say how you tested: macOS version, devices used.
- Changes visible to users go in `CHANGELOG.md`, under *Unreleased*.

## Translations

- **The app** is in English and French, with Chinese (simplified and traditional) translations that are out of date: updates are welcome. Translations live in String Catalogs (`AirBattery/Localizable.xcstrings`, `AirBattery/InfoPlist.xcstrings`): open them in Xcode to see, language by language, which phrases are missing.
- **The user guide** is written in English (`docs/guide/en/`) and mirrored in French (`docs/guide/fr/`), like the README (`README.fr.md`). A change to either updates both languages in the same pull request.

## Releases

Maintainer only: updates are signed with the project's EdDSA key, which stays in the maintainer's keychain.

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` (Sparkle compares the latter), and turn *Unreleased* in `CHANGELOG.md` into a `## X.Y.Z` section.
2. Build in Release, make `AirBattery-Plus-X.Y.Z.dmg` (the app and an Applications shortcut) and attach it to the GitHub release `vX.Y.Z`.
3. `scripts/update-appcast.sh AirBattery-Plus-X.Y.Z.dmg` adds the version to `appcast.xml`, signed, with its changelog section as release notes. Commit it and get it onto `main`: installed copies read the feed from there, so the update is offered only once the DMG is online.

## License

By contributing, you agree that your work is published under the [AGPL-3.0](LICENSE), like the rest of the project.
