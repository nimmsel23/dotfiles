#!/bin/bash

# Systemd Timer Manager
# Part of nimmsel23's dotfiles system scripts
# Modern replacement for cron using systemd timers
# Usage: bash ~/.dotfiles/scripts/system/systemd-timer-manager.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Configuration
TIMER_DIR="$HOME/.config/systemd/user"
LOG_DIR="$HOME/.dotfiles/logs"

# Ensure directories exist
setup_directories() {
    mkdir -p "$TIMER_DIR" "$LOG_DIR"
}

# Create desktop sync timer
create_desktop_sync_timer() {
    local service_name="dotfiles-desktop-sync"
    
    log "Creating desktop sync systemd timer..."
    
    # Create service file
    cat > "$TIMER_DIR/${service_name}.service" << EOF
[Unit]
Description=Dotfiles Desktop Sync with Rclone
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
Environment=HOME=$HOME
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin
ExecStart=$HOME/.dotfiles/scripts/utils/rclone-desktop-sync.sh sync
StandardOutput=append:$LOG_DIR/desktop-sync.log
StandardError=append:$LOG_DIR/desktop-sync.log

[Install]
WantedBy=default.target
EOF

    # Create timer file
    cat > "$TIMER_DIR/${service_name}.timer" << EOF
[Unit]
Description=Run desktop sync daily
Requires=${service_name}.service

[Timer]
OnCalendar=daily
AccuracySec=1h
Persistent=true
RandomizedDelaySec=30m

[Install]
WantedBy=timers.target
EOF

    success "Desktop sync timer created"
}

# Create dotfiles auto-push timer
create_dotfiles_push_timer() {
    local service_name="dotfiles-auto-push"
    
    log "Creating dotfiles auto-push systemd timer..."
    
    # Create service file
    cat > "$TIMER_DIR/${service_name}.service" << EOF
[Unit]
Description=Auto-push dotfiles changes to GitHub
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$HOME/.dotfiles
Environment=HOME=$HOME
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin
ExecStart=/bin/bash -c 'git add . && git diff --cached --quiet || (git commit -m "Auto-update \$(date +%%Y-%%m-%%d)" && git push origin main)'
StandardOutput=append:$LOG_DIR/dotfiles-push.log
StandardError=append:$LOG_DIR/dotfiles-push.log

[Install]
WantedBy=default.target
EOF

    # Create timer file
    cat > "$TIMER_DIR/${service_name}.timer" << EOF
[Unit]
Description=Auto-push dotfiles changes daily
Requires=${service_name}.service

[Timer]
OnCalendar=23:00
AccuracySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

    success "Dotfiles auto-push timer created"
}

# Create system cleanup timer
create_system_cleanup_timer() {
    local service_name="dotfiles-system-cleanup"
    
    log "Creating system cleanup systemd timer..."
    
    # Create service file
    cat > "$TIMER_DIR/${service_name}.service" << EOF
[Unit]
Description=Clean system package cache
After=network.target

[Service]
Type=oneshot
User=$USER
Environment=HOME=$HOME
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin
ExecStart=/usr/bin/yay -Sc --noconfirm
StandardOutput=append:$LOG_DIR/system-cleanup.log
StandardError=append:$LOG_DIR/system-cleanup.log

[Install]
WantedBy=default.target
EOF

    # Create timer file
    cat > "$TIMER_DIR/${service_name}.timer" << EOF
[Unit]
Description=Clean system weekly
Requires=${service_name}.service

[Timer]
OnCalendar=Sun 03:00
AccuracySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

    success "System cleanup timer created"
}

# Create study reminder timer
create_study_reminder_timer() {
    local service_name="dotfiles-study-reminder"
    
    log "Creating study reminder systemd timer..."
    
    # Check if telegram is available
    if [ ! -f "$HOME/.dotfiles/scripts/utils/telegram/tele.sh" ]; then
        warning "Telegram not found. Creating timer template that can be enabled later."
    fi
    
    # Create service file
    cat > "$TIMER_DIR/${service_name}.service" << EOF
[Unit]
Description=Study reminder via Telegram
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
Environment=HOME=$HOME
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin
ExecStart=$HOME/.dotfiles/scripts/utils/telegram/tele.sh "Time for your Vitaltrainer studies! 📚"
StandardOutput=append:$LOG_DIR/study-reminder.log
StandardError=append:$LOG_DIR/study-reminder.log

[Install]
WantedBy=default.target
EOF

    # Create timer file
    cat > "$TIMER_DIR/${service_name}.timer" << EOF
[Unit]
Description=Daily study reminder (weekdays)
Requires=${service_name}.service

[Timer]
OnCalendar=Mon..Fri 09:00
AccuracySec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF

    success "Study reminder timer created"
}

# Enable and start a timer
enable_timer() {
    local timer_name="$1"
    
    log "Enabling timer: $timer_name"
    
    if ! systemctl --user daemon-reload; then
        error "Failed to reload systemd user daemon"
        return 1
    fi
    
    if ! systemctl --user enable "$timer_name.timer"; then
        error "Failed to enable timer: $timer_name"
        return 1
    fi
    
    if ! systemctl --user start "$timer_name.timer"; then
        error "Failed to start timer: $timer_name"
        return 1
    fi
    
    success "Timer enabled and started: $timer_name"
    return 0
}

# Disable and stop a timer
disable_timer() {
    local timer_name="$1"
    
    log "Disabling timer: $timer_name"
    
    systemctl --user stop "$timer_name.timer" 2>/dev/null || true
    systemctl --user disable "$timer_name.timer" 2>/dev/null || true
    
    success "Timer disabled: $timer_name"
}

# Show timer status
show_timer_status() {
    echo "Systemd User Timers Status:"
    echo "═══════════════════════════════"
    echo ""
    
    # Check if user linger is enabled
    if loginctl show-user "$USER" --property=Linger | grep -q "Linger=yes"; then
        success "User linger enabled (timers run without login)"
    else
        warning "User linger not enabled"
        echo "Enable with: sudo loginctl enable-linger $USER"
        echo ""
    fi
    
    # List dotfiles timers
    local dotfiles_timers=(
        "dotfiles-desktop-sync"
        "dotfiles-auto-push"
        "dotfiles-system-cleanup"
        "dotfiles-study-reminder"
    )
    
    echo "Dotfiles Timers:"
    echo "─────────────────"
    
    for timer in "${dotfiles_timers[@]}"; do
        if [ -f "$TIMER_DIR/${timer}.timer" ]; then
            local status="inactive"
            local next_run="unknown"
            
            if systemctl --user is-active "${timer}.timer" >/dev/null 2>&1; then
                status="active"
                next_run=$(systemctl --user list-timers "${timer}.timer" --no-pager | awk 'NR==2 {print $1, $2}' 2>/dev/null || echo "unknown")
            fi
            
            if [ "$status" = "active" ]; then
                echo "  ✅ $timer ($status) - Next: $next_run"
            else
                echo "  ⏸️  $timer ($status)"
            fi
        else
            echo "  ❌ $timer (not created)"
        fi
    done
    
    echo ""
    
    # Show recent timer activity
    echo "Recent Timer Activity:"
    echo "─────────────────────────"
    
    if systemctl --user list-timers --all | grep -q dotfiles; then
        systemctl --user list-timers --all | grep dotfiles | head -5
    else
        echo "No active dotfiles timers found"
    fi
    
    echo ""
    
    # Show logs if available
    echo "Recent Logs:"
    echo "─────────────"
    
    for log_file in "$LOG_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            local log_name=$(basename "$log_file")
            echo "📋 $log_name (last 2 lines):"
            tail -2 "$log_file" 2>/dev/null | sed 's/^/    /' || echo "    No recent activity"
        fi
    done
}

# Interactive timer management
manage_timers() {
    echo "Systemd Timer Management:"
    echo "═══════════════════════════"
    echo ""
    echo "Available timers:"
    echo "  1. Desktop Sync (daily rclone backup)"
    echo "  2. Dotfiles Push (daily git push)"
    echo "  3. System Cleanup (weekly package cache cleaning)"
    echo "  4. Study Reminder (weekday study notifications)"
    echo ""
    echo "Actions:"
    echo "  [c] Create all timers"
    echo "  [e] Enable specific timer"
    echo "  [d] Disable specific timer"
    echo "  [s] Show timer status"
    echo "  [l] Show logs"
    echo "  [r] Remove all timers"
    echo "  [0] Back to main menu"
    echo ""
    
    read -p "Choose action: " action
    
    case "$action" in
        c)
            create_all_timers
            ;;
        e)
            enable_specific_timer
            ;;
        d)
            disable_specific_timer
            ;;
        s)
            show_timer_status
            ;;
        l)
            show_timer_logs
            ;;
        r)
            remove_all_timers
            ;;
        0)
            return 0
            ;;
        *)
            error "Invalid action: $action"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    manage_timers
}

# Create all timers
create_all_timers() {
    log "Creating all dotfiles systemd timers..."
    
    setup_directories
    
    create_desktop_sync_timer
    create_dotfiles_push_timer
    create_system_cleanup_timer
    create_study_reminder_timer
    
    # Reload systemd
    systemctl --user daemon-reload
    
    success "All timers created"
    
    # Ask about enabling user linger
    if ! loginctl show-user "$USER" --property=Linger | grep -q "Linger=yes"; then
        echo ""
        warning "User linger is not enabled"
        echo "This means timers only run when you're logged in."
        read -p "Enable user linger for persistent timers? [y/N] " enable_linger
        
        if [[ $enable_linger =~ ^[Yy]$ ]]; then
            if sudo loginctl enable-linger "$USER"; then
                success "User linger enabled - timers will run even when logged out"
            else
                error "Failed to enable user linger"
            fi
        fi
    fi
    
    # Ask about enabling timers
    echo ""
    read -p "Enable and start all timers now? [Y/n] " enable_all
    if [[ ! $enable_all =~ ^[Nn]$ ]]; then
        enable_timer "dotfiles-desktop-sync"
        enable_timer "dotfiles-auto-push"
        enable_timer "dotfiles-system-cleanup"
        
        # Only enable study reminder if telegram is configured
        if [ -f "$HOME/.dotfiles/config/telegram/tele.env" ]; then
            enable_timer "dotfiles-study-reminder"
        else
            log "Skipping study reminder (telegram not configured)"
        fi
        
        success "Timers enabled and started"
    fi
}

# Enable specific timer
enable_specific_timer() {
    echo "Available timers to enable:"
    echo "  1. Desktop Sync"
    echo "  2. Dotfiles Push" 
    echo "  3. System Cleanup"
    echo "  4. Study Reminder"
    echo ""
    
    read -p "Choose timer to enable [1-4]: " timer_choice
    
    case "$timer_choice" in
        1) enable_timer "dotfiles-desktop-sync" ;;
        2) enable_timer "dotfiles-auto-push" ;;
        3) enable_timer "dotfiles-system-cleanup" ;;
        4) enable_timer "dotfiles-study-reminder" ;;
        *) error "Invalid choice: $timer_choice" ;;
    esac
}

# Disable specific timer
disable_specific_timer() {
    echo "Active timers to disable:"
    systemctl --user list-timers | grep dotfiles | awk '{print "  " NR ". " $NF}'
    echo ""
    
    read -p "Enter timer name to disable: " timer_name
    if [ -n "$timer_name" ]; then
        disable_timer "$timer_name"
    fi
}

# Show timer logs
show_timer_logs() {
    echo "Available log files:"
    echo ""
    
    local log_count=1
    for log_file in "$LOG_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            echo "  $log_count. $(basename "$log_file")"
            ((log_count++))
        fi
    done
    
    if [ $log_count -eq 1 ]; then
        warning "No log files found"
        return
    fi
    
    echo ""
    read -p "Enter log file name to view (or 'all'): " log_choice
    
    if [ "$log_choice" = "all" ]; then
        for log_file in "$LOG_DIR"/*.log; do
            if [ -f "$log_file" ]; then
                echo "═══ $(basename "$log_file") ═══"
                tail -10 "$log_file"
                echo ""
            fi
        done
    elif [ -f "$LOG_DIR/$log_choice" ]; then
        echo "═══ $log_choice ═══"
        tail -20 "$LOG_DIR/$log_choice"
    else
        error "Log file not found: $log_choice"
    fi
}

# Remove all timers
remove_all_timers() {
    echo "⚠️  This will remove all dotfiles systemd timers"
    read -p "Are you sure? Type 'YES' to confirm: " confirm
    
    if [ "$confirm" != "YES" ]; then
        warning "Removal cancelled"
        return
    fi
    
    local timers=(
        "dotfiles-desktop-sync"
        "dotfiles-auto-push"
        "dotfiles-system-cleanup"
        "dotfiles-study-reminder"
    )
    
    for timer in "${timers[@]}"; do
        disable_timer "$timer"
        rm -f "$TIMER_DIR/${timer}.service" "$TIMER_DIR/${timer}.timer"
    done
    
    systemctl --user daemon-reload
    success "All timers removed"
}

# Test a timer
test_timer() {
    echo "Timer Test Options:"
    echo "  1. Test desktop sync service"
    echo "  2. Test dotfiles push service" 
    echo "  3. Test system cleanup service"
    echo "  4. Test study reminder service"
    echo ""
    
    read -p "Choose service to test [1-4]: " test_choice
    
    local service_name=""
    case "$test_choice" in
        1) service_name="dotfiles-desktop-sync" ;;
        2) service_name="dotfiles-auto-push" ;;
        3) service_name="dotfiles-system-cleanup" ;;
        4) service_name="dotfiles-study-reminder" ;;
        *) error "Invalid choice"; return 1 ;;
    esac
    
    log "Testing service: $service_name"
    
    if systemctl --user start "${service_name}.service"; then
        success "Service test completed"
        echo "Check logs: tail -f $LOG_DIR/${service_name#dotfiles-}.log"
    else
        error "Service test failed"
        echo "Check status: systemctl --user status ${service_name}.service"
    fi
}

# Main function
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    case "${1:-menu}" in
        create)
            create_all_timers
            ;;
        enable)
            enable_specific_timer
            ;;
        disable)
            disable_specific_timer
            ;;
        status)
            show_timer_status
            ;;
        test)
            test_timer
            ;;
        remove)
            remove_all_timers
            ;;
        menu|*)
            script_header "Systemd Timer Manager" "Modern scheduled tasks using systemd user timers"
            
            show_timer_status
            echo ""
            
            echo "Quick Actions:"
            echo "  create  - Create all dotfiles timers"
            echo "  enable  - Enable specific timer"
            echo "  disable - Disable specific timer"
            echo "  status  - Show timer status"
            echo "  test    - Test a timer service"
            echo "  remove  - Remove all timers"
            echo "  menu    - Interactive management"
            echo ""
            
            read -p "Choose action (or Enter for interactive menu): " quick_action
            
            if [ -n "$quick_action" ]; then
                main "$quick_action"
            else
                manage_timers
            fi
            ;;
    esac
    
    if [ "$1" != "menu" ] && [ "$1" != "status" ]; then
        script_footer "Systemd timer management completed"
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi