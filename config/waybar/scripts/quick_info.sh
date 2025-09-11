#!/bin/bash
# quick_info.sh - Cycle through useful info on scroll

MODE=$(cat /tmp/quick_info_mode 2>/dev/null || echo 0)
MODE=$((MODE % 4))
[ $MODE -lt 0 ] && MODE=$((4 + MODE))
echo $MODE > /tmp/quick_info_mode

case $MODE in
    0)
        # System load and RAM - Improved version
        # CPU usage (same as original, seems reliable)
        cpu=$(awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f", (u-u1) * 100 / (t-t1)}' <(grep 'cpu ' /proc/stat; sleep 0.1; grep 'cpu ' /proc/stat) 2>/dev/null)
        [ -z "$cpu" ] && cpu=0

        # RAM usage from /proc/meminfo for reliability
        meminfo=$(cat /proc/meminfo 2>/dev/null)
        if [ -n "$meminfo" ]; then
            mem_total=$(echo "$meminfo" | awk '/^MemTotal:/ {print $2}')
            mem_available=$(echo "$meminfo" | awk '/^MemAvailable:/ {print $2}')
            if [ -n "$mem_total" ] && [ -n "$mem_available" ] && [ "$mem_total" -gt 0 ]; then
                mem_used=$((mem_total - mem_available))
                mem_percentage=$((mem_used * 100 / mem_total))
            else
                mem_percentage=0
            fi
        else
            mem_percentage=0
        fi

        echo "{\"text\":\"💻 ${cpu}% 🧠 ${mem_percentage}%\",\"tooltip\":\"CPU: ${cpu}% • RAM: ${mem_percentage}%\",\"class\":\"memory-${mem_percentage}\"}"
        ;;
    1)
        # Updates + temp - Original logic with minor cleanup
        if command -v pacman >/dev/null 2>&1; then
            updates=$(pacman -Qu 2>/dev/null | wc -l)
        else
            updates=0
        fi
        [ -z "$updates" ] && updates=0

        if command -v sensors >/dev/null 2>&1; then
            temp=$(sensors 2>/dev/null | awk '/Package id 0:|Core 0:|Tctl:/ {
                match($0, /[+]?[0-9]+\.[0-9]+°C/)
                if (RSTART) {
                    temp_str = substr($0, RSTART, RLENGTH)
                    gsub(/[^0-9.]/, "", temp_str)
                    print int(temp_str)
                    exit#!/bin/bash
# quick_info.sh - Cycle through useful info on scroll

MODE=$(cat /tmp/quick_info_mode 2>/dev/null || echo 0)
MODE=$((MODE % 4))
[ $MODE -lt 0 ] && MODE=$((4 + MODE))
echo $MODE > /tmp/quick_info_mode

case $MODE in
    0)
        # System load - Debug version
        cpu=$(awk '/^cpu /{u=$2+$4; t=$2+$3+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f", (u-u1) * 100 / (t-t1)}' <(grep 'cpu ' /proc/stat; sleep 0.1; grep 'cpu ' /proc/stat) 2>/dev/null)
        [ -z "$cpu" ] && cpu=0
        
        mem=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}' 2>/dev/null)
        [ -z "$mem" ] && mem=0  
        
        echo "{\"text\":\"💻 ${cpu}% 🧠 ${mem}%\",\"tooltip\":\"CPU: ${cpu}% • RAM: ${mem}%\"}"
        ;;
    1)
        # Updates + temp - Debug version
        if command -v pacman >/dev/null 2>&1; then
            updates=$(pacman -Qu 2>/dev/null | wc -l)
        else
            updates=0
        fi
        [ -z "$updates" ] && updates=0
        
        if command -v sensors >/dev/null 2>&1; then
            temp=$(sensors 2>/dev/null | awk '/Package id 0:|Core 0:|Tctl:/ {
                match($0, /[+]?[0-9]+\.[0-9]+°C/)
                if (RSTART) {
                    temp_str = substr($0, RSTART, RLENGTH)
                    gsub(/[^0-9.]/, "", temp_str)
                    print int(temp_str)
                    exit
                }
            }')
        fi
        
        # Fallback: thermal zones
        if [ -z "$temp" ] && [ -d "/sys/class/thermal" ]; then
            temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)}')
        fi
        
        [ -z "$temp" ] && temp="--"
        
        echo "{\"text\":\"📦 ${updates} 🌡️ ${temp}°C\",\"tooltip\":\"${updates} updates • ${temp}°C\"}"
        ;;
    2)
        # Disk usage
        disk=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}' || echo 0)
        echo "{\"text\":\"💾 ${disk}%\",\"tooltip\":\"Disk usage: ${disk}%\"}"
        ;;
    3)
        # Moon + date
        moon="🌙"
        if [ -f "$HOME/.config/waybar/scripts/moon.sh" ]; then
            moon_json=$($HOME/.config/waybar/scripts/moon.sh 2>/dev/null)
            moon=$(echo "$moon_json" | jq -r '.text // "🌙"' 2>/dev/null)
        fi
        day=$(date +%d.%m)
        echo "{\"text\":\"${moon} ${day}\",\"tooltip\":\"Moon phase + Date\"}"
        ;;
esac

                }
            }')
        fi

        # Fallback: thermal zones
        if [ -z "$temp" ] && [ -d "/sys/class/thermal" ]; then
            temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000)}')
        fi

        [ -z "$temp" ] && temp="--"

        echo "{\"text\":\"📦 ${updates} 🌡️ ${temp}°C\",\"tooltip\":\"${updates} updates • ${temp}°C\"}"
        ;;
    2)
        # Disk usage - Original logic, seems fine
        disk=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}' || echo 0)
        echo "{\"text\":\"💾 ${disk}%\",\"tooltip\":\"Disk usage: ${disk}%\"}"
        ;;
    3)
        # Moon + date - Original logic, seems fine
        moon="🌙"
        if [ -f "$HOME/.config/waybar/scripts/moon.sh" ]; then
            moon_json=$($HOME/.config/waybar/scripts/moon.sh 2>/dev/null)
            moon=$(echo "$moon_json" | jq -r '.text // "🌙"' 2>/dev/null)
        fi
        day=$(date +%d.%m)
        echo "{\"text\":\"${moon} ${day}\",\"tooltip\":\"Moon phase + Date\"}"
        ;;
esac