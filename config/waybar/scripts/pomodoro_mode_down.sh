#!/bin/bash
# pomodoro_mode_down.sh - Scroll down through pomodoro modes

MODE_FILE="/tmp/.pomodoro_mode_selection"
current_mode=$(cat "$MODE_FILE" 2>/dev/null || echo "25")

# Cycle: 25 → 15 → 90 → 50 → 25
case "$current_mode" in
    "15") echo "90" > "$MODE_FILE" ;;
    "25") echo "15" > "$MODE_FILE" ;;
    "50") echo "25" > "$MODE_FILE" ;;
    "90") echo "50" > "$MODE_FILE" ;;
    *) echo "25" > "$MODE_FILE" ;;
esac

pkill -RTMIN+8 waybar
