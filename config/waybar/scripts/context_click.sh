#!/bin/bash
# context_click.sh - Handle context clicks

# Simple action based on current context
if pgrep -x "firefox\|falkon" >/dev/null 2>&1; then
    foot nmtui
elif pgrep -x "code\|nvim" >/dev/null 2>&1; then
    foot btop
else
    notify-send "Context" "Click to interact with current context"
fi
