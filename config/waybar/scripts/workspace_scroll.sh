#!/bin/bash
# workspace_scroll.sh - Handle workspace scrolling

direction="$1"

# Detect which WM is running
if pgrep -x "sway" > /dev/null; then
    if [ "$direction" = "up" ]; then
        swaymsg workspace next
    else
        swaymsg workspace prev
    fi
elif pgrep -x "Hyprland" > /dev/null; then
    if [ "$direction" = "up" ]; then
        hyprctl dispatch workspace e+1
    else
        hyprctl dispatch workspace e-1
    fi
fi
