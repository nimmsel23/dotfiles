#!/bin/bash
# window_click.sh - Handle window clicks

action="$1"

# Detect which WM is running
if pgrep -x "sway" > /dev/null; then
    case "$action" in
        "floating")
            swaymsg floating toggle
            ;;
        "fullscreen")
            swaymsg fullscreen toggle
            ;;
        "kill")
            swaymsg kill
            ;;
    esac
elif pgrep -x "Hyprland" > /dev/null; then
    case "$action" in
        "floating")
            hyprctl dispatch togglefloating
            ;;
        "fullscreen")
            hyprctl dispatch fullscreen
            ;;
        "kill")
            hyprctl dispatch killactive
            ;;
    esac
fi
