#!/bin/bash

SRC="$HOME/dev"
DST="gdrive:dev"
BACKUP="gdrive:dev_backup"

rclone bisync "$SRC" "$DST" \
  --exclude-from "$HOME/.config/rclone/default.ignore" \
  --backup-dir "$BACKUP" \
  --resync \
  --log-file "$HOME/.cache/rclone/bisync_dev.log" \
  --log-level INFO
