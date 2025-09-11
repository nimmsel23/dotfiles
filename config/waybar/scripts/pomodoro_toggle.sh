#!/bin/bash
# pomodoro_toggle.sh - Start/stop using selected mode

TIMER_FILE="/tmp/.pomodoro_timer"
MODE_SELECTION_FILE="/tmp/.pomodoro_mode_selection"

# Get selected mode
SELECTED_MODE=$(cat "$MODE_SELECTION_FILE" 2>/dev/null || echo "25")

if [ -f "$TIMER_FILE" ]; then
    rm -f "$TIMER_FILE" "/tmp/.pomodoro_locked"
    notify-send "🍅 Pomodoro" "Timer stopped" -t 2000
else
    date +%s > "$TIMER_FILE"
    notify-send "🍅 Pomodoro" "${SELECTED_MODE}-minute session started!" -t 3000
fi

pkill -RTMIN+8 waybar
