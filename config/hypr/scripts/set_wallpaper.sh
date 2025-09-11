#!/bin/bash

# Verzeichnis für Wallpapers
WALLPAPER_DIR=~/Pictures/wallpapers
DEFAULT_WALL="$WALLPAPER_DIR/default.jpg"
FALLBACK_WALL="$WALLPAPER_DIR/fallback.jpg"

# Erstelle Verzeichnis, falls es nicht existiert
mkdir -p "$WALLPAPER_DIR"

# Lade ein neues Wallpaper, wenn keines vorhanden ist
if [ ! -f "$DEFAULT_WALL" ]; then
    echo "Lade neues Wallpaper..."
    if ! curl -L -o "$DEFAULT_WALL" "https://source.unsplash.com/1920x1080/?mountain,galaxy" 2>/dev/null; then
        echo "Fehler beim Laden des Wallpapers, Fallback wird verwendet."
        # Fallback-Wallpaper (z. B. eine lokale Datei oder ein Platzhalter)
        if [ ! -f "$FALLBACK_WALL" ]; then
            convert -size 1920x1080 xc:black "$FALLBACK_WALL" 2>/dev/null || touch "$FALLBACK_WALL"
        fi
        WALL="$FALLBACK_WALL"
    else
        WALL="$DEFAULT_WALL"
    fi
else
    WALL="$DEFAULT_WALL"
fi

# Optional: Zufälliges Wallpaper aus einer Liste wählen
WALLPAPERS=("$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.png)
if [ ${#WALLPAPERS[@]} -gt 1 ]; then
    WALL="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"
fi

# Hyprpaper.conf aktualisieren (nur den Wallpaper-Eintrag ändern)
HYPRPAPER_CONF=~/.config/hypr/hyprpaper.conf
if [ -f "$HYPRPAPER_CONF" ]; then
    sed -i "s|^wallpaper=.*|wallpaper=,$WALL|" "$HYPRPAPER_CONF" 2>/dev/null || \
    echo "wallpaper=,$WALL" >> "$HYPRPAPER_CONF"
else
    echo "wallpaper=,$WALL" > "$HYPRPAPER_CONF"
fi

# Hyprpaper starten oder neu laden
if pgrep -x hyprpaper > /dev/null; then
    hyprctl dispatch dpms off && hyprctl dispatch dpms on
else
    hyprpaper &
fi

echo "Wallpaper wurde auf $WALL gesetzt."
