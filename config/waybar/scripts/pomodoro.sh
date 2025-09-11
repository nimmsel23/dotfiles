#!/bin/bash
# ~/.config/waybar/scripts/pomodoro.sh

STATE_FILE="/tmp/.pomodoro_timer"
POMODORO_LENGTH=1500 # 25 Minuten

now=$(date +%s)

# Initialisieren, wenn Datei nicht existiert
if [ ! -f "$STATE_FILE" ]; then
  echo "$now" > "$STATE_FILE"
fi

start_time=$(cat "$STATE_FILE")
elapsed=$((now - start_time))
remaining=$((POMODORO_LENGTH - elapsed))

if [ "$remaining" -le 0 ]; then
  echo "⏰ Done"
else
  min=$((remaining / 60))
  sec=$((remaining % 60))
  printf "🍅 %02d:%02d\\n" "$min" "$sec"
fi
