#!/bin/bash

# TTY3 Session Manager Setup Script
# Part of nimmsel23's dotfiles system scripts
# Configures TTY3 to properly auto-start session manager
# Usage: bash ~/.dotfiles/scripts/system/setup-tty3-session-manager.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Setup TTY3 for session manager
setup_tty3_session_manager() {
    script_header "TTY3 Session Manager Setup" "Configure TTY3 for automatic session manager launch"
    
    log "Setting up TTY3 session manager configuration..."
    
    # Check if TTY3 is available
    if ! systemctl is-enabled getty@tty3 >/dev/null 2>&1; then
        log "Enabling getty@tty3 service..."
        sudo systemctl enable getty@tty3
    fi
    
    # Create systemd override directory if it doesn't exist
    sudo mkdir -p /etc/systemd/system/getty@tty3.service.d/
    
    # Create systemd override for automatic login on TTY3
    log "Creating systemd override for TTY3 auto-login..."
    sudo tee /etc/systemd/system/getty@tty3.service.d/override.conf > /dev/null << EOF
[Service]
# TTY3 Session Manager Auto-Start Override
ExecStart=
ExecStart=-/sbin/agetty -a alpha --noclear %I \$TERM
Type=idle
EOF
    
    # Reload systemd configuration
    log "Reloading systemd configuration..."
    sudo systemctl daemon-reload
    
    # Restart getty@tty3 if it's running
    if systemctl is-active getty@tty3 >/dev/null 2>&1; then
        log "Restarting getty@tty3 service..."
        sudo systemctl restart getty@tty3
    else
        log "Starting getty@tty3 service..."
        sudo systemctl start getty@tty3
    fi
    
    # Verify bashrc configuration
    log "Verifying .bashrc configuration..."
    if grep -q 'XDG_VTNR.*=.*"3"' "$HOME/.bashrc"; then
        success "✅ .bashrc is configured for TTY3 session manager"
    else
        warning "⚠️ .bashrc may need manual configuration for TTY3"
        echo "Add this to ~/.bashrc:"
        echo 'if [ "$XDG_VTNR" = "3" ] && [ -z "$SESSION_MANAGER_ACTIVE" ]; then'
        echo '    export SESSION_MANAGER_ACTIVE=1'
        echo '    exec session-manager'
        echo 'fi'
    fi
    
    success "TTY3 session manager setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "  • Press Ctrl+Alt+F3 to switch to TTY3"
    echo "  • The session manager should auto-start"
    echo "  • Use 'q' in session manager to exit to bash"
    echo "  • Use '0' in session manager to logout"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  • Check TTY3 status: systemctl status getty@tty3"
    echo "  • Check logs: journalctl -u getty@tty3"
    echo "  • Test manually: sudo systemctl restart getty@tty3"
    
    return 0
}

# Test TTY3 configuration
test_tty3_config() {
    log "Testing TTY3 configuration..."
    
    # Check systemd service status
    if systemctl is-active getty@tty3 >/dev/null 2>&1; then
        success "✅ getty@tty3 service is running"
    else
        error "❌ getty@tty3 service is not running"
        return 1
    fi
    
    # Check override configuration
    if [ -f "/etc/systemd/system/getty@tty3.service.d/override.conf" ]; then
        success "✅ TTY3 override configuration exists"
        
        # Check for auto-login configuration
        if grep -q "\-a alpha" "/etc/systemd/system/getty@tty3.service.d/override.conf"; then
            success "✅ Auto-login configured for user 'alpha'"
        else
            warning "⚠️ Auto-login not configured"
        fi
    else
        error "❌ TTY3 override configuration missing"
        return 1
    fi
    
    # Check bashrc configuration
    if grep -q 'XDG_VTNR.*=.*"3"' "$HOME/.bashrc"; then
        success "✅ .bashrc configured for TTY3"
    else
        error "❌ .bashrc not configured for TTY3"
        return 1
    fi
    
    # Check session-manager script
    if [ -x "$HOME/.dotfiles/scripts/session-manager" ]; then
        success "✅ session-manager script is executable"
    else
        error "❌ session-manager script not found or not executable"
        return 1
    fi
    
    success "TTY3 configuration test completed successfully!"
    return 0
}

# Remove TTY3 session manager configuration
remove_tty3_config() {
    log "Removing TTY3 session manager configuration..."
    
    # Remove systemd override
    if [ -f "/etc/systemd/system/getty@tty3.service.d/override.conf" ]; then
        sudo rm -f /etc/systemd/system/getty@tty3.service.d/override.conf
        log "Removed TTY3 systemd override"
    fi
    
    # Remove directory if empty
    if [ -d "/etc/systemd/system/getty@tty3.service.d" ] && [ -z "$(ls -A /etc/systemd/system/getty@tty3.service.d)" ]; then
        sudo rmdir /etc/systemd/system/getty@tty3.service.d
        log "Removed empty TTY3 systemd override directory"
    fi
    
    # Reload systemd and restart service
    sudo systemctl daemon-reload
    sudo systemctl restart getty@tty3
    
    success "TTY3 session manager configuration removed"
    echo "Note: .bashrc configuration remains - remove manually if desired"
    
    return 0
}

# Interactive menu
interactive_menu() {
    echo "TTY3 Session Manager Setup Options:"
    echo "══════════════════════════════════════"
    echo "  [1] Setup TTY3 session manager"
    echo "  [2] Test current TTY3 configuration"
    echo "  [3] Remove TTY3 configuration"
    echo "  [4] Show TTY3 status"
    echo "  [0] Exit"
    echo ""
    
    read -p "Choose option: " choice
    
    case "$choice" in
        1)
            setup_tty3_session_manager
            ;;
        2)
            test_tty3_config
            ;;
        3)
            remove_tty3_config
            ;;
        4)
            log "TTY3 Service Status:"
            systemctl status getty@tty3 --no-pager
            echo ""
            log "TTY3 Override Configuration:"
            if [ -f "/etc/systemd/system/getty@tty3.service.d/override.conf" ]; then
                cat /etc/systemd/system/getty@tty3.service.d/override.conf
            else
                warning "No override configuration found"
            fi
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
    
    if ! check_requirements; then
        error "System requirements not met"
        exit 1
    fi
    
    interactive_menu
    
    script_footer "TTY3 Session Manager Setup"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi