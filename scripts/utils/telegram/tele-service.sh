#!/usr/bin/env bash

# 🤖 Telegram Service Controller
# Manage telegram notifications and monitoring
# Part of nimmsel23's dotfiles system

set -euo pipefail

DOTFILES_DIR="${HOME}/.dotfiles"
SERVICE_CONFIG="${HOME}/.config/telegram-service.conf"
PID_FILE="/tmp/telegram-service.pid"

# Source common functions
if [ -f "${DOTFILES_DIR}/scripts/utils/common.sh" ]; then
    source "${DOTFILES_DIR}/scripts/utils/common.sh"
else
    log() { echo -e "\033[0;34m[$(date +'%H:%M:%S')]\033[0m $1"; }
    success() { echo -e "\033[0;32m✅ $1\033[0m"; }
    error() { echo -e "\033[0;31m❌ $1\033[0m"; }
fi

# Check if telegram is configured
check_telegram_config() {
    if [[ ! -f "${HOME}/.config/telegram.env" ]]; then
        error "Telegram not configured. Run: tele --setup"
        return 1
    fi
    return 0
}

# Show service status
show_status() {
    log "📱 Telegram Service Status"
    echo ""
    
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        local pid=$(cat "$PID_FILE")
        success "Service is running (PID: $pid)"
        
        # Show process info
        echo "Process info:"
        ps -p "$pid" -o pid,ppid,cmd,etime 2>/dev/null || true
    else
        warning "Service is not running"
    fi
    
    echo ""
    
    # Show configuration
    if [[ -f "$SERVICE_CONFIG" ]]; then
        log "Current configuration:"
        cat "$SERVICE_CONFIG"
    else
        warning "No service configuration found"
    fi
    
    # Show recent activity
    echo ""
    log "Recent telegram activity:"
    if [[ -f "${HOME}/.cache/telegram/sent_messages.log" ]]; then
        tail -n 5 "${HOME}/.cache/telegram/sent_messages.log" || echo "No messages found"
    else
        echo "No message log found"
    fi
}

# Configure service
configure_service() {
    log "🔧 Configuring Telegram Service"
    echo ""
    
    echo "Available notification types:"
    echo "1. System events (login, logout, reboot)"
    echo "2. Performance monitoring (high CPU, memory)"
    echo "3. Session changes (desktop switching)"
    echo "4. Scheduled reports (daily, weekly)"
    echo ""
    
    read -p "Enable system events? [y/N]: " enable_system
    read -p "Enable performance monitoring? [y/N]: " enable_perf
    read -p "Enable session notifications? [y/N]: " enable_session
    read -p "Enable daily reports? [y/N]: " enable_reports
    
    # Create service configuration
    cat > "$SERVICE_CONFIG" << EOF
# Telegram Service Configuration
ENABLE_SYSTEM_EVENTS=${enable_system:-n}
ENABLE_PERFORMANCE_MONITORING=${enable_perf:-n}
ENABLE_SESSION_NOTIFICATIONS=${enable_session:-n}
ENABLE_DAILY_REPORTS=${enable_reports:-n}

# Performance thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90

# Check intervals (seconds)
MONITOR_INTERVAL=300
REPORT_TIME="09:00"
EOF

    chmod 600 "$SERVICE_CONFIG"
    success "Service configuration saved"
}

# Start monitoring service
start_service() {
    if ! check_telegram_config; then
        return 1
    fi
    
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        warning "Service is already running"
        return 0
    fi
    
    log "🚀 Starting Telegram monitoring service..."
    
    # Start background monitoring
    nohup bash -c '
        DOTFILES_DIR="${HOME}/.dotfiles"
        SERVICE_CONFIG="${HOME}/.config/telegram-service.conf"
        
        # Load configuration
        if [[ -f "$SERVICE_CONFIG" ]]; then
            source "$SERVICE_CONFIG"
        fi
        
        # Load telegram config
        source "${HOME}/.config/telegram.env"
        
        while true; do
            # Performance monitoring
            if [[ "${ENABLE_PERFORMANCE_MONITORING:-n}" == "y" ]]; then
                cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | sed "s/%us,//")
                mem_usage=$(free | awk "/^Mem:/ {printf \"%.0f\", \$3/\$2 * 100.0}")
                
                if (( $(echo "$mem_usage > ${MEMORY_THRESHOLD:-85}" | bc -l) )); then
                    bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "⚠️ High memory usage: ${mem_usage}% on $(hostname)"
                fi
            fi
            
            # Session monitoring
            if [[ "${ENABLE_SESSION_NOTIFICATIONS:-n}" == "y" ]]; then
                current_session="${XDG_CURRENT_DESKTOP:-unknown}"
                if [[ -f "/tmp/last_session" ]]; then
                    last_session=$(cat /tmp/last_session)
                    if [[ "$current_session" != "$last_session" ]]; then
                        bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "🔄 Session changed: $last_session → $current_session"
                    fi
                fi
                echo "$current_session" > /tmp/last_session
            fi
            
            sleep ${MONITOR_INTERVAL:-300}
        done
    ' > /tmp/telegram-service.log 2>&1 &
    
    echo $! > "$PID_FILE"
    success "Telegram service started (PID: $(cat "$PID_FILE"))"
    
    # Send startup notification
    bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "🤖 Telegram monitoring service started on $(hostname)"
}

# Stop service
stop_service() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        local pid=$(cat "$PID_FILE")
        log "🛑 Stopping Telegram service (PID: $pid)..."
        
        kill "$pid"
        rm -f "$PID_FILE"
        success "Service stopped"
        
        # Send shutdown notification if telegram is configured
        if [[ -f "${HOME}/.config/telegram.env" ]]; then
            bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "🛑 Telegram monitoring service stopped on $(hostname)" 2>/dev/null || true
        fi
    else
        warning "Service is not running"
    fi
}

# Send test notification
test_notifications() {
    if ! check_telegram_config; then
        return 1
    fi
    
    log "📬 Sending test notifications..."
    
    bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "🧪 Test notification from Telegram Service"
    bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" --status
    
    success "Test notifications sent!"
}

# Show help
show_help() {
    cat << EOF
🤖 Telegram Service Controller

Usage:
  tele-service start          Start monitoring service
  tele-service stop           Stop monitoring service
  tele-service status         Show service status
  tele-service config         Configure service settings
  tele-service test           Send test notifications
  tele-service restart        Restart service
  tele-service help           Show this help

The service monitors system events and sends notifications via Telegram.
Configure with 'tele-service config' before starting.
EOF
}

# Main function
main() {
    case "${1:-}" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        status)
            show_status
            ;;
        config)
            configure_service
            ;;
        test)
            test_notifications
            ;;
        restart)
            stop_service
            sleep 2
            start_service
            ;;
        help|--help)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            error "Unknown command: $1"
            echo "Use 'tele-service help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"