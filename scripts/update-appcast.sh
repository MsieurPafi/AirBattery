#!/bin/bash
# Adds a release to appcast.xml (Sparkle update feed, D-026).
#   scripts/update-appcast.sh <dmg>
# The DMG must be the one attached to the GitHub release vX.Y.Z (same file, same name).
# Its release notes are the "## X.Y.Z" section of CHANGELOG.md. The new item is signed
# with the fork's EdDSA key, read from the login keychain (account below).
# Then commit appcast.xml and get it onto main: the app reads the feed from there.
set -euo pipefail

ACCOUNT="io.github.msieurpafi.AirBattery"
REPO="MsieurPafi/AirBattery-Plus"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin"

dmg="${1:?usage: $0 <dmg>}"
[ -f "$dmg" ] || { echo "No such file: $dmg" >&2; exit 1; }
[ -x "$TOOLS/generate_appcast" ] || { echo "Sparkle tools not found: build the app once (they come with the Sparkle package)." >&2; exit 1; }

# Version from the app inside the DMG, not from the file name
mnt="$(mktemp -d)"
hdiutil attach -nobrowse -readonly -mountpoint "$mnt" "$dmg" >/dev/null
app="$(find "$mnt" -maxdepth 1 -name '*.app' | head -n 1)"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Contents/Info.plist")"
hdiutil detach "$mnt" >/dev/null
rmdir "$mnt"
echo "DMG: version $version (build $build)"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
base="$(basename "$dmg" .dmg)"
cp "$dmg" "$work/"
cp "$ROOT/appcast.xml" "$work/appcast.xml"

# Release notes: the version's CHANGELOG section, as simple embedded HTML
python3 -I - "$ROOT/CHANGELOG.md" "$version" > "$work/$base.html" <<'EOF'
import html, re, sys
path, version = sys.argv[1], sys.argv[2]
lines, inside = [], False
for line in open(path, encoding="utf-8"):
    if line.startswith("## "):
        if inside: break
        inside = line[3:].split(" ")[0] == version
        continue
    if inside: lines.append(line.rstrip("\n"))
if not lines: sys.exit(f"No '## {version}' section in CHANGELOG.md")

def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    return re.sub(r"\[(.+?)\]\((.+?)\)", r'<a href="\2">\1</a>', text)

out, in_list = [], False
for line in lines:
    item = line.startswith("- ")
    if in_list and not item: out.append("</ul>"); in_list = False
    if line.startswith("### "): out.append(f"<h3>{inline(line[4:])}</h3>")
    elif item:
        if not in_list: out.append("<ul>"); in_list = True
        out.append(f"<li>{inline(line[2:])}</li>")
    elif line.strip(): out.append(f"<p>{inline(line)}</p>")
if in_list: out.append("</ul>")
print("\n".join(out))
EOF

# --maximum-versions 0 keeps every item already in the feed (their DMGs are not here);
# no deltas: each release is a full DMG.
"$TOOLS/generate_appcast" --account "$ACCOUNT" \
    --download-url-prefix "https://github.com/$REPO/releases/download/v$version/" \
    --full-release-notes-url "https://github.com/$REPO/blob/main/CHANGELOG.md" \
    --link "https://github.com/$REPO" \
    --embed-release-notes --maximum-versions 0 --maximum-deltas 0 \
    "$work"

grep -q "<sparkle:version>$build</sparkle:version>" "$work/appcast.xml" || { echo "Version $build is missing from the new appcast." >&2; exit 1; }
# generate_appcast silently leaves an item unsigned when the app has no SUPublicEDKey,
# and the app would refuse that update.
grep "releases/download/v$version/" "$work/appcast.xml" | grep -q "sparkle:edSignature=" || { echo "The new item is not signed: does the app in the DMG have SUPublicEDKey?" >&2; exit 1; }
cp "$work/appcast.xml" "$ROOT/appcast.xml"
echo "appcast.xml updated with $version. Check it (git diff appcast.xml), then commit it and get it onto main."
