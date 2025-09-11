#!/bin/bash
OPTIONS="Lock\nLogout\nSuspend\nReboot\nShutdown"
CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power Menu")

case "$CHOICE" in
    Lock) hyprlock ;;
    Logout) hyprctl dispatch exit ;;
    Suspend) systemctl suspend ;;
    Reboot) systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
