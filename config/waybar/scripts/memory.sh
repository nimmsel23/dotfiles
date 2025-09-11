#!/bin/bash

# Speicherauslastung berechnen
used=$(free -m | awk 'NR==2{print $3}')
total=$(free -m | awk 'NR==2{print $2}')
percent=$((used * 100 / total))

# Fortschrittsbalken (10 Segmente)
bar_length=10
filled=$((percent / 10))
bar=$(printf '█%.0s' $(seq 1 $filled))
empty=$((bar_length - filled))
if [ $empty -gt 0 ]; then
    bar="$bar$(printf '░%.0s' $(seq 1 $empty))"
fi

# Zustandsklasse
if [ $percent -gt 80 ]; then
    class="high"
else
    class="normal"
fi

# JSON-Ausgabe
echo "{\"text\":\"🧠 $bar $percent%\",\"class\":\"$class\",\"tooltip\":\"Memory Usage: $percent%\"}"
