#!/bin/bash

# Pfad zum lokalen Ordner
LOCAL_PATH="$HOME/Dokumente/BODY/ANATOMIE"

# Google Drive Remote-Name
REMOTE_NAME="gdrive"

# Zielpfad in Google Drive
REMOTE_PATH="BODY/ANATOMIE"

# Log-Datei
LOG_FILE="$HOME/log/anatomie_bisync.log"

# Prüfe ob lokaler Pfad existiert
if [ ! -d "$LOCAL_PATH" ]; then
    echo "$(date): Lokaler Pfad $LOCAL_PATH existiert nicht" >> "$LOG_FILE"
    exit 1
fi

# Synchronisation mit rclone bisync
echo "$(date): Starte Bisync für $LOCAL_PATH" >> "$LOG_FILE"
rclone bisync "$LOCAL_PATH" "$REMOTE_NAME:$REMOTE_PATH" --log-file="$LOG_FILE" --log-level INFO

# Fehlerprüfung
if [ $? -eq 0 ]; then
    echo "$(date): Synchronisation erfolgreich" >> "$LOG_FILE"
    echo "✅ ANATOMIE Bisync erfolgreich"
else
    echo "$(date): Fehler bei der Synchronisation" >> "$LOG_FILE"
    echo "❌ FEHLER bei ANATOMIE Bisync (siehe Log: $LOG_FILE)"
fi
