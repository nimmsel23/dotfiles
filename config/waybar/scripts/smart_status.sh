#!/bin/bash
# smart_status.sh - Shows most important status first

# Priority 1: Critical battery
bat_level=$(upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | sed 's/%//' 2>/dev/null)
if [ -n "$bat_level" ] && [ "$bat_level" -lt 15 ]; then
    echo "{\"text\":\"🪫 ${bat_level}%\",\"tooltip\":\"CRITICAL: Battery low!\",\"class\":\"critical\"}"
    exit 0
fi

# Priority 2: No network
if command -v nmcli >/dev/null 2>&1; then
    if ! nmcli -t -f STATE dev | grep -q "connected"; then
        echo "{\"text\":\"❌ Offline\",\"tooltip\":\"No network connection\",\"class\":\"warning\"}"
        exit 0
    fi
fi

# Priority 3: Audio muted (if media playing)
if pgrep -x "mpv\|vlc\|spotify" >/dev/null 2>&1; then
    if command -v pamixer >/dev/null 2>&1 && pamixer --get-mute >/dev/null 2>&1; then
        echo "{\"text\":\"🔇 Muted\",\"tooltip\":\"Audio is muted while media playing\",\"class\":\"warning\"}"
        exit 0
    fi
fi

# Priority 4: High system load
cpu=$(awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f", (u-u1) * 100 / (t-t1)}' <(grep 'cpu ' /proc/stat; sleep 0.1; grep 'cpu ' /proc/stat) 2>/dev/null || echo 0)
if [ "$cpu" -gt 80 ]; then
    temp=$(sensors 2>/dev/null | awk '/Core 0/ {print int($3)}' | head -1)
    temp=${temp:-"--"}
    echo "{\"text\":\"🔥 ${cpu}% ${temp}°C\",\"tooltip\":\"High system load\",\"class\":\"warning\"}"
    exit 0
fi

# Normal status: Show most relevant info
if [ "$bat_level" -lt 30 ]; then
    echo "{\"text\":\"🔋 ${bat_level}%\",\"tooltip\":\"Battery: ${bat_level}%\",\"class\":\"normal\"}"
elif command -v pamixer >/dev/null 2>&1; then
    vol=$(pamixer --get-volume 2>/dev/null)
    vol_icon="🔊"
    if [ -n "$vol" ] && [ "$vol" -lt 30 ]; then
        vol_icon="🔈"
    elif [ -n "$vol" ] && [ "$vol" -lt 70 ]; then
        vol_icon="🔉"
    fi
    echo "{\"text\":\"${vol_icon} ${vol}%\",\"tooltip\":\"Volume: ${vol}%\",\"class\":\"normal\"}"
else
    echo "{\"text\":\"✓ OK\",\"tooltip\":\"All systems normal\",\"class\":\"normal\"}"
fi
