#!/bin/bash
# pomodoro_status.sh - Enhanced with scrollable modes

TIMER_FILE="/tmp/.pomodoro_timer"
LOCK_FILE="/tmp/.pomodoro_locked"
MODE_FILE="/tmp/.pomodoro_mode"
MODE_SELECTION_FILE="/tmp/.pomodoro_mode_selection"
BREAK_DURATION=300     # 5 Minuten

# Get selected mode (from scrolling)
SELECTED_MODE=$(cat "$MODE_SELECTION_FILE" 2>/dev/null || echo "25")

# Set work duration based on selected mode
case "$SELECTED_MODE" in
    "15") WORK_DURATION=900 ;;   # 15 min
    "25") WORK_DURATION=1500 ;;  # 25 min
    "50") WORK_DURATION=3000 ;;  # 50 min
    "90") WORK_DURATION=5400 ;;  # 90 min
    *) WORK_DURATION=1500 ;;     # default 25
esac

# JSON output function
output_json() {
    local text="$1"
    local class="$2" 
    local tooltip="$3"
    
    text=$(echo "$text" | sed 's/"/\\"/g')
    tooltip=$(echo "$tooltip" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    
    printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
}

# Check if timer is running
if [ -f "$TIMER_FILE" ]; then
    start_time=$(cat "$TIMER_FILE")
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -lt $WORK_DURATION ]; then
        # Work time running
        remaining=$(( (WORK_DURATION - elapsed + 59) / 60 ))
        output_json "🍅 ${remaining}m (${SELECTED_MODE})" "running" "Working - ${SELECTED_MODE}min mode\\nClick: Stop\\nScroll: Change mode\\nMiddle: Reset"
        
    elif [ $elapsed -lt $((WORK_DURATION + BREAK_DURATION)) ]; then
        # Break time
        if [ ! -f "$LOCK_FILE" ]; then
            notify-send -u critical "🍅 Pomodoro" "${SELECTED_MODE}min work done! Break time." -t 5000
            (tmatrix-lock.sh &) 2>/dev/null
            touch "$LOCK_FILE"
        fi
        
        remaining=$(( (WORK_DURATION + BREAK_DURATION - elapsed + 59) / 60 ))
        output_json "☕ ${remaining}m break" "paused" "Break time\\nClick: End break\\nScroll: Change mode\\nMiddle: Reset"
        
    else
        # Timer finished
        rm -f "$TIMER_FILE" "$LOCK_FILE"
        output_json "🍅 ${SELECTED_MODE}min" "stopped" "Ready for ${SELECTED_MODE}min session\\nClick: Start\\nScroll: Change mode (15/25/50/90)\\nMiddle: Reset"
    fi
else
    # Timer stopped
    output_json "🍅 ${SELECTED_MODE}min" "stopped" "Ready for ${SELECTED_MODE}min session\\nClick: Start\\nScroll: Change mode (15/25/50/90)\\nMiddle: Reset"
fi
