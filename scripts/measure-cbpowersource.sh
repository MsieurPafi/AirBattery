#!/bin/bash
# Read-only measurement of bluetoothd's CBPowerSource log lines (docs/dev/IDEAS.md): which
# accessories appear, how often, with which levels, and what a query costs.
#   scripts/measure-cbpowersource.sh [--names] [<window>]
# <window> defaults to 7d (macOS usually keeps less: the summary gives the period covered).
# Device names are replaced by their category unless --names is given, so the output can be
# pasted in an issue or saved in docs/dev/samples/.
set -uo pipefail

names=0
if [ "${1:-}" = "--names" ]; then names=1; shift; fi
window="${1:-7d}"
pred='subsystem == "com.apple.bluetooth" AND category == "CBPowerSource"'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

/usr/bin/log show --style compact --info --last "$window" --predicate "$pred" > "$tmp/lines.log"
# Cost of the query a reader would run on each refresh
/usr/bin/time -p /usr/bin/log show --style compact --info --last 2m --predicate "$pred" 2> "$tmp/time.txt" > /dev/null

echo "macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion)), $(date '+%Y-%m-%d %H:%M'), window $window"
python3 -I - "$tmp/lines.log" "$tmp/time.txt" "$names" <<'EOF'
import collections, re, sys
lines = [l for l in open(sys.argv[1], encoding="utf-8", errors="replace") if "Power source updated" in l]
cost = dict(l.split() for l in open(sys.argv[2]) if len(l.split()) == 2)
show_names = sys.argv[3] == "1"
if not lines:
    print("No CBPowerSource line in the window.")
    sys.exit()
print(f"{len(lines)} lines, {lines[0][:16]} → {lines[-1][:16]}")
print(f"2-minute query: {cost.get('real', '?')} s, CPU {float(cost.get('user', 0)) + float(cost.get('sys', 0)):.2f} s")
field = lambda name, line: (re.search(rf"{name} ([^,]+),", line) or [None, "?"])[1].strip()
devices = collections.defaultdict(list)
for l in lines:
    name = (re.search(r"Nm '([^']*)'", l) or [None, "?"])[1]
    ids = [(re.search(rf"{n} (0x\w+(?: \([^)]*\))?)", l) or [None, "?"])[1] for n in ("VID", "PID")]
    key = (name, field("AcCa", l), field("TPT", l), *ids)
    level = re.search(r"Battery (-?\d+)%", l)
    parts = re.search(r"Components \(\w\): (.*?)(?:, CF|$)", l)
    devices[key].append((l[:16], int(level[1]) if level else None, parts[1].strip() if parts else ""))
# One label per device name, whatever its category or transport in each line
anonymous, labels = collections.Counter(), {}
for (name, category, transport, vid, pid), seen in sorted(devices.items(), key=lambda d: -len(d[1])):
    if not show_names:
        if name not in labels:
            anonymous[category] += 1
            labels[name] = f"{category} {anonymous[category]}"
        name = labels[name]
    levels = [s[1] for s in seen if s[1] is not None]
    hours = len({s[0][:13] for s in seen})
    print(f"- {name} | {category} | {transport} | VID {vid} PID {pid} | {len(seen)} lines over {hours} h "
          f"| levels {min(levels)}…{max(levels)}% ({len(set(levels))} distinct), last {levels[-1]}%"
          + (f" | components: {seen[-1][2]}" if seen[-1][2] else ""))
EOF
