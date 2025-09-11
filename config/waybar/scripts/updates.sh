#!/bin/bash

case "$1" in
    "click")
        # Bestimme verfügbaren Package Manager und installiere Updates
        if command -v yay >/dev/null 2>&1; then
            alacritty -e bash -c "yay -Syu; read -p 'Drücke Enter zum Schließen...'"
        elif command -v paru >/dev/null 2>&1; then
            alacritty -e bash -c "paru -Syu; read -p 'Drücke Enter zum Schließen...'"
        elif command -v pamac >/dev/null 2>&1; then
            alacritty -e bash -c "pamac upgrade -a; read -p 'Drücke Enter zum Schließen...'"
        else
            alacritty -e bash -c "sudo pacman -Syu; read -p 'Drücke Enter zum Schließen...'"
        fi
        ;;
    *)
        # System-Updates prüfen
        if command -v yay >/dev/null 2>&1; then
            updates=$(yay -Qu 2>/dev/null | wc -l)
        elif command -v paru >/dev/null 2>&1; then
            updates=$(paru -Qu 2>/dev/null | wc -l)
        elif command -v pamac >/dev/null 2>&1; then
            updates=$(pamac checkupdates -q 2>/dev/null | wc -l)
        else
            updates=$(checkupdates 2>/dev/null | wc -l)
        fi

        # Fehlerbehandlung
        if [ $? -ne 0 ]; then
            echo "{\"text\":\"📦 Error\",\"class\":\"error\",\"tooltip\":\"Failed to check updates\"}"
            exit 1
        fi

        # Zustandsklasse
        if [ $updates -gt 0 ]; then
            class="warning"
        else
            class="normal"
        fi

        # JSON-Ausgabe (kompakt ohne "updates" Text)
        echo "{\"text\":\"📦 $updates\",\"class\":\"$class\",\"tooltip\":\"$updates updates available - Klicken zum Installieren\"}"
        ;;
esac
