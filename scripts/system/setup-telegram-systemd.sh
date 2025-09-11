#!/bin/bash

# Telegram Systemd Service Setup
# Creates a proper systemd service for telegram monitoring
# Usage: bash ~/.dotfiles/scripts/system/setup-telegram-systemd.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

SERVICE_NAME="telegram-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
USER_SERVICE_DIR="$HOME/.config/systemd/user"
USER_SERVICE_FILE="$USER_SERVICE_DIR/${SERVICE_NAME}.service"

# Create systemd service for telegram monitoring
create_telegram_systemd_service() {
    script_header "Telegram Systemd Service Setup" "Create system service for telegram monitoring"
    
    # Check if telegram is configured
    if [[ ! -f "$HOME/.config/telegram.env" ]]; then
        warning "Telegram not configured yet"
        echo "Run this first: bash ~/.dotfiles/scripts/utils/telegram/tele.sh --setup"
        echo ""
        read -p "Do you want to configure telegram now? [y/N]: " configure_now
        if [[ "$configure_now" =~ ^[Yy]$ ]]; then
            bash "$HOME/.dotfiles/scripts/utils/telegram/tele.sh" --setup
        else
            error "Telegram configuration required for service setup"
            return 1
        fi
    fi
    
    log "Creating telegram monitoring systemd service..."
    
    # Create user systemd directory
    mkdir -p "$USER_SERVICE_DIR"
    
    # Create user service file (preferred method)
    cat > "$USER_SERVICE_FILE" << EOF
[Unit]
Description=Telegram Monitoring Service
Documentation=https://github.com/nimmsel23/dotfiles
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/bash $HOME/.dotfiles/scripts/utils/telegram/telegram-monitor-daemon.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=telegram-monitor

# Environment
Environment=HOME=$HOME
Environment=USER=$USER
Environment=DOTFILES_DIR=$HOME/.dotfiles

# Security (user service)
NoNewPrivileges=yes
PrivateTmp=yes
ProtectHome=read-only
ProtectSystem=strict
ReadWritePaths=$HOME/.config $HOME/.cache

[Install]
WantedBy=default.target
EOF
    
    success "User systemd service created: $USER_SERVICE_FILE"
    
    # Create the actual monitoring daemon script
    create_telegram_daemon
    
    # Reload systemd user daemon
    log "Reloading systemd user daemon..."
    systemctl --user daemon-reload
    
    success "Telegram systemd service setup completed!"
    echo ""
    echo "📋 Usage:"
    echo "  • Start:   systemctl --user start $SERVICE_NAME"
    echo "  • Stop:    systemctl --user stop $SERVICE_NAME"
    echo "  • Enable:  systemctl --user enable $SERVICE_NAME  (auto-start)"
    echo "  • Status:  systemctl --user status $SERVICE_NAME"
    echo "  • Logs:    journalctl --user -u $SERVICE_NAME -f"
    echo ""
    echo "🔧 Configuration:"
    echo "  • Edit telegram settings: tele-service config"
    echo "  • Service file: $USER_SERVICE_FILE"
    echo "  • Daemon script: $HOME/.dotfiles/scripts/utils/telegram/telegram-monitor-daemon.sh"
    
    return 0
}

# Create telegram monitoring daemon script
create_telegram_daemon() {
    local daemon_script="$HOME/.dotfiles/scripts/utils/telegram/telegram-monitor-daemon.sh"
    
    log "Creating telegram monitoring daemon script..."
    
    cat > "$daemon_script" << 'EOF'
#!/bin/bash

# Telegram Monitoring Daemon
# Runs as systemd service to monitor system events

set -euo pipefail

# Configuration
DOTFILES_DIR="${HOME}/.dotfiles"
SERVICE_CONFIG="${HOME}/.config/telegram-service.conf"
LOG_FILE="${HOME}/.cache/telegram/monitor.log"
PID_FILE="${HOME}/.cache/telegram/monitor.pid"

# Create cache directory
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PID_FILE")"

# Write PID
echo $$ > "$PID_FILE"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Cleanup function
cleanup() {
    log_message "Telegram monitoring daemon shutting down"
    rm -f "$PID_FILE"
    exit 0
}

# Handle signals
trap cleanup SIGTERM SIGINT

log_message "Telegram monitoring daemon started (PID: $$)"

# Load telegram configuration
if [[ -f "${HOME}/.config/telegram.env" ]]; then
    source "${HOME}/.config/telegram.env"
else
    log_message "ERROR: Telegram not configured"
    exit 1
fi

# Load service configuration with defaults
ENABLE_SYSTEM_EVENTS="n"
ENABLE_PERFORMANCE_MONITORING="n"
ENABLE_SESSION_NOTIFICATIONS="n"
ENABLE_DAILY_REPORTS="n"
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
MONITOR_INTERVAL=300

if [[ -f "$SERVICE_CONFIG" ]]; then
    source "$SERVICE_CONFIG"
fi

# Send startup notification
bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "🤖 Telegram monitoring service started on $(hostname) via systemd" 2>/dev/null || true

# Initialize tracking variables
last_session="${XDG_CURRENT_DESKTOP:-unknown}"
echo "$last_session" > /tmp/telegram_last_session
last_notification_time=0

# Main monitoring loop
while true; do
    current_time=$(date +%s)
    
    # Performance monitoring
    if [[ "$ENABLE_PERFORMANCE_MONITORING" == "y" ]]; then
        # Memory check
        mem_usage=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100.0}')
        if (( mem_usage > MEMORY_THRESHOLD )) && (( current_time - last_notification_time > 1800 )); then
            bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "⚠️ High memory usage: ${mem_usage}% on $(hostname)" 2>/dev/null || true
            last_notification_time=$current_time
            log_message "High memory alert sent: ${mem_usage}%"
        fi
        
        # Disk check
        disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        if (( disk_usage > DISK_THRESHOLD )) && (( current_time - last_notification_time > 3600 )); then
            bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "⚠️ High disk usage: ${disk_usage}% on $(hostname)" 2>/dev/null || true
            last_notification_time=$current_time
            log_message "High disk usage alert sent: ${disk_usage}%"
        fi
    fi
    
    # Session monitoring
    if [[ "$ENABLE_SESSION_NOTIFICATIONS" == "y" ]]; then
        current_session="${XDG_CURRENT_DESKTOP:-unknown}"
        if [[ -f "/tmp/telegram_last_session" ]]; then
            last_session=$(cat /tmp/telegram_last_session)
            if [[ "$current_session" != "$last_session" ]]; then
                bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "🔄 Session changed: $last_session → $current_session on $(hostname)" 2>/dev/null || true
                log_message "Session change notification sent: $last_session → $current_session"
            fi
        fi
        echo "$current_session" > /tmp/telegram_last_session
    fi
    
    # System events monitoring
    if [[ "$ENABLE_SYSTEM_EVENTS" == "y" ]]; then
        # Check for system events (simplified)
        uptime_minutes=$(awk '{print int($1/60)}' /proc/uptime)
        if (( uptime_minutes < 5 )) && (( current_time - last_notification_time > 300 )); then
            bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" "🚀 System $(hostname) recently started (uptime: ${uptime_minutes}m)" 2>/dev/null || true
            last_notification_time=$current_time
            log_message "System startup notification sent"
        fi
    fi
    
    # Daily reports
    if [[ "$ENABLE_DAILY_REPORTS" == "y" ]]; then
        current_hour=$(date +%H)
        current_minute=$(date +%M)
        report_hour="${REPORT_TIME%:*}"
        report_minute="${REPORT_TIME#*:}"
        
        if [[ "$current_hour" == "$report_hour" ]] && [[ "$current_minute" == "$report_minute" ]]; then
            if ! [[ -f "/tmp/telegram_daily_report_$(date +%Y%m%d)" ]]; then
                bash "${DOTFILES_DIR}/scripts/utils/telegram/tele.sh" --status 2>/dev/null || true
                touch "/tmp/telegram_daily_report_$(date +%Y%m%d)"
                log_message "Daily report sent"
            fi
        fi
    fi
    
    # Sleep until next check
    sleep "$MONITOR_INTERVAL"
done
EOF
    
    chmod +x "$daemon_script"
    success "Telegram monitoring daemon created: $daemon_script"
}

# Enable and start telegram service
enable_telegram_service() {
    log "Enabling telegram monitoring service..."
    
    if systemctl --user enable "$SERVICE_NAME"; then
        success "Service enabled for auto-start"
    else
        error "Failed to enable service"
        return 1
    fi
    
    if systemctl --user start "$SERVICE_NAME"; then
        success "Service started successfully"
    else
        error "Failed to start service"
        return 1
    fi
    
    # Show status
    systemctl --user status "$SERVICE_NAME" --no-pager
}

# Remove telegram service
remove_telegram_service() {
    log "Removing telegram monitoring service..."
    
    # Stop service if running
    systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
    
    # Disable service
    systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
    
    # Remove service files
    rm -f "$USER_SERVICE_FILE"
    rm -f "$HOME/.dotfiles/scripts/utils/telegram/telegram-monitor-daemon.sh"
    
    # Reload daemon
    systemctl --user daemon-reload
    
    success "Telegram service removed"
}

# Show service status and logs
show_service_status() {
    log "Telegram monitoring service status:"
    echo ""
    
    if systemctl --user is-active "$SERVICE_NAME" >/dev/null 2>&1; then
        success "Service is running"
        systemctl --user status "$SERVICE_NAME" --no-pager
    else
        warning "Service is not running"
    fi
    
    echo ""
    log "Recent logs:"
    journalctl --user -u "$SERVICE_NAME" --no-pager -n 10 2>/dev/null || echo "No logs available"
    
    echo ""
    log "Configuration:"
    if [[ -f "$HOME/.config/telegram-service.conf" ]]; then
        cat "$HOME/.config/telegram-service.conf"
    else
        echo "No service configuration found"
    fi
}

# Interactive menu
interactive_menu() {
    echo "Telegram Systemd Service Manager:"
    echo "═══════════════════════════════════"
    echo "  [1] Create telegram systemd service"
    echo "  [2] Enable and start service"
    echo "  [3] Configure service settings"
    echo "  [4] Show service status and logs"
    echo "  [5] Remove service"
    echo "  [0] Exit"
    echo ""
    
    read -p "Choose option: " choice
    
    case "$choice" in
        1)
            create_telegram_systemd_service
            ;;
        2)
            enable_telegram_service
            ;;
        3)
            bash "$HOME/.dotfiles/scripts/utils/telegram/tele-service.sh" config
            ;;
        4)
            show_service_status
            ;;
        5)
            remove_telegram_service
            ;;
        0)
            log "Exiting..."
            return 0
            ;;
        *)
            error "Invalid choice"
            return 1
            ;;
    esac
}

# Main function
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    interactive_menu
    
    script_footer "Telegram Systemd Service Setup"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi