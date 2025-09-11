#!/bin/bash

# Clock mit Task-Integration für Waybar
# Speichere als ~/.config/waybar/scripts/clock_with_tasks.sh

# Aktuelle Zeit formatieren
current_time=$(date '+%H:%M')
current_date=$(date '+%a %d %b')

# Task-Liste für Tooltip generieren (falls task verfügbar)
if command -v task &> /dev/null; then
    # Hole die nächsten 5 Tasks mit besserer Formatierung
    tasks=$(task limit:5 rc.verbose=nothing rc.report.next.columns=description,due rc.report.next.labels= 2>/dev/null | grep -v '^ | head -5)
    
    if [ -n "$tasks" ] && [ "$tasks" != "No matches." ]; then
        # Tasks nummerieren und formatieren
        formatted_tasks=""
        i=1
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                formatted_tasks+="$i. $line\\n"
                ((i++))
            fi
        done <<< "$tasks"
        
        tooltip="📅 $current_date\\n\\n📋 Upcoming Tasks:\\n$formatted_tasks"
    else
        tooltip="📅 $current_date\\n\\n✅ No tasks scheduled!"
    fi
else
    tooltip="📅 $current_date\\n\\n💡 Install taskwarrior for task integration"
fi

# JSON für Waybar ausgeben (Tooltip muss escaped werden)
echo "{\"text\":\"$current_time\",\"tooltip\":\"$tooltip\",\"class\":\"clock\"}"
