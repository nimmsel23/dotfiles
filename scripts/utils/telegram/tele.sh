#!/usr/bin/env bash

# 📱 Modern Telegram CLI - Enhanced for dotfiles system
# Usage: tele "message" or tele --setup for configuration
# Part of nimmsel23's dotfiles system

set -euo pipefail

# Configuration paths
DOTFILES_DIR="${HOME}/.dotfiles"
TELE_CONFIG="${HOME}/.config/telegram.env"
TELE_CACHE="${HOME}/.cache/telegram"

# Source common functions if available
if [ -f "${DOTFILES_DIR}/scripts/utils/common.sh" ]; then
    source "${DOTFILES_DIR}/scripts/utils/common.sh"
else
    # Fallback functions
    log() { echo -e "\033[0;34m[$(date +'%H:%M:%S')]\033[0m $1"; }
    success() { echo -e "\033[0;32m✅ $1\033[0m"; }
    error() { echo -e "\033[0;31m❌ $1\033[0m"; }
    warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }
fi

# Initialize telegram configuration
init_telegram_config() {
    log "📱 Telegram Setup - Enhanced Edition"
    echo ""
    echo "🔧 To create a Telegram bot:"
    echo "1. Message @BotFather on Telegram"
    echo "2. Send: /newbot"
    echo "3. Follow instructions to get your BOT_TOKEN"
    echo "4. Get your CHAT_ID by messaging your bot, then visit:"
    echo "   https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates"
    echo ""
    
    read -rp "🤖 BOT_TOKEN: " BOT_TOKEN
    read -rp "💬 CHAT_ID: " CHAT_ID
    
    # Validate inputs
    if [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
        error "BOT_TOKEN and CHAT_ID are required!"
        return 1
    fi
    
    # Create config directory
    mkdir -p "$(dirname "$TELE_CONFIG")"
    mkdir -p "$TELE_CACHE"
    
    # Save configuration
    cat > "$TELE_CONFIG" << EOF
# Telegram Bot Configuration
BOT_TOKEN=$BOT_TOKEN
CHAT_ID=$CHAT_ID
EOF
    
    chmod 600 "$TELE_CONFIG"
    success "Telegram configuration saved to $TELE_CONFIG"
    
    # Test the configuration
    if test_telegram_connection; then
        success "✨ Telegram setup completed successfully!"
    else
        error "Setup failed. Please check your BOT_TOKEN and CHAT_ID."
        return 1
    fi
}

# Test telegram connection
test_telegram_connection() {
    local test_message="🚀 Telegram CLI test from $(hostname) at $(date +'%H:%M:%S')"
    
    local response=$(curl -sS -X POST \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${test_message}" \
        -d "parse_mode=Markdown")
    
    if echo "$response" | grep -q '"ok":true'; then
        success "Test message sent successfully!"
        return 0
    else
        error "Test message failed: $response"
        return 1
    fi
}

# Send telegram message
send_telegram_message() {
    local message="$1"
    local parse_mode="${2:-Markdown}"
    
    # Escape special characters for MarkdownV2 if needed
    if [[ "$parse_mode" == "MarkdownV2" ]]; then
        message=$(echo "$message" | sed 's/[_*\[\]()~`>#+=|{}.!-]/\\&/g')
    fi
    
    local response=$(curl -sS -X POST \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=${parse_mode}")
    
    if echo "$response" | grep -q '"ok":true'; then
        success "📨 Message sent to Telegram"
        
        # Log message to cache
        echo "[$(date)] $message" >> "$TELE_CACHE/sent_messages.log"
        
        # Keep only last 100 messages
        tail -n 100 "$TELE_CACHE/sent_messages.log" > "$TELE_CACHE/sent_messages.log.tmp"
        mv "$TELE_CACHE/sent_messages.log.tmp" "$TELE_CACHE/sent_messages.log"
        
        return 0
    else
        error "Failed to send message: $response"
        return 1
    fi
}

# Send system status to telegram
send_system_status() {
    local hostname=$(hostname)
    local uptime=$(uptime -p)
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local memory=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
    local disk=$(df -h / | awk 'NR==2 {print $5}')
    
    local status_message="🖥️ *System Status - $hostname*

⏰ Uptime: $uptime
📊 Load: $load
🧠 Memory: $memory
💾 Disk: $disk used
🕐 Time: $(date +'%H:%M:%S %d.%m.%Y')"

    send_telegram_message "$status_message"
}

# Send desktop session info
send_session_info() {
    local session_type="${XDG_SESSION_TYPE:-unknown}"
    local current_desktop="${XDG_CURRENT_DESKTOP:-unknown}"
    local display_info="${DISPLAY:-N/A}"
    local wayland_display="${WAYLAND_DISPLAY:-N/A}"
    
    local session_message="🏠 *Desktop Session Info*

🖥️ Session: $session_type
🎨 Desktop: $current_desktop
📺 Display: $display_info
🌊 Wayland: $wayland_display
👤 User: $(whoami)
📍 TTY: $(tty)"

    send_telegram_message "$session_message"
}

# Show help
show_help() {
    cat << EOF
📱 Telegram CLI - Enhanced Edition

Usage:
  tele "message"              Send a message
  tele --setup                Configure Telegram bot
  tele --test                 Test connection
  tele --status               Send system status
  tele --session              Send session info
  tele --history              Show recent messages
  tele --help                 Show this help

Examples:
  tele "Hello from $(hostname)!"
  tele --status
  tele "System rebooting in 5 minutes"

Configuration is stored in: $TELE_CONFIG
Message history: $TELE_CACHE/sent_messages.log
EOF
}

# Show message history
show_history() {
    if [[ -f "$TELE_CACHE/sent_messages.log" ]]; then
        log "Recent Telegram messages:"
        echo ""
        tail -n 10 "$TELE_CACHE/sent_messages.log"
    else
        warning "No message history found"
    fi
}

# Main function
main() {
    case "${1:-}" in
        --setup)
            init_telegram_config
            ;;
        --test)
            if [[ -f "$TELE_CONFIG" ]]; then
                source "$TELE_CONFIG"
                test_telegram_connection
            else
                error "No configuration found. Run: tele --setup"
                exit 1
            fi
            ;;
        --status)
            if [[ -f "$TELE_CONFIG" ]]; then
                source "$TELE_CONFIG"
                send_system_status
            else
                error "No configuration found. Run: tele --setup"
                exit 1
            fi
            ;;
        --session)
            if [[ -f "$TELE_CONFIG" ]]; then
                source "$TELE_CONFIG"
                send_session_info
            else
                error "No configuration found. Run: tele --setup"
                exit 1
            fi
            ;;
        --history)
            show_history
            ;;
        --help)
            show_help
            ;;
        "")
            error "No message provided"
            echo "Usage: tele \"message\" or tele --help"
            exit 1
            ;;
        *)
            # Send message
            if [[ -f "$TELE_CONFIG" ]]; then
                source "$TELE_CONFIG"
                send_telegram_message "$*"
            else
                error "No configuration found. Run: tele --setup"
                exit 1
            fi
            ;;
    esac
}

# Run main function
main "$@"