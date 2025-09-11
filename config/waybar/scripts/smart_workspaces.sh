#!/bin/bash
# smart_workspaces.sh - Simple workspace display

if pgrep -x "sway" > /dev/null; then
    workspaces=$(swaymsg -t get_workspaces)
    current=$(echo "$workspaces" | jq -r '.[] | select(.focused==true) | .name')
    
    workspace_list=""
    for ws in $(echo "$workspaces" | jq -r '.[].name' | sort -n); do
        if [ "$ws" = "$current" ]; then
            workspace_list+="●$ws "
        else
            workspace_list+="○$ws "
        fi
    done
    
    echo "{\"text\":\"$workspace_list\",\"tooltip\":\"Workspaces\"}"
else
    echo "{\"text\":\"●1 ○2 ○3 ○4\",\"tooltip\":\"Workspaces\"}"
fi
