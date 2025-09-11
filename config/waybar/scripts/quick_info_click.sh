#!/bin/bash
# quick_info_click.sh - Click actions for quick info

MODE=$(cat /tmp/quick_info_mode 2>/dev/null || echo 0)

case $MODE in
    0) foot btop ;;               # System load -> btop
    1) foot sudo pacman -Syu ;;   # Updates -> update system  
    2) foot ncdu / ;;             # Disk -> disk analyzer
    3) gnome-calendar ;;          # Moon/Date -> calendar
esac

