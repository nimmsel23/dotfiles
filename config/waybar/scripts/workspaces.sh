#!/bin/bash
# workspaces.sh - Auto-detect Sway/Hyprland and show workspaces

# Detect which WM is running
if pgrep -x "sway" > /dev/null; then
    WM="sway"
elif pgrep -x "Hyprland" > /dev/null; then
    WM="hyprland"
else
    echo '{"text":"❓","class":"unknown","tooltip":"Unknown WM"}'
    exit 1
fi

if [ "$WM" = "sway" ]; then
    # Sway workspaces - Minimal with numbers
    workspaces=$(swaymsg -t get_workspaces)
    current=$(echo "$workspaces" | jq -r '.[] | select(.focused==true) | .name')
    
    # Build workspace list with numbers only
    workspace_list=""
    for ws in $(echo "$workspaces" | jq -r '.[].name' | sort -n); do
        if [ "$ws" = "$current" ]; then
            workspace_list+="<span color='#a6e3a1' weight='bold'>$ws</span> "
        else
            workspace_list+="<span color='#6c7086'>$ws</span> "
        fi
    done
    
    echo "{\"text\":\"$workspace_list\",\"class\":\"sway\",\"tooltip\":\"Sway Workspaces\\nActive: $current\"}"

elif [ "$WM" = "hyprland" ]; then
    # Hyprland workspaces - Keep emoji icons
    declare -A ICONS=(
        ["1"]="⚔️"
        ["2"]="🌐"
        ["3"]="🧪"
        ["4"]="📂"
        ["5"]="🍎"
        ["6"]="🍍"
        ["7"]="7"
        ["8"]="🥒"
        ["9"]="👑"
        ["10"]="10"
    )
    
    workspaces=$(hyprctl workspaces -j)
    current=$(hyprctl activeworkspace -j | jq -r '.id')
    
    # Build workspace list with icons for Hyprland
    workspace_list=""
    for ws in $(echo "$workspaces" | jq -r '.[].id' | sort -n); do
        icon="${ICONS[$ws]:-$ws}"
        if [ "$ws" = "$current" ]; then
            workspace_list+="<span color='#a6e3a1'>$icon</span> "
        else
            workspace_list+="<span color='#636777'>$icon</span> "
        fi
    done
    
    echo "{\"text\":\"$workspace_list\",\"class\":\"hyprland\",\"tooltip\":\"Hyprland Workspaces\\nActive: $current\"}"
fi
