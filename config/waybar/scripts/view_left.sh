#!/bin/bash
# view_left.sh - Scrollbare Ansichten für linke Seite

VIEW_FILE="/tmp/waybar_left_view"
VIEW=$(cat "$VIEW_FILE" 2>/dev/null || echo 0)

# View normalisieren (0-3)
VIEW=$((VIEW % 4))
if [ $VIEW -lt 0 ]; then
    VIEW=$((4 + VIEW))
fi
echo $VIEW > "$VIEW_FILE"

case $VIEW in
    0)
        # Workspaces View
        if pgrep -x "sway" > /dev/null; then
            workspaces=$(swaymsg -t get_workspaces)
            current=$(echo "$workspaces" | jq -r '.[] | select(.focused==true) | .name')
            workspace_list=""
            for ws in $(echo "$workspaces" | jq -r '.[].name' | sort -n); do
                if [ "$ws" = "$current" ]; then
                    workspace_list+="●$ws "
                else
                    workspace_list+="○$ws "
                fi
            done
            echo "{\"text\":\"$workspace_list\",\"tooltip\":\"Workspaces - Scroll: Switch views\"}"
        else
            echo "{\"text\":\"1 2 3 4\",\"tooltip\":\"Workspaces\\nScroll: Switch views\"}"
        fi
        ;;
    1)
        # System View
        cpu=$(awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f%%", (u-u1) * 100 / (t-t1)}' <(grep 'cpu ' /proc/stat; sleep 0.1; grep 'cpu ' /proc/stat) 2>/dev/null || echo "0%")
        mem=$(free | awk '/^Mem:/ {printf "%.0f%%", $3/$2*100}')
        temp=$(sensors 2>/dev/null | awk '/Core 0/ {print int($3)"°C"}' | head -1)
        temp=${temp:-"--°C"}
        echo "{\"text\":\"💻 ${cpu} 🧠 ${mem} 🌡️ ${temp}\",\"tooltip\":\"System Info - CPU: ${cpu} - RAM: ${mem} - Temp: ${temp} - Scroll: Switch views\"}"
        ;;
    2)
        # Network View
        if command -v nmcli >/dev/null 2>&1; then
            wifi_info=$(nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | head -1)
            if [ -n "$wifi_info" ]; then
                ssid=$(echo "$wifi_info" | cut -d: -f2)
                signal=$(echo "$wifi_info" | cut -d: -f3)
                echo "{\"text\":\"📶 ${ssid} ${signal}%\",\"tooltip\":\"WiFi: ${ssid} - Signal: ${signal}% - Scroll: Switch views\"}"
            else
                echo "{\"text\":\"❌ No WiFi\",\"tooltip\":\"No WiFi connection - Scroll: Switch views\"}"
            fi
        else
            echo "{\"text\":\"🌐 Network\",\"tooltip\":\"Network status\\nScroll: Switch views\"}"
        fi
        ;;
    3)
        # Updates + Moon View
        updates=""
        if command -v pacman >/dev/null 2>&1; then
            update_count=$(pacman -Qu 2>/dev/null | wc -l)
            if [ "$update_count" -gt 0 ]; then
                updates="${update_count} "
            fi
        fi
        
        moon="🌙"
        if [ -f "$HOME/.config/waybar/scripts/moon.sh" ]; then
            moon_json=$($HOME/.config/waybar/scripts/moon.sh 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$moon_json" ]; then
                moon_text=$(echo "$moon_json" | jq -r '.text // "🌙"' 2>/dev/null)
                moon=${moon_text:-"🌙"}
            fi
        fi
        
        echo "{\"text\":\"📦${updates}${moon}\",\"tooltip\":\"Updates: ${update_count:-0} + Moon phase - Scroll: Switch views\"}"
        ;;
esac
