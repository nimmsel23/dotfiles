#!/bin/bash
if pgrep -x "sway" > /dev/null; then
    ln -sf ~/.config/sway/waybar/style.css ~/.config/waybar/style.css
elif pgrep -x "Hyprland" > /dev/null; then
    ln -sf ~/.config/hypr/waybar/style.css ~/.config/waybar/style.css
fi
