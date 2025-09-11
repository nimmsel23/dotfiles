#!/bin/bash
# view_right.sh - Scrollbare Ansichten für rechte Seite

VIEW_FILE="/tmp/waybar_right_view"
VIEW=$(cat "$VIEW_FILE" 2>/dev/null || echo 0)

# View normalisieren (0-2)
VIEW=$((VIEW % 3))
if [ $VIEW -lt 0 ]; then
    VIEW=$((3 + VIEW))
fi
echo $VIEW > "$VIEW_FILE"

case $VIEW in
    0)
        # Audio + Network
        volume_icon="🔊"
        if command -v pamixer >/dev/null 2>&1; then
            if pamixer --get-mute >/dev/null 2>&1; then
                volume_icon="🔇"
            else
                volume=$(pamixer --get-volume 2>/dev/null)
                if [ -n "$volume" ] && [ "$volume" -lt 30 ]; then
                    volume_icon="🔈"
                elif [ -n "$volume" ] && [ "$volume" -lt 70 ]; then
                    volume_icon="🔉"
                fi
            fi
        fi
        
        network_icon="📶"
        if command -v nmcli >/dev/null 2>&1; then
            connection=$(nmcli -t -f TYPE,STATE dev | grep -E "wifi.*connected" | head -1)
            if [ -z "$connection" ]; then
                ethernet=$(nmcli -t -f TYPE,STATE dev | grep -E "ethernet.*connected" | head -1)
                if [ -n "$ethernet" ]; then
                    network_icon="🌐"
                else
                    network_icon="❌"
                fi
            fi
        fi
        
        echo "{\"text\":\"${volume_icon} ${network_icon}\",\"tooltip\":\"Audio + Network - Scroll: Switch views\"}"
        ;;
    1)
        # Brightness + Bluetooth
        brightness_icon="🌕"
        if command -v brightnessctl >/dev/null 2>&1; then
            brightness=$(brightnessctl get 2>/dev/null)
            max_brightness=$(brightnessctl max 2>/dev/null)
            if [ -n "$brightness" ] && [ -n "$max_brightness" ]; then
                percent=$((brightness * 100 / max_brightness))
                if [ "$percent" -lt 20 ]; then
                    brightness_icon="🌑"
                elif [ "$percent" -lt 40 ]; then
                    brightness_icon="🌘"
                elif [ "$percent" -lt 60 ]; then
                    brightness_icon="🌗"
                elif [ "$percent" -lt 80 ]; then
                    brightness_icon="🌖"
                fi
            fi
        fi
        
        bluetooth_icon="🔵"
        if command -v bluetoothctl >/dev/null 2>&1; then
            bt_status=$(bluetoothctl show 2>/dev/null | grep "Powered: yes")
            if [ -z "$bt_status" ]; then
                bluetooth_icon="⚫"
            else
                connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
                if [ "$connected" -gt 0 ]; then
                    bluetooth_icon="🔵"
                fi
            fi
        fi
        
        echo "{\"text\":\"${brightness_icon} ${bluetooth_icon}\",\"tooltip\":\"Brightness + Bluetooth - Scroll: Switch views\"}"
        ;;
    2)
        # Battery + Weather  
        battery_icon="🔋"
        battery_percent=""
        if command -v upower >/dev/null 2>&1; then
            battery_level=$(upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | sed 's/%//' 2>/dev/null)
            if [ -n "$battery_level" ]; then
                battery_percent="${battery_level}%"
                if [ "$battery_level" -lt 20 ]; then
                    battery_icon="🪫"
                elif [ "$battery_level" -lt 50 ]; then
                    battery_icon="🔋"
                else
                    battery_icon="🔋"
                fi
            fi
        fi
        
        weather="🌤️"
        if [ -f "$HOME/.config/waybar/scripts/weather.sh" ]; then
            weather_json=$($HOME/.config/waybar/scripts/weather.sh 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$weather_json" ]; then
                weather_text=$(echo "$weather_json" | jq -r '.text // "🌤️"' 2>/dev/null)
                weather=${weather_text:-"🌤️"}
            fi
        fi
        
        echo "{\"text\":\"${battery_icon}${battery_percent} ${weather}\",\"tooltip\":\"Battery + Weather - Scroll: Switch views\"}"
        ;;
esac	
