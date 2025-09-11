#!/bin/bash

# Mock-Logik für Mondphasen (ersetze mit echter API, falls verfügbar)
CACHE_FILE="/tmp/moon_cache"
CURRENT_DAY=$(date +%d)
PHASE_CYCLE=29.53  # Mondzyklus in Tagen

# Cache für 30 Minuten
if [ -f "$CACHE_FILE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -lt 1800 ]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Simulierte Berechnung der Mondphase
day_of_cycle=$(echo "$CURRENT_DAY % $PHASE_CYCLE" | bc -l)
if (( $(echo "$day_of_cycle < 1 || $day_of_cycle > 29" | bc -l) )); then
    phase="New Moon"
    class="normal"
elif (( $(echo "$day_of_cycle >= 1 && $day_of_cycle < 7.5" | bc -l) )); then
    phase="Waxing Crescent"
    class="normal"
elif (( $(echo "$day_of_cycle >= 7.5 && $day_of_cycle < 14.5" | bc -l) )); then
    phase="First Quarter"
    class="warning"
elif (( $(echo "$day_of_cycle >= 14.5 && $day_of_cycle < 15.5" | bc -l) )); then
    phase="Full Moon"
    class="full-moon"
elif (( $(echo "$day_of_cycle >= 15.5 && $day_of_cycle < 22.5" | bc -l) )); then
    phase="Waning Gibbous"
    class="normal"
elif (( $(echo "$day_of_cycle >= 22.5 && $day_of_cycle < 29" | bc -l) )); then
    phase="Last Quarter"
    class="warning"
else
    phase="Error"
    class="error"
fi

# JSON-Ausgabe
output="{\"text\":\"🌙 $phase\",\"tooltip\":\"Mondphase: $phase\",\"class\":\"$class\"}"
echo "$output" | tee "$CACHE_FILE"
