#!/bin/bash

# JSON API Module for Session Manager
# Separated for performance - only loads when needed

# Configuration
JSON_API_VERSION="1.0"
JSON_PRETTY=true

# JSON Utility Functions
json_escape() {
    local input="$1"
    # Remove ANSI escape sequences and control characters first
    echo "$input" | sed 's/\x1b\[[0-9;]*[mK]//g' | \
                   tr -d '\000-\037\177' | \
                   sed 's/\\/\\\\/g; s/"/\\"/g; s/\x08/\\b/g; s/\x0c/\\f/g; s/\x0a/\\n/g; s/\x0d/\\r/g; s/\x09/\\t/g'
}

json_timestamp() {
    date -Iseconds
}

json_pretty_print() {
    local json_content="$1"
    if command_exists jq && [ "$JSON_PRETTY" = true ]; then
        echo "$json_content" | jq .
    else
        echo "$json_content"
    fi
}

# Core JSON API - Complete System Status
api_json_status() {
    local json_content
    json_content=$(cat << EOF
{
    "meta": {
        "api_version": "$JSON_API_VERSION",
        "session_manager_version": "4.0-MODULAR",
        "timestamp": "$(json_timestamp)",
        "hostname": "$(hostname)",
        "user": "$(whoami)",
        "tty": "$(tty)",
        "pid": "$$"
    },
    "system": {
        "network": {
            "status": "$(ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && echo 'connected' || echo 'disconnected')",
            "dns_resolution": "$(nslookup google.com >/dev/null 2>&1 && echo 'working' || echo 'failed')"
        },
        "performance": {
            "load_average_1m": "$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')",
            "uptime": "$(uptime -p)",
            "uptime_seconds": "$(awk '{print int($1)}' /proc/uptime)",
            "memory_usage": "$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100.0}')",
            "cpu_count": "$(nproc)"
        },
        "storage": {
            "root_usage": "$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')",
            "available_space": "$(df -h / | awk 'NR==2 {print $4}')"
        }
    },
    "desktop_environments": $(api_json_desktops_array),
    "health_score": $(calculate_system_health_score)
}
EOF
    )
    
    json_pretty_print "$json_content"
}

# Desktop Environments JSON Array
api_json_desktops_array() {
    echo "["
    local first=true
    
    # Source detection from main session manager
    source "${DOTFILES_DIR:-$HOME/.dotfiles}/scripts/utils/common.sh" 2>/dev/null || true
    
    # Lightweight desktop detection
    if command_exists startplasma-wayland; then
        [ "$first" = true ] && first=false || echo ","
        echo '        {"id": "1", "name": "KDE Plasma (Wayland)", "wayland_support": true}'
    fi
    
    if command_exists sway; then
        [ "$first" = true ] && first=false || echo ","
        echo '        {"id": "2", "name": "Sway", "wayland_support": true}'
    fi
    
    if command_exists Hyprland; then
        [ "$first" = true ] && first=false || echo ","
        echo '        {"id": "3", "name": "Hyprland", "wayland_support": true}'
    fi
    
    if command_exists cosmic-session; then
        [ "$first" = true ] && first=false || echo ","
        echo '        {"id": "4", "name": "COSMIC Desktop", "wayland_support": true}'
    fi
    
    echo "    ]"
}

# System Health Score (simplified)
calculate_system_health_score() {
    local score=100
    
    # Network connectivity (-10 if down)
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || score=$((score - 10))
    
    # Load average (-5 per 1.0 load above CPU count)
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_count=$(nproc)
    local load_penalty=$(echo "$load $cpu_count" | awk '{if($1 > $2) print int(($1 - $2) * 5); else print 0}')
    score=$((score - load_penalty))
    
    # Memory usage (-10 if above 90%)
    local mem_usage=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100.0}')
    [ "${mem_usage:-0}" -gt 90 ] && score=$((score - 10))
    
    # Ensure score doesn't go below 0
    [ "$score" -lt 0 ] && score=0
    
    echo "$score"
}

# Fast Performance Benchmark
json_performance_benchmark() {
    echo "{"
    echo '    "benchmark_info": {'
    echo '        "timestamp": "'$(json_timestamp)'",'
    echo '        "test_type": "lightweight"'
    echo '    },'
    
    # Quick CPU test
    local cpu_start=$(date +%s%N)
    for i in {1..1000}; do :; done
    local cpu_end=$(date +%s%N)
    local cpu_time=$(( (cpu_end - cpu_start) / 1000000 ))
    
    echo '    "results": {'
    echo '        "cpu_test_ms": '$cpu_time','
    echo '        "overall_rating": "'$([ $cpu_time -lt 10 ] && echo 'excellent' || echo 'good')'"'
    echo '    },'
    echo '    "system_health": '$(calculate_system_health_score)
    echo "}"
}

# Command exists check
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main JSON API dispatcher
main() {
    case "${1:-}" in
        --status)
            api_json_status
            ;;
        --desktops)
            api_json_desktops_array
            ;;
        --benchmark)
            json_performance_benchmark
            ;;
        --help)
            echo "JSON API Module v$JSON_API_VERSION"
            echo ""
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --status      System status JSON"
            echo "  --desktops    Desktop environments JSON"
            echo "  --benchmark   Quick performance test JSON"
            echo "  --help        Show this help"
            ;;
        *)
            echo '{"error": "Unknown option. Use --help for usage."}'
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi