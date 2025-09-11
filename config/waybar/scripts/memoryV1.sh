#!/bin/bash

# memory.sh - Speichernutzung für Waybar anzeigen

# RAM-Nutzung in Prozent und Werten berechnen
get_memory_usage() {
  # Informationen aus /proc/meminfo holen
  mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
  mem_used=$((mem_total - mem_available))
  
  # Prozentuale Nutzung berechnen
  percentage=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total*100)}")
  
  # Nutzung in Menschenlesbare Form umwandeln (GB)
  used_gb=$(awk "BEGIN {printf \"%.1f\", $mem_used/1024/1024}")
  total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total/1024/1024}")
  
  # Ergebnis zurückgeben
  echo "$percentage:$used_gb:$total_gb"
}

# Passende Emoji basierend auf der Speichernutzung auswählen
get_memory_emoji() {
  percentage=$1
  if (( $(echo "$percentage < 30" | bc -l) )); then
    echo "🧠"  # Viel freier Speicher
  elif (( $(echo "$percentage < 70" | bc -l) )); then
    echo "💭"  # Moderater Speicherverbrauch
  elif (( $(echo "$percentage < 85" | bc -l) )); then
    echo "⚠️"  # Warnung - hohe Nutzung
  else
    echo "❗"  # Kritisch - sehr hohe Nutzung
  fi
}

# Hauptfunktion
main() {
  # Speicherinformationen abrufen
  memory_info=$(get_memory_usage)
  percentage=$(echo "$memory_info" | cut -d':' -f1)
  used_gb=$(echo "$memory_info" | cut -d':' -f2)
  total_gb=$(echo "$memory_info" | cut -d':' -f3)
  
  # Emoji basierend auf Nutzung auswählen
  memory_emoji=$(get_memory_emoji "$percentage")
  
  # Ausgabe formatieren
  echo "$memory_emoji ${percentage}% (${used_gb}/${total_gb} GB)"
}

# Skript ausführen
main
