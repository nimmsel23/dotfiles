#!/bin/bash
# window.sh - Auto-detect Sway/Hyprland and show active window

# Detect which WM is running
if pgrep -x "sway" > /dev/null; then
    WM="sway"
elif pgrep -x "Hyprland" > /dev/null; then
    WM="hyprland"
else
    echo '{"text":"","class":"unknown","tooltip":"No active window"}'
    exit 1
fi

if [ "$WM" = "sway" ]; then
    # Sway active window
    window_info=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true)')
    
    if [ "$window_info" != "null" ] && [ -n "$window_info" ]; then
        title=$(echo "$window_info" | jq -r '.name // empty')
        app_id=$(echo "$window_info" | jq -r '.app_id // .window_properties.class // empty')
        
        if [ -n "$title" ] && [ "$title" != "null" ]; then
            # Truncate long titles
            if [ ${#title} -gt 50 ]; then
                display_title="${title:0:47}..."
            else
                display_title="$title"
            fi
            
            echo "{\"text\":\"$display_title\",\"class\":\"sway\",\"tooltip\":\"Sway Window\\nTitle: $title\\nApp: $app_id\"}"
        else
            echo '{"text":"","class":"sway","tooltip":"No active window"}'
        fi
    else
        echo '{"text":"","class":"sway","tooltip":"No active window"}'
    fi

elif [ "$WM" = "hyprland" ]; then
    # Hyprland active window
    window_info=$(hyprctl activewindow -j)
    
    if [ "$window_info" != "{}" ] && [ -n "$window_info" ]; then
        title=$(echo "$window_info" | jq -r '.title // empty')
        class=$(echo "$window_info" | jq -r '.class // empty')
        
        if [ -n "$title" ] && [ "$title" != "null" ] && [ "$title" != "" ]; then
            # Truncate long titles
            if [ ${#title} -gt 50 ]; then
                display_title="${title:0:47}..."
            else
                display_title="$title"
            fi
            
            echo "{\"text\":\"$display_title\",\"class\":\"hyprland\",\"tooltip\":\"Hyprland Window\\nTitle: $title\\nClass: $class\"}"
        else
            echo '{"text":"","class":"hyprland","tooltip":"No active window"}'
        fi
    else
        echo '{"text":"","class":"hyprland","tooltip":"No active window"}'
    fi
fi
