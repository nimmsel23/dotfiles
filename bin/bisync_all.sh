#!/bin/bash

LOGDIR="$HOME/.cache/rclone"
mkdir -p "$LOGDIR"

IGNORE="$HOME/.config/rclone/default.ignore"

declare -A SYNC_PAIRS=(
  ["$HOME/dev"]="gdrive:dev"
  ["$HOME/bin"]="gdrive:bin"
  ["$HOME/.alpha_os"]="gdrive:alpha_os"
)

for SRC in "${!SYNC_PAIRS[@]}"; do
  DST="${SYNC_PAIRS[$SRC]}"
  BACKUP="${DST}_backup"
  NAME=$(basename "$SRC")
  LOGFILE="$LOGDIR/bisync_${NAME}.log"

  echo "→ Syncing $SRC → $DST"

  # Prüfe ob Source-Verzeichnis existiert
  if [ ! -d "$SRC" ]; then
    echo "⚠️  Überspringe $SRC (Verzeichnis existiert nicht)"
    continue
  fi

  rclone bisync "$SRC" "$DST" \
    --exclude-from "$IGNORE" \
    --backup-dir "$BACKUP" \
    --resync \
    --log-file "$LOGFILE" \
    --log-level INFO

  if [ $? -eq 0 ]; then
    echo "✅ Bisync erfolgreich: $NAME → $DST"
  else
    echo "❌ FEHLER bei Bisync: $NAME → $DST (siehe Log: $LOGFILE)"
  fi
done
