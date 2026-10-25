#!/bin/bash
# Quick checks that need no build, run by CI (.github/workflows/ci.yml) and runnable locally:
#   scripts/ci-checks.sh
set -uo pipefail
cd "$(dirname "$0")/.."
failed=0
check() { echo "== $1"; }
fail() { echo "FAILED: $1" >&2; failed=1; }

check "Shell scripts parse"
while IFS= read -r f; do bash -n "$f" || fail "$f"; done < <(git ls-files '*.sh')

check "Property lists are valid"
while IFS= read -r f; do plutil -lint -s "$f" || fail "$f"; done < <(git ls-files '*.plist' '*.entitlements')

check "String Catalogs are valid JSON"
while IFS= read -r f; do python3 -I -c 'import json, sys; json.load(open(sys.argv[1]))' "$f" || fail "$f"; done < <(git ls-files '*.xcstrings')

check "appcast.xml is well formed, every update is signed"
xmllint --noout appcast.xml || fail "appcast.xml is not well formed"
python3 -I - appcast.xml <<'EOF' || fail "appcast.xml has an unsigned update"
import sys, xml.etree.ElementTree as ET
ns = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"
items = ET.parse(sys.argv[1]).getroot().findall("./channel/item")
unsigned = [i.findtext(ns + "shortVersionString") for i in items
            if (e := i.find("enclosure")) is None or not e.get(ns + "edSignature")]
print(f"{len(items)} update(s)")
if unsigned: sys.exit(f"Unsigned: {', '.join(unsigned)}")
EOF

check "Bundle ID prefix matches AppIdentifiers.prefix"
setting=$(grep -o 'APP_ID_PREFIX = [^;]*' AirBattery.xcodeproj/project.pbxproj | sort -u | sed 's/APP_ID_PREFIX = //')
code=$(grep -o 'static let prefix = "[^"]*"' Shared/AppIdentifiers.swift | sed 's/.*= "//; s/"$//')
echo "APP_ID_PREFIX: $setting, AppIdentifiers.prefix: $code"
[ -n "$code" ] && [ "$setting" = "$code" ] || fail "the widget and the login helper would not find the app"

check "logReader.sh reads the Bluetooth log sample"
out=$(LOGREADER_SAMPLE=docs/dev/samples/logreader-mac-sample.log bash AirBattery/Supports/logReader.sh mac 10m)
python3 -I -c '
import json, sys
lines = [json.loads(l) for l in sys.argv[1].splitlines() if l.strip()]
names = [l["name"] for l in lines]
print(f"{len(lines)} device(s): {names}")
assert len(lines) == 2, "expected 2 devices"
assert names[1] == "Bob'"'"'s \"Speaker\" *", "device name not escaped"
' "$out" || fail "unexpected logReader.sh output"

[ "$failed" = 0 ] && echo "All checks passed." || { echo "Some checks failed." >&2; exit 1; }
