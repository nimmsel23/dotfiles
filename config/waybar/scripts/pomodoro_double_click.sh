#!/bin/bash
# pomodoro_double_click.sh - Rechtsklick-Handler für Moduswechsel
TIMER_FILE="/tmp/.pomodoro_timer"
MODE_FILE="/tmp/.pomodoro_mode"

# Aktuellen Modus bestimmen
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE")
else
    MODE="25"
fi

# Timer stoppen falls er läuft
if [ -f "$TIMER_FILE" ]; then
    rm -f "$TIMER_FILE" "/tmp/.pomodoro_locked"
fi

# Modus wechseln und Timer starten
if [ "$MODE" = "25" ]; then
    echo "50" > "$MODE_FILE"
    date +%s > "$TIMER_FILE"
    notify-send "🍅 Pomodoro" "50-Minuten-Session gestartet!" -t 3000
else
    echo "25" > "$MODE_FILE"
    date +%s > "$TIMER_FILE"
    notify-send "🍅 Pomodoro" "25-Minuten-Session gestartet!" -t 3000
fi

# Waybar aktualisieren
pkill -RTMIN+8 waybar
