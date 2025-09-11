#!/bin/bash
# context_aware.sh - Shows relevant info based on what you're doing

# Detect current activity context
if pgrep -x "firefox\|falkon\|chromium" >/dev/null 2>&1; then
    # Browsing - show network
    if command -v nmcli >/dev/null 2>&1; then
        conn=$(nmcli -t -f TYPE,STATE dev | grep "connected" | head -1)
        if echo "$conn" | grep -q "wifi"; then
            signal=$(nmcli -t -f active,signal dev wifi | grep '^yes' | head -1 | cut -d: -f2)
            echo "{\"text\":\"📶 ${signal}%\",\"tooltip\":\"Browsing mode - WiFi signal\",\"class\":\"browsing\"}"
        elif echo "$conn" | grep -q "ethernet"; then
            echo "{\"text\":\"🌐 LAN\",\"tooltip\":\"Browsing mode - Ethernet\",\"class\":\"browsing\"}"
        else
            echo "{\"text\":\"🔗 Tether\",\"tooltip\":\"Browsing mode - USB/Mobile\",\"class\":\"browsing\"}"
        fi
    else
        echo "{\"text\":\"🌐 Online\",\"tooltip\":\"Browsing mode\",\"class\":\"browsing\"}"
    fi

elif pgrep -x "code\|nvim\|vim\|foot.*vim\|kitty.*vim" >/dev/null 2>&1; then
    # Coding - show system load
    cpu=$(awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f", (u-u1) * 100 / (t-t1)}' <(grep 'cpu ' /proc/stat; sleep 0.1; grep 'cpu ' /proc/stat) 2>/dev/null || echo 0)
    mem=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
    echo "{\"text\":\"💻 ${cpu}% 🧠 ${mem}%\",\"tooltip\":\"Coding mode - System load\",\"class\":\"coding\"}"

elif pgrep -x "mpv\|vlc\|spotify" >/dev/null 2>&1; then
    # Media - show audio + battery
    vol_icon="🔊"
    if command -v pamixer >/dev/null 2>&1; then
        if pamixer --get-mute >/dev/null 2>&1; then
            vol_icon="🔇"
        fi
    fi
    
    bat_level=$(upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | sed 's/%//' 2>/dev/null)
    bat_icon="🔋"
    if [ -n "$bat_level" ] && [ "$bat_level" -lt 30 ]; then
        bat_icon="🪫"
    fi
    
    echo "{\"text\":\"${vol_icon} ${bat_icon}${bat_level}%\",\"tooltip\":\"Media mode - Audio + Battery\",\"class\":\"media\"}"

elif [ "$(date +%H)" -ge 22 ] || [ "$(date +%H)" -le 6 ]; then
    # Night mode - show battery + brightness
    brightness_icon="🌙"
    if command -v brightnessctl >/dev/null 2>&1; then
        brightness=$(brightnessctl get 2>/dev/null)
        max_brightness=$(brightnessctl max 2>/dev/null)
        if [ -n "$brightness" ] && [ -n "$max_brightness" ]; then
            percent=$((brightness * 100 / max_brightness))
            if [ "$percent" -lt 30 ]; then
                brightness_icon="🌑"
            fi
        fi
    fi
    
    bat_level=$(upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | sed 's/%//' 2>/dev/null)
    echo "{\"text\":\"${brightness_icon} 🔋${bat_level}%\",\"tooltip\":\"Night mode - Brightness + Battery\",\"class\":\"night\"}"

else
    # Default - show most critical info
    updates=$(pacman -Qu 2>/dev/null | wc -l)
    if [ "$updates" -gt 0 ]; then
        echo "{\"text\":\"📦 ${updates}\",\"tooltip\":\"${updates} updates available\",\"class\":\"updates\"}"
    else
        # Show moon phase
        moon="🌙"
        if [ -f "$HOME/.config/waybar/scripts/moon.sh" ]; then
            moon_json=$($HOME/.config/waybar/scripts/moon.sh 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$moon_json" ]; then
                moon=$(echo "$moon_json" | jq -r '.text // "🌙"' 2>/dev/null)
            fi
        fi
        echo "{\"text\":\"${moon}\",\"tooltip\":\"All systems normal\",\"class\":\"normal\"}"
    fi
fi

