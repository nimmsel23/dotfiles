#!/bin/bash

# Speedtest ausführen und Ergebnis speichern
RESULT=$(speedtest-cli --simple 2>&1)

if [ $? -eq 0 ]; then
    # Erfolgreich - Ergebnis in Notification anzeigen
    PING=$(echo "$RESULT" | grep "Ping:" | cut -d' ' -f2-3)
    DOWNLOAD=$(echo "$RESULT" | grep "Download:" | cut -d' ' -f2-3)
    UPLOAD=$(echo "$RESULT" | grep "Upload:" | cut -d' ' -f2-3)
    
    notify-send -t 10000 "🚀 Speedtest Results" \
        "📡 Ping: $PING\n⬇️  Download: $DOWNLOAD\n⬆️  Upload: $UPLOAD"
else
    # Fehler - Fehlermeldung anzeigen
    notify-send -t 5000 "❌ Speedtest Failed" "$RESULT"
fi
