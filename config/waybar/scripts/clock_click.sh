#!/bin/bash

# Clock Click Handler - Verbesserte Version
# Speichere als ~/.config/waybar/scripts/clock_click.sh

# Funktionen für verschiedene Aktionen
open_calendar_app() {
    if command -v gnome-calendar &> /dev/null; then
        gnome-calendar &
        return 0
    elif command -v evolution &> /dev/null; then
        evolution -c calendar &
        return 0
    elif command -v thunderbird &> /dev/null; then
        thunderbird -calendar &
        return 0
    else
        return 1
    fi
}

show_task_overview() {
    if command -v task &> /dev/null; then
        # Task-Übersicht in einem schönen Terminal-Window
        if command -v alacritty &> /dev/null; then
            alacritty --title "Task Overview" -e bash -c "
                echo '📋 Task Overview:'
                echo '=================='
                echo
                task summary 2>/dev/null || echo 'No tasks found'
                echo
                echo '📅 This week:'
                echo '============='
                task due.before:eow list 2>/dev/null || echo 'No tasks due this week'
                echo
                echo '⚡ Next 10 tasks:'
                echo '================'
                task limit:10 2>/dev/null || echo 'No tasks found'
                echo
                echo 'Press ENTER to close...'
                read
            " &
        elif command -v kitty &> /dev/null; then
            kitty --title "Task Overview" bash -c "
                echo '📋 Task Overview:'
                echo '=================='
                echo
                task summary 2>/dev/null || echo 'No tasks found'
                echo
                echo '📅 This week:'
                echo '============='
                task due.before:eow list 2>/dev/null || echo 'No tasks due this week'
                echo
                echo '⚡ Next 10 tasks:'
                echo '================'
                task limit:10 2>/dev/null || echo 'No tasks found'
                echo
                echo 'Press ENTER to close...'
                read
            " &
        else
            # Fallback für andere Terminals
            x-terminal-emulator -T "Task Overview" -e bash -c "
                clear
                echo '📋 Task Overview:'
                echo '=================='
                echo
                task summary 2>/dev/null || echo 'No tasks found'
                echo
                echo 'Press ENTER to close...'
                read
            " &
        fi
        return 0
    else
        return 1
    fi
}

open_web_calendar() {
    if command -v firefox &> /dev/null; then
        firefox "https://calendar.google.com" &
    elif command -v chromium &> /dev/null; then
        chromium "https://calendar.google.com" &
    elif command -v google-chrome &> /dev/null; then
        google-chrome "https://calendar.google.com" &
    else
        notify-send "Calendar" "No web browser found"
        return 1
    fi
    return 0
}

# Hauptlogik: Versuche verschiedene Optionen
if open_calendar_app; then
    # Calendar App gefunden und gestartet
    exit 0
elif show_task_overview; then
    # Task-Übersicht gezeigt
    exit 0
elif open_web_calendar; then
    # Web-Calendar geöffnet
    exit 0
else
    # Nichts funktioniert
    notify-send "Calendar" "No calendar app or browser found. Install gnome-calendar or taskwarrior."
fi
