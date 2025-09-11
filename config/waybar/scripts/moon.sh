#!/bin/bash
# moon.sh - Korrigiertes Vollmond-Vorwarnungsskript für Waybar
# Verwendet einfache, aber präzise Berechnungen ohne externe APIs

# Konfiguration
CACHE_FILE="/tmp/moon_data_cache"
CACHE_DURATION=1800  # Cache für 30 Minuten
DEBUG=false          # Auf true setzen für Debug-Ausgaben

# Debug-Funktion
debug() {
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: $1" >&2
    fi
}

# Berechne Tage seit bekanntem Neumond
calculate_days_since_reference() {
    # Bekannter Neumond: 27. Mai 2025, 01:31 UT
    # Verwende einfache Tage-Differenz statt Julian Date
    local ref_year=2025
    local ref_month=5
    local ref_day=27.0625  # 27. Mai + 1.5 Stunden = 0.0625 Tage
    
    # Aktuelles Datum
    local current_year=$(date +%Y)
    local current_month=$(date +%m)
    local current_day=$(date +%d)
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    
    # Entferne führende Nullen
    current_month=$((10#$current_month))
    current_day=$((10#$current_day))
    current_hour=$((10#$current_hour))
    current_minute=$((10#$current_minute))
    
    # Berechne aktuellen Tag mit Tageszeit
    local current_day_decimal=$(echo "scale=6; $current_day + ($current_hour + $current_minute/60) / 24" | bc -l)
    
    # Einfache Tage-Differenz-Berechnung
    local days_diff
    
    if [ "$current_year" -eq "$ref_year" ] && [ "$current_month" -eq "$ref_month" ]; then
        # Gleicher Monat (Mai 2025)
        days_diff=$(echo "scale=6; $current_day_decimal - $ref_day" | bc -l)
    elif [ "$current_year" -eq "$ref_year" ] && [ "$current_month" -gt "$ref_month" ]; then
        # Spätere Monate in 2025
        local days_from_ref=0
        
        # Tage vom Referenztag bis Ende Mai
        days_from_ref=$(echo "scale=6; 31 - $ref_day" | bc -l)
        
        # Ganze Monate dazwischen
        local month=$((ref_month + 1))
        while [ "$month" -lt "$current_month" ]; do
            case $month in
                6) days_from_ref=$(echo "scale=6; $days_from_ref + 30" | bc -l) ;;  # Juni
                7) days_from_ref=$(echo "scale=6; $days_from_ref + 31" | bc -l) ;;  # Juli
                8) days_from_ref=$(echo "scale=6; $days_from_ref + 31" | bc -l) ;;  # August
                9) days_from_ref=$(echo "scale=6; $days_from_ref + 30" | bc -l) ;;  # September
                10) days_from_ref=$(echo "scale=6; $days_from_ref + 31" | bc -l) ;; # Oktober
                11) days_from_ref=$(echo "scale=6; $days_from_ref + 30" | bc -l) ;; # November
                12) days_from_ref=$(echo "scale=6; $days_from_ref + 31" | bc -l) ;; # Dezember
            esac
            month=$((month + 1))
        done
        
        # Aktuelle Tage im aktuellen Monat
        days_diff=$(echo "scale=6; $days_from_ref + $current_day_decimal" | bc -l)
    else
        # Andere Jahre - verwende Unix-Timestamps für Genauigkeit
        local ref_timestamp=$(date -d "2025-05-27 01:30" +%s)
        local current_timestamp=$(date +%s)
        local seconds_diff=$((current_timestamp - ref_timestamp))
        days_diff=$(echo "scale=6; $seconds_diff / 86400" | bc -l)
    fi
    
    debug "Reference: $ref_year-$ref_month-$ref_day"
    debug "Current: $current_year-$current_month-$current_day_decimal"
    debug "Days since reference: $days_diff"
    
    echo "$days_diff"
}

# Berechne aktuelles Mondalter
calculate_moon_age() {
    local days_since_ref=$1
    local synodic_month=29.530588861
    
    # Modulo-Operation um das Mondalter zu bekommen
    local cycles=$(echo "scale=10; $days_since_ref / $synodic_month" | bc -l)
    local whole_cycles=$(echo "scale=0; $cycles / 1" | bc -l)
    local fractional_cycle=$(echo "scale=10; $cycles - $whole_cycles" | bc -l)
    local moon_age=$(echo "scale=6; $fractional_cycle * $synodic_month" | bc -l)
    
    # Stelle sicher, dass moon_age positiv ist
    if (( $(echo "$moon_age < 0" | bc -l) )); then
        moon_age=$(echo "scale=6; $moon_age + $synodic_month" | bc -l)
    fi
    
    debug "Cycles: $cycles"
    debug "Whole cycles: $whole_cycles"
    debug "Fractional cycle: $fractional_cycle"
    debug "Moon age: $moon_age days"
    
    echo "$moon_age"
}

# Berechne Mondphase (0-1)
get_moon_phase() {
    local moon_age=$1
    local synodic_month=29.530588861
    local phase=$(echo "scale=6; $moon_age / $synodic_month" | bc -l)
    echo "$phase"
}

# Berechne Tage bis zum nächsten Vollmond
days_to_full_moon() {
    local moon_age=$1
    local synodic_month=29.530588861
    local full_moon_age=$(echo "scale=6; $synodic_month / 2" | bc -l)  # ~14.765 Tage
    
    local days_to_full
    
    if (( $(echo "$moon_age <= $full_moon_age" | bc -l) )); then
        # Vor Vollmond in diesem Zyklus
        days_to_full=$(echo "scale=6; $full_moon_age - $moon_age" | bc -l)
    else
        # Nach Vollmond - nächster Vollmond ist im nächsten Zyklus
        days_to_full=$(echo "scale=6; $synodic_month + $full_moon_age - $moon_age" | bc -l)
    fi
    
    debug "Full moon age: $full_moon_age"
    debug "Current moon age: $moon_age"
    debug "Days to full moon: $days_to_full"
    
    echo "$days_to_full"
}

# Bestimme Mond-Emoji und Phase
get_moon_info() {
    local phase=$1
    local phase_percent=$(echo "scale=1; $phase * 100" | bc -l)
    local phase_name=""
    local emoji=""
    
    # Bestimme Mondphase und Emoji
    if (( $(echo "$phase <= 0.0625" | bc -l) )) || (( $(echo "$phase >= 0.9375" | bc -l) )); then
        emoji="🌑"
        phase_name="Neumond"
    elif (( $(echo "$phase <= 0.1875" | bc -l) )); then
        emoji="🌒"
        phase_name="Zunehmende Sichel"
    elif (( $(echo "$phase <= 0.3125" | bc -l) )); then
        emoji="🌓"
        phase_name="Erstes Viertel"
    elif (( $(echo "$phase <= 0.4375" | bc -l) )); then
        emoji="🌔"
        phase_name="Zunehmender Mond"
    elif (( $(echo "$phase <= 0.5625" | bc -l) )); then
        emoji="🌕"
        phase_name="Vollmond"
    elif (( $(echo "$phase <= 0.6875" | bc -l) )); then
        emoji="🌖"
        phase_name="Abnehmender Mond"
    elif (( $(echo "$phase <= 0.8125" | bc -l) )); then
        emoji="🌗"
        phase_name="Letztes Viertel"
    else
        emoji="🌘"
        phase_name="Abnehmende Sichel"
    fi
    
    echo "$emoji|$phase_name|$phase_percent"
}

# Formatiere Waybar-Ausgabe
format_output() {
    local phase=$1
    local days_to_full=$2
    local moon_info=$(get_moon_info "$phase")
    
    local emoji=$(echo "$moon_info" | cut -d'|' -f1)
    local phase_name=$(echo "$moon_info" | cut -d'|' -f2)
    local phase_percent=$(echo "$moon_info" | cut -d'|' -f3)
    
    local days_rounded=$(printf "%.0f" "$days_to_full")
    local hours_to_full=$(echo "scale=1; $days_to_full * 24" | bc -l)
    local hours_rounded=$(printf "%.0f" "$hours_to_full")
    
    # Spezielle Behandlung für Vollmond-Nähe
    if (( $(echo "$days_to_full <= 0.5" | bc -l) )); then
        if (( $(echo "$hours_to_full <= 6" | bc -l) )); then
            echo "{\"text\":\"$emoji Vollmond!\",\"class\":\"full-moon\",\"tooltip\":\"Vollmond in ca. $hours_rounded Stunden\\n$phase_name ($phase_percent%)\"}"
        else
            echo "{\"text\":\"$emoji Heute!\",\"class\":\"full-moon\",\"tooltip\":\"Vollmond heute\\n$phase_name ($phase_percent%)\"}"
        fi
    elif (( $(echo "$days_to_full <= 1" | bc -l) )); then
        echo "{\"text\":\"$emoji Morgen\",\"class\":\"warning\",\"tooltip\":\"Vollmond morgen\\n$phase_name ($phase_percent%)\"}"
    elif (( $(echo "$days_to_full <= 2" | bc -l) )); then
        echo "{\"text\":\"$emoji $days_rounded Tage\",\"class\":\"warning\",\"tooltip\":\"Vollmond in $days_rounded Tagen\\n$phase_name ($phase_percent%)\"}"
    else
        # Normale Anzeige
        local day_word="Tage"
        if [ "$days_rounded" -eq "1" ]; then
            day_word="Tag"
        fi
        
        echo "{\"text\":\"$emoji $days_rounded $day_word\",\"class\":\"normal\",\"tooltip\":\"Nächster Vollmond in $days_rounded $day_word\\n$phase_name ($phase_percent%)\"}"
    fi
}

# Cache-Funktionen
load_from_cache() {
    if [ -f "$CACHE_FILE" ]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local age=$((current_time - cache_time))
        
        if [ "$age" -lt "$CACHE_DURATION" ]; then
            cat "$CACHE_FILE"
            return 0
        fi
    fi
    return 1
}

save_to_cache() {
    echo "$1" > "$CACHE_FILE"
}

# Hauptfunktion
get_moon_data() {
    # Temporär Cache deaktivieren für Tests
    # rm -f "$CACHE_FILE"
    
    # Prüfe Cache zuerst
    if load_from_cache; then
        debug "Using cached data"
        return 0
    fi
    
    debug "Calculating new moon data"
    
    # Berechne aktuelle Mondphase
    local days_since_ref=$(calculate_days_since_reference)
    local moon_age=$(calculate_moon_age "$days_since_ref")
    local phase=$(get_moon_phase "$moon_age")
    local days_to_full=$(days_to_full_moon "$moon_age")
    local output=$(format_output "$phase" "$days_to_full")
    
    # Speichere in Cache
    save_to_cache "$output"
    echo "$output"
}

# Test-Modus
if [ "$1" = "--test" ] || [ "$1" = "-t" ]; then
    DEBUG=true
    # Cache löschen für Test
    rm -f "$CACHE_FILE"
    echo "=== Mondphasen-Test ==="
    days_since_ref=$(calculate_days_since_reference)
    echo "Tage seit Referenz-Neumond: $days_since_ref"
    moon_age=$(calculate_moon_age "$days_since_ref")
    echo "Mondalter: $moon_age Tage"
    phase=$(get_moon_phase "$moon_age")
    echo "Mondphase: $phase ($(echo "scale=1; $phase * 100" | bc -l)%)"
    days=$(days_to_full_moon "$moon_age")
    echo "Tage bis Vollmond: $days"
    moon_info=$(get_moon_info "$phase")
    echo "Mondinfo: $moon_info"
    echo "=== Waybar-Ausgabe ==="
fi

# Hauptausführung
if command -v bc >/dev/null 2>&1; then
    if moon_info=$(get_moon_data 2>/dev/null); then
        echo "$moon_info"
    else
        echo "{\"text\":\"🌙 ?\",\"class\":\"error\",\"tooltip\":\"Fehler beim Berechnen der Monddaten\"}"
    fi
else
    echo "{\"text\":\"🌙 !\",\"class\":\"error\",\"tooltip\":\"'bc' nicht installiert\\nInstalliere mit: sudo apt install bc\"}"
fi
