#!/bin/bash

# cpu.sh - CPU-Nutzung und Temperatur für Waybar anzeigen

# CPU-Auslastung in Prozent berechnen
get_cpu_usage() {
  # CPU-Auslastung mit top ermitteln und nur den Prozentsatz extrahieren
  usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
  echo "$usage" | awk '{printf "%.1f", $1}'
}

# CPU-Temperatur ermitteln (falls verfügbar)
get_cpu_temp() {
  if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    # Temperatur in Milligrad Celsius wird durch 1000 geteilt
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    echo "$temp" | awk '{printf "%.1f", $1/1000}'
  elif [ -x "$(command -v sensors)" ]; then
    # Alternativ mit lm-sensors
    temp=$(sensors | grep -i "cpu" | head -n 1 | awk '{print $2}' | sed 's/[^0-9.]//g')
    if [ -z "$temp" ]; then
      # Fallback, wenn kein CPU-Eintrag gefunden wurde
      temp=$(sensors | grep -i "core 0" | head -n 1 | awk '{print $2}' | sed 's/[^0-9.]//g')
    fi
    echo "$temp"
  else
    echo "N/A"
  fi
}

# Passende Emoji basierend auf der CPU-Auslastung auswählen
get_cpu_emoji() {
  usage=$1
  if (( $(echo "$usage < 20" | bc -l) )); then
    echo "🥶"  # Kalt/Ungenutzt
  elif (( $(echo "$usage < 50" | bc -l) )); then
    echo "😊"  # Moderat
  elif (( $(echo "$usage < 80" | bc -l) )); then
    echo "😓"  # Intensiv
  else
    echo "🔥"  # Sehr hoch
  fi
}

# Hauptfunktion
main() {
  cpu_usage=$(get_cpu_usage)
  cpu_temp=$(get_cpu_temp)
  cpu_emoji=$(get_cpu_emoji "$cpu_usage")
  
  # Ausgabe formatieren
  if [ "$cpu_temp" != "N/A" ]; then
    echo "$cpu_emoji ${cpu_usage}% (${cpu_temp}°C)"
  else
    echo "$cpu_emoji ${cpu_usage}%"
  fi
}

# Skript ausführen
main
