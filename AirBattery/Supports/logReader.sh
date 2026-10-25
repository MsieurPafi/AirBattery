#!/bin/bash
# Battery levels from logs.
#   logReader.sh mac <window> [<start>]
#       Third-party Bluetooth devices, from bluetoothd's logs: the last <window> (e.g. 10m),
#       or since <start> ("yyyy-MM-dd HH:mm:ss +zzzz") when given. One JSON object per line.
#   logReader.sh <idevicesyslog> <type> <udid>
#       Apple Pencil battery, from the iPad's SpringBoard logs.
# LOGREADER_SAMPLE=<file> reads log lines from that file instead of `log show` (tests).

# Escapes a value for a JSON string: device names come from Bluetooth and may contain quotes.
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

if [ "x$1" = "xmac" ]; then
    PRED='subsystem == "com.apple.bluetooth" AND (category == "CBStackDeviceMonitor" OR category == "Server.GATT") AND (eventMessage CONTAINS "Battery" OR eventMessage CONTAINS "statedump: 0x001A" OR eventMessage CONTAINS "statedump: 0x001D")'
    # Options in an array: as plain strings, "--style compact" reached `log show` as one
    # argument, which made it fail (and `log show` takes --info, not --level).
    OPTS=(--style compact --info --predicate "$PRED")
    if [ -n "$3" ]; then OPTS+=(--start "$3"); else OPTS+=(--last "${2:-10m}"); fi

    if [ -n "$LOGREADER_SAMPLE" ]; then
        data=$(cat "$LOGREADER_SAMPLE")
    else
        data=$(/usr/bin/nice -n 19 /usr/bin/log show "${OPTS[@]}")
    fi

    # Lines read one by one, never word-split or glob-expanded
    while IFS= read -r i; do
        [ -n "$i" ] || continue
        time=$(echo "$i" | awk '{print $1"T"$2}')
        name=$(echo "$i" | grep -o ", Nm '.*', PID" | sed "s/, Nm '//g;s/', PID//g")
        type=$(echo "$i" | grep -o ", DvT [A-Za-z]*" | sed "s/, DvT //g")
        batt=$(echo "$i" | grep -o ", Battery M [+-]*[0-9]*%" | grep -Eo "[0-9]+")
        stat=$(echo "$i" | grep -o ", Battery M [+-]*[0-9]*%" | grep -Eo "\+|\-")
        mac=$(echo "$i" | grep -o ", BDA [A-Za-z0-9:]*" | sed "s/, BDA //g")
        vid=$(echo "$i" | grep -o ", VID 0x[A-Za-z0-9]*" | sed "s/, VID //g")
        pid=$(echo "$i" | grep -o ", PID 0x[A-Za-z0-9]*" | sed "s/, PID //g")
        if [ -n "$batt" ]; then
            echo "{\"time\": \"$time\", \"vid\": \"$vid\", \"pid\": \"$pid\", \"type\": \"$(json_escape "$type")\", \"mac\": \"$mac\", \"name\": \"$(json_escape "$name")\", \"level\": $batt, \"status\": \"$stat\"}"
        fi
    done <<< "$(echo "$data" | grep "Battery" | grep -v "VID 0x004C")"

    devData=$(echo "$data" | grep -E "statedump: 0x001A Characteristic Value|statedump: 0x001D Characteristic Value" | grep -o "\[[A-Za-z0-9 ]*\]" | sed 's/\[ //g;s/ \]//g' | awk '{if (NR%2==1) {line=$0} else {print line, $0}}' | awk 'length($0) == 23')
    times=$(echo "$data" | grep -E "statedump: 0x001D Characteristic Value" | awk '{print $1"T"$2}')
    # Nothing to match: skip system_profiler (it ran on every call before)
    if [ -n "$times" ] && [ -n "$devData" ] && [ "$(echo "$devData" | wc -l)" = "$(echo "$times" | wc -l)" ]; then
        btData=$(/usr/sbin/system_profiler SPBluetoothDataType)
        while IFS= read -r i; do
            if [ "$(echo "$i" | wc -w | tr -d " ")" = "9" ]; then
                time=$(echo "$i" | awk '{print $1}')
                batt=$(echo "$i" | awk '{print "0x"$NF}')
                vid=$(echo "$i" | awk '{print "0x"$4$3}')
                pid=$(echo "$i" | awk '{print "0x"$6$5}')
                name=$(echo "$btData" | grep -B3 "$pid" | sed -n '1p' | sed 's/^ *//g;s/:$//g')
                type=$(echo "$btData" | grep -A5 "$pid" | grep "Minor Type: " | sed 's/^ *Minor Type: //g')
                mac=$(echo "$btData" | grep -B2 "$pid" | sed -n '1p' | sed 's/^ *Address: //g;s/:$//g')
                echo "{\"time\": \"$time\", \"vid\": \"$vid\", \"pid\": \"$pid\", \"type\": \"$(json_escape "$type")\", \"mac\": \"$mac\", \"name\": \"$(json_escape "$name")\", \"level\": $(($batt)), \"status\": \"?\"}"
            fi
        done <<< "$(paste -d ' ' <(echo "$times") <(echo "$devData"))"
    fi
else
    syslog=$1
    type=$2
    id=$3

    # The path contains "AirBattery Plus.app": quoted. $type is empty for USB, so left unquoted.
    data=$("$syslog" $type -u "$id" --process SpringBoard -m '"Accessory Category" = Pencil;' -T SpringBoard)
    batt=`echo "$data"|grep "Current Capacity"|grep -o "[0-9]*"|sed -n '$p'`
    stat=`echo "$data"|grep "Is Charging"|grep -o "[0-9]*"|sed -n '$p'`
    model=`echo "$data"|grep "Product ID"|grep -o "[0-9]*"|sed -n '$p'`
    vendor=`echo "$data"|grep "Vendor ID"|grep -v Source|grep -o "[0-9]*"|sed -n '$p'`
    if [ x"$vendor" = "x76" ]; then vendor="Apple"; else vendor="Other"; fi

    #data=`$syslog $type -u $id -m 'name = Pencil' --process SpringBoard -T SpringBoard|tr ';' '\n'`
    #batt=`echo "$data"|grep "percentCharge ="|grep -o "[0-9]*"|sed -n '$p'`
    #stat=`echo "$data"|grep "charging ="|tr -d " "|sed 's/charging=//g'|sed -n '$p'`
    #model=`echo "$data"|grep "productIdentifier ="|grep -o "[0-9]*"|sed -n '$p'`
    #vendor=`echo "$data"|grep "vendor ="|tr -d " "|sed 's/vendor=//g'|sed -n '$p'`
    #if [ x"$stat" = "xYES" ]; then stat=1; else stat=0; fi
    echo "{\"level\": $batt, \"status\": $stat, \"model\": \"$model\", \"vendor\": \"$vendor\"}"
fi
