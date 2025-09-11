#!/bin/bash

# TTY3 JavaScript Session Manager Setup Script
# Enhanced version for Node.js powered session manager
# Usage: bash ~/.dotfiles/scripts/system/setup-tty3-js-session-manager.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Setup TTY3 for JavaScript session manager
setup_tty3_js_session_manager() {
    script_header "TTY3 JavaScript Session Manager Setup" "Configure TTY3 for automatic Node.js session manager launch"
    
    # Check Node.js availability
    if ! command_exists node; then
        error "Node.js is required but not installed!"
        echo "Install Node.js first: yay -S nodejs npm"
        return 1
    fi
    
    local node_version=$(node --version)
    success "Node.js detected: $node_version"
    
    log "Setting up TTY3 JavaScript session manager configuration..."
    
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
# TTY3 JavaScript Session Manager Auto-Start Override
ExecStart=
ExecStart=-/sbin/agetty -a alpha --noclear %I \$TERM
Type=idle
StandardInput=tty
StandardOutput=tty
EOF
    
    # Update .bashrc for JavaScript session manager
    log "Configuring .bashrc for JavaScript session manager..."
    
    # Remove old session manager config if exists
    if grep -q 'XDG_VTNR.*=.*"3".*exec session-manager' "$HOME/.bashrc"; then
        log "Removing old session manager configuration..."
        sed -i '/XDG_VTNR.*=.*"3"/,/^fi$/d' "$HOME/.bashrc"
    fi
    
    # Add JavaScript session manager configuration
    if ! grep -q 'TTY3_JS_SESSION_MANAGER' "$HOME/.bashrc"; then
        log "Adding JavaScript session manager to .bashrc..."
        cat >> "$HOME/.bashrc" << 'EOF'

# TTY3 JavaScript Session Manager - Auto-launch
if [ "$XDG_VTNR" = "3" ] && [ -z "$TTY3_JS_SESSION_MANAGER" ]; then
    export TTY3_JS_SESSION_MANAGER=1
    export NODE_ENV=production
    
    # Welcome message
    echo "🚀 Starting JavaScript Session Manager..."
    echo "Node.js $(node --version) | $(date)"
    echo ""
    
    # Launch JavaScript session manager
    cd "$HOME/.dotfiles"
    exec node scripts/session-manager.js
fi
EOF
        success "JavaScript session manager added to .bashrc"
    else
        success ".bashrc already configured for JavaScript session manager"
    fi
    
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
    
    success "TTY3 JavaScript session manager setup completed!"
    echo ""
    echo "📋 Usage:"
    echo "  • Press Ctrl+Alt+F3 to switch to TTY3"
    echo "  • JavaScript session manager will auto-start"
    echo "  • Full Node.js powered interface with Telegram integration"
    echo "  • Use 'q' to exit to bash, '0' to logout completely"
    echo ""
    echo "🔧 Available features on TTY3:"
    echo "  • Desktop environment launcher"
    echo "  • CLI tools integration"
    echo "  • Live system monitoring"
    echo "  • Telegram notifications"
    echo "  • Performance benchmarking"
    echo ""
    echo "🚀 Performance:"
    echo "  • Node.js $(node --version)"
    echo "  • Fast startup with async operations"
    echo "  • Real-time system monitoring"
    
    return 0
}

# Test TTY3 JavaScript configuration
test_tty3_js_config() {
    log "Testing TTY3 JavaScript configuration..."
    
    # Check Node.js
    if command_exists node; then
        success "✅ Node.js available: $(node --version)"
    else
        error "❌ Node.js not found"
        return 1
    fi
    
    # Check JavaScript session manager
    if [ -f "$HOME/.dotfiles/scripts/session-manager.js" ]; then
        success "✅ JavaScript session manager exists"
        
        # Test if it's executable
        if node "$HOME/.dotfiles/scripts/session-manager.js" --help >/dev/null 2>&1; then
            success "✅ JavaScript session manager is functional"
        else
            error "❌ JavaScript session manager has errors"
            return 1
        fi
    else
        error "❌ JavaScript session manager not found"
        return 1
    fi
    
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
    if grep -q 'TTY3_JS_SESSION_MANAGER' "$HOME/.bashrc"; then
        success "✅ .bashrc configured for JavaScript session manager"
    else
        error "❌ .bashrc not configured for JavaScript session manager"
        return 1
    fi
    
    success "TTY3 JavaScript configuration test completed successfully!"
    return 0
}

# Switch from old to JavaScript session manager
migrate_to_js_session_manager() {
    log "Migrating from old session manager to JavaScript version..."
    
    # Remove old configuration
    if grep -q 'XDG_VTNR.*=.*"3".*SESSION_MANAGER_ACTIVE' "$HOME/.bashrc"; then
        log "Removing old session manager configuration..."
        sed -i '/SESSION_MANAGER_ACTIVE=1/d' "$HOME/.bashrc"
        sed -i '/exec session-manager/d' "$HOME/.bashrc"
        success "Old configuration removed"
    fi
    
    # Setup new JavaScript configuration
    setup_tty3_js_session_manager
}

# Interactive menu
interactive_menu() {
    echo "TTY3 JavaScript Session Manager Setup:"
    echo "════════════════════════════════════════"
    echo "  [1] Setup TTY3 JavaScript session manager"
    echo "  [2] Test JavaScript configuration"
    echo "  [3] Migrate from old session manager"
    echo "  [4] Show TTY3 status and logs"
    echo "  [5] Remove TTY3 configuration"
    echo "  [0] Exit"
    echo ""
    
    read -p "Choose option: " choice
    
    case "$choice" in
        1)
            setup_tty3_js_session_manager
            ;;
        2)
            test_tty3_js_config
            ;;
        3)
            migrate_to_js_session_manager
            ;;
        4)
            log "TTY3 Service Status:"
            systemctl status getty@tty3 --no-pager
            echo ""
            log "Recent TTY3 logs:"
            journalctl -u getty@tty3 --no-pager -n 10
            ;;
        5)
            log "Removing TTY3 configuration..."
            sudo rm -f /etc/systemd/system/getty@tty3.service.d/override.conf
            sudo systemctl daemon-reload
            sudo systemctl restart getty@tty3
            success "TTY3 configuration removed"
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
    
    script_footer "TTY3 JavaScript Session Manager Setup"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi