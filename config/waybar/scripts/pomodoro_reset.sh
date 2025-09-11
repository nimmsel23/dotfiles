#!/bin/bash
# pomodoro_reset.sh - Kompletter Reset

# Alle Pomodoro-Dateien löschen
rm -f "/tmp/.pomodoro_timer" "/tmp/.pomodoro_locked" "/tmp/.pomodoro_mode"

# Notification senden
notify-send "🍅 Pomodoro" "Timer und Modus zurückgesetzt" -t 2000

# Waybar aktualisieren
pkill -RTMIN+8 waybar