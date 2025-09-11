#!/bin/bash

CITY="Vienna"  # Ersetze mit deiner Stadt
CACHE_FILE="/tmp/weather_cache"

# Cache für 30 Minuten
if [ -f "$CACHE_FILE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -lt 1800 ]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Wetterdaten abrufen
weather=$(curl -s "wttr.in/$CITY?format=%c%t" 2>/dev/null)
if [ -z "$weather" ]; then
    echo "{\"text\":\"❓ Error\",\"class\":\"error\",\"tooltip\":\"Failed to fetch weather\"}" | tee "$CACHE_FILE"
    exit 1
fi

# JSON-Ausgabe
echo "{\"text\":\"$weather\",\"class\":\"normal\",\"tooltip\":\"Weather in $CITY: $weather\"}" | tee "$CACHE_FILE"
