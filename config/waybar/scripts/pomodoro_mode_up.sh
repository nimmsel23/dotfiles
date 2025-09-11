#!/bin/bash
# pomodoro_mode_up.sh - Scroll up through pomodoro modes

MODE_FILE="/tmp/.pomodoro_mode_selection"
current_mode=$(cat "$MODE_FILE" 2>/dev/null || echo "25")

# Cycle: 25 → 50 → 90 → 15 → 25
case "$current_mode" in
    "15") echo "25" > "$MODE_FILE" ;;
    "25") echo "50" > "$MODE_FILE" ;;
    "50") echo "90" > "$MODE_FILE" ;;
    "90") echo "15" > "$MODE_FILE" ;;
    *) echo "25" > "$MODE_FILE" ;;
esac

# Update waybar
pkill -RTMIN+8 waybar
