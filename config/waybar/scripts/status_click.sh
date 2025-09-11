#!/bin/bash
# status_click.sh - Handle status clicks

# Quick actions for status
bat_level=$(upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | sed 's/%//' 2>/dev/null)

if [ -n "$bat_level" ] && [ "$bat_level" -lt 20 ]; then
    notify-send "Battery" "Low battery: ${bat_level}%" -u critical
elif command -v pamixer >/dev/null 2>&1; then
    pamixer -t
    if pamixer --get-mute >/dev/null 2>&1; then
        notify-send "Audio" "Muted"
    else
        vol=$(pamixer --get-volume)
        notify-send "Audio" "Volume: ${vol}%"
    fi
else
    notify-send "Status" "System OK"
fi
