#!/bin/bash

# r-wall.sh - Zufällige Hintergründe für Hyprland
# Für Waybar-Integration und Klickfunktion zum Hintergrundwechsel

# Konfigurierbare Variablen
WALLPAPER_DIR="$HOME/Bilder/Wallpapers"      # Pfad zu deinen Hintergrundbildern
CURRENT_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"  # Speicherort für aktuellen Hintergrund
CACHE_DIR="$HOME/.cache/wallpapers"           # Cache-Verzeichnis für Miniaturansichten
HYPRPAPER_CONFIG="$HOME/.config/hypr/hyprpaper.conf" # Hyprpaper Konfigurationsdatei
WALLPAPER_HISTORY="$HOME/.cache/wallpaper_history"  # Speichert die letzten Hintergründe

# Erstelle Cache-Verzeichnis falls es nicht existiert
mkdir -p "$CACHE_DIR"
touch "$WALLPAPER_HISTORY" 2>/dev/null

# Funktion zum Setzen eines zufälligen Hintergrundbilds
set_random_wallpaper() {
  # Prüfen ob Verzeichnis existiert
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "🖼️ ❌"  # Verzeichnis nicht gefunden
    return 1
  fi
  
  # Liste aller Bilddateien erstellen
  wallpapers=($(find "$WALLPAPER_DIR" -type f -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif"))
  
  # Prüfen ob Bilder gefunden wurden
  if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "🖼️ ❌"  # Keine Bilder gefunden
    return 1
  fi
  
  # Zufälliges Bild auswählen
  random_wallpaper=${wallpapers[$RANDOM % ${#wallpapers[@]}]}
  
  # Hyprpaper zum Setzen des Hintergrunds verwenden
  if command -v hyprctl &> /dev/null; then
    # Hintergrundbild laden und setzen
    echo "preload = $random_wallpaper" > "$HYPRPAPER_CONFIG"
    echo "wallpaper = ,${random_wallpaper}" >> "$HYPRPAPER_CONFIG"
    
    # Hyprpaper neustarten wenn es läuft
    if pgrep -x "hyprpaper" > /dev/null; then
      killall hyprpaper
    fi
    hyprpaper &
  elif command -v swaybg &> /dev/null; then
    # Fallback auf swaybg
    if pgrep -x "swaybg" > /dev/null; then
      killall swaybg
    fi
    swaybg -i "$random_wallpaper" -m fill &
  else
    echo "🖼️ ❌"  # Kein unterstütztes Programm zum Setzen des Hintergrunds gefunden
    return 1
  fi
  
  # Aktuellen Hintergrund speichern
  echo "$random_wallpaper" > "$CURRENT_WALLPAPER_FILE"
  
  # Zum Verlauf hinzufügen (maximal 10 Einträge)
  echo "$random_wallpaper" >> "$WALLPAPER_HISTORY"
  tail -n 10 "$WALLPAPER_HISTORY" > "${WALLPAPER_HISTORY}.tmp"
  mv "${WALLPAPER_HISTORY}.tmp" "$WALLPAPER_HISTORY"
  
  # Miniaturansicht für Waybar erstellen (optional)
  # convert "$random_wallpaper" -resize 64x64 "$CACHE_DIR/current_thumb.png"
  
  echo "🖼️ ✓"  # Erfolgreicher Wechsel
  return 0
}

# Funktion zum Anzeigen des aktuellen Hintergrundbilds für Waybar
show_current_wallpaper() {
  if [ -f "$CURRENT_WALLPAPER_FILE" ]; then
    wallpaper=$(cat "$CURRENT_WALLPAPER_FILE")
    # Dateiname ohne Pfad extrahieren
    wallpaper_name=$(basename "$wallpaper")
    # Zu langen Namen kürzen
    if [ ${#wallpaper_name} -gt 10 ]; then
      wallpaper_name="${wallpaper_name:0:8}..."
    fi
    echo "🖼️ $wallpaper_name"
  else
    echo "🖼️"
  fi
}

# Funktion um zum vorherigen Hintergrund zurückzukehren
set_previous_wallpaper() {
  if [ -f "$WALLPAPER_HISTORY" ]; then
    # Die letzten beiden Einträge holen (aktuell und vorherig)
    prev_wallpaper=$(tail -n 2 "$WALLPAPER_HISTORY" | head -n 1)
    
    if [ -n "$prev_wallpaper" ] && [ -f "$prev_wallpaper" ]; then
      # Vorherigen Hintergrund setzen
      if command -v hyprctl &> /dev/null; then
        echo "preload = $prev_wallpaper" > "$HYPRPAPER_CONFIG"
        echo "wallpaper = ,${prev_wallpaper}" >> "$HYPRPAPER_CONFIG"
        
        if pgrep -x "hyprpaper" > /dev/null; then
          killall hyprpaper
        fi
        hyprpaper &
      elif command -v swaybg &> /dev/null; then
        if pgrep -x "swaybg" > /dev/null; then
          killall swaybg
        fi
        swaybg -i "$prev_wallpaper" -m fill &
      fi
      
      # Aktuellen Hintergrund aktualisieren
      echo "$prev_wallpaper" > "$CURRENT_WALLPAPER_FILE"
      echo "🖼️ ↩️"  # Zurück zum vorherigen
      return 0
    fi
  fi
  
  echo "🖼️ ❌"  # Kein vorheriger Hintergrund verfügbar
  return 1
}

# Verarbeite Kommandozeilenargumente
case "$1" in
  "set")
    set_random_wallpaper
    ;;
  "prev")
    set_previous_wallpaper
    ;;
  *)
    show_current_wallpaper
    ;;
esac
