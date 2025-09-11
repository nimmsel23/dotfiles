#!/bin/bash

# 🛸 Post-Reinstall Recovery Wizard 
# Lands the UFO - Restores everything after system reinstall
# Usage: bash ~/.dotfiles/scripts/post-install/recovery-wizard.sh

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

RECOVERY_LOG="$HOME/.cache/recovery-wizard.log"
RECOVERY_STATE="$HOME/.cache/recovery-state.json"

# Create cache directory
mkdir -p "$(dirname "$RECOVERY_LOG")"

# Logging function
recovery_log() {
    local message="$1"
    echo "[$(date '+%H:%M:%S')] $message" | tee -a "$RECOVERY_LOG"
}

# Welcome message
show_welcome() {
    clear
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                  🛸 RECOVERY WIZARD 🛸                       ║
║           Post-Reinstall System Recovery Manager               ║
╠════════════════════════════════════════════════════════════════╣
║  This wizard will help restore your system after reinstall    ║
║  • Cloud sync (rclone)                                        ║
║  • Telegram integration                                       ║
║  • Essential applications                                     ║  
║  • Personal configurations                                    ║
╚════════════════════════════════════════════════════════════════╝

EOF
    
    recovery_log "Recovery wizard started"
    echo "💾 Log file: $RECOVERY_LOG"
    echo ""
    
    read -p "🚀 Ready to start recovery? [Y/n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]?$ ]]; then
        echo "❌ Recovery cancelled"
        exit 0
    fi
}

# Check system requirements
check_recovery_requirements() {
    log "🔍 Checking system requirements..."
    
    local missing=()
    
    # Essential tools
    command_exists curl || missing+=("curl")
    command_exists wget || missing+=("wget") 
    command_exists git || missing+=("git")
    command_exists yay || missing+=("yay")
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        echo "Install with: sudo pacman -S ${missing[*]}"
        return 1
    fi
    
    success "✅ System requirements met"
    return 0
}

# rclone setup automation
setup_rclone_wizard() {
    log "☁️ rclone Setup Wizard"
    echo ""
    
    if command_exists rclone; then
        success "rclone is already installed"
    else
        log "Installing rclone..."
        if yay -S --noconfirm rclone; then
            success "rclone installed successfully"
        else
            error "Failed to install rclone"
            return 1
        fi
    fi
    
    echo "rclone configuration options:"
    echo "  [1] Google Drive (recommended)"
    echo "  [2] OneDrive"
    echo "  [3] Dropbox"
    echo "  [4] Skip rclone setup"
    echo ""
    
    read -p "Choose cloud provider [1-4]: " rclone_choice
    
    case "$rclone_choice" in
        1)
            log "Setting up Google Drive..."
            
            # Check if gdrive remote already exists
            if rclone listremotes | grep -q "gdrive:"; then
                success "Google Drive already configured"
                
                # Test connection
                if rclone lsd gdrive: >/dev/null 2>&1; then
                    success "✅ Google Drive connection verified"
                else
                    warning "Google Drive config exists but connection failed"
                    read -p "Reconfigure Google Drive? [y/N]: " reconfig
                    if [[ "$reconfig" =~ ^[Yy]$ ]]; then
                        rclone config delete gdrive
                        setup_google_drive_interactive
                    fi
                fi
            else
                setup_google_drive_interactive
            fi
            
            # Setup Desktop sync if drive works
            if rclone lsd gdrive: >/dev/null 2>&1; then
                echo ""
                log "Setting up Desktop folder sync..."
                read -p "Setup automatic Desktop sync? [Y/n]: " setup_sync
                if [[ "$setup_sync" =~ ^[Yy]?$ ]]; then
                    setup_desktop_sync
                fi
            fi
            ;;
        2|3)
            warning "OneDrive/Dropbox setup not implemented yet"
            log "Use: rclone config"
            ;;
        4)
            log "Skipping rclone setup"
            ;;
        *)
            error "Invalid choice"
            ;;
    esac
}

# Interactive Google Drive setup
setup_google_drive_interactive() {
    log "🔧 Interactive Google Drive setup..."
    echo ""
    echo "Setting up Google Drive access:"
    echo "1. rclone will guide you through authentication"
    echo "2. A browser will open for Google login"
    echo "3. Grant rclone access to your Google Drive"
    echo "4. Follow the prompts"
    echo ""
    
    read -p "Ready to start Google Drive setup? [Y/n]: " ready
    if [[ ! "$ready" =~ ^[Yy]?$ ]]; then
        log "Google Drive setup cancelled"
        return 1
    fi
    
    # Run rclone config interactively
    log "Starting rclone configuration..."
    rclone config create gdrive drive scope=drive
    
    # Test the connection
    if rclone lsd gdrive: >/dev/null 2>&1; then
        success "✅ Google Drive configured successfully"
        
        # Show some info
        echo ""
        log "Google Drive info:"
        rclone about gdrive: 2>/dev/null || echo "Could not get drive info"
        
        return 0
    else
        error "❌ Google Drive configuration failed"
        return 1
    fi
}

# Setup desktop sync
setup_desktop_sync() {
    log "🔄 Setting up Desktop folder sync..."
    
    # Check if Desktop sync script exists
    local sync_script="${SCRIPT_DIR}/../utils/rclone-desktop-sync.sh"
    if [ -f "$sync_script" ]; then
        log "Running Desktop sync setup..."
        bash "$sync_script"
    else
        # Create a simple sync setup
        log "Creating basic Desktop sync..."
        
        # Create sync directory in Google Drive
        rclone mkdir gdrive:Desktop-Sync 2>/dev/null || true
        
        # Test sync
        if rclone ls gdrive:Desktop-Sync >/dev/null 2>&1; then
            success "✅ Desktop sync folder created in Google Drive"
            
            echo ""
            echo "📋 Manual sync commands:"
            echo "  Upload:   rclone sync ~/Desktop/ gdrive:Desktop-Sync/"
            echo "  Download: rclone sync gdrive:Desktop-Sync/ ~/Desktop/"
            echo "  Compare:  rclone check ~/Desktop/ gdrive:Desktop-Sync/"
            echo ""
            
            # Offer to do initial sync
            read -p "Upload current Desktop to Google Drive? [y/N]: " upload
            if [[ "$upload" =~ ^[Yy]$ ]]; then
                log "Uploading Desktop to Google Drive..."
                rclone sync ~/Desktop/ gdrive:Desktop-Sync/ --progress
                success "✅ Desktop uploaded to Google Drive"
            fi
        else
            error "❌ Failed to create Desktop sync folder"
        fi
    fi
}

# Telegram setup automation
setup_telegram_wizard() {
    log "📱 Telegram Setup Wizard"
    echo ""
    
    read -p "Setup Telegram integration? [Y/n]: " setup_telegram
    if [[ ! "$setup_telegram" =~ ^[Yy]?$ ]]; then
        log "Skipping Telegram setup"
        return 0
    fi
    
    # Check if python/pip available
    if ! command_exists python3; then
        log "Installing Python..."
        yay -S --noconfirm python python-pip
    fi
    
    echo "Telegram setup options:"
    echo "  [1] Simple CLI bot (recommended for laptop)"
    echo "  [2] Advanced Python bot"
    echo "  [3] Google Apps Script integration" 
    echo "  [4] Skip Telegram"
    echo ""
    
    read -p "Choose option [1-4]: " telegram_choice
    
    case "$telegram_choice" in
        1)
            log "Setting up simple Telegram CLI..."
            
            # Check if already configured
            if [ -f "$HOME/.config/telegram.env" ]; then
                success "Telegram already configured"
                
                # Test connection
                if bash "${SCRIPT_DIR}/../utils/telegram/tele.sh" --test >/dev/null 2>&1; then
                    success "✅ Telegram connection verified"
                else
                    warning "Telegram config exists but connection failed"
                    read -p "Reconfigure Telegram? [y/N]: " reconfig
                    if [[ "$reconfig" =~ ^[Yy]$ ]]; then
                        bash "${SCRIPT_DIR}/../utils/telegram/tele.sh" --setup
                    fi
                fi
            else
                bash "${SCRIPT_DIR}/../utils/telegram/tele.sh" --setup
            fi
            
            # Send test message if configured
            if [ -f "$HOME/.config/telegram.env" ]; then
                read -p "Send recovery test message? [Y/n]: " send_test
                if [[ "$send_test" =~ ^[Yy]?$ ]]; then
                    bash "${SCRIPT_DIR}/../utils/telegram/tele.sh" "🛸 Recovery wizard completed on $(hostname)!"
                fi
            fi
            
            success "✅ Telegram CLI ready"
            ;;
        2)
            log "Installing Python Telegram bot..."
            pip install --user python-telegram-bot requests
            
            log "Creating Telegram bot template..."
            cat > "$HOME/.local/bin/telegram-bot.py" << 'EOF'
#!/usr/bin/env python3
# Simple Telegram Bot Template
# Usage: python3 telegram-bot.py

import os
from telegram import Bot

BOT_TOKEN = os.environ.get('BOT_TOKEN', 'YOUR_BOT_TOKEN_HERE')
CHAT_ID = os.environ.get('CHAT_ID', 'YOUR_CHAT_ID_HERE')

def send_message(text):
    bot = Bot(token=BOT_TOKEN)
    bot.send_message(chat_id=CHAT_ID, text=text)

if __name__ == "__main__":
    send_message("🚀 Python Telegram bot is working!")
EOF
            chmod +x "$HOME/.local/bin/telegram-bot.py"
            success "✅ Python Telegram bot template created"
            ;;
        3)
            log "Google Apps Script setup info:"
            echo ""
            echo "📋 Manual steps for GAS integration:"
            echo "1. Go to script.google.com"
            echo "2. Create new project"
            echo "3. Copy your GAS webhook URL"
            echo "4. Use webhook for notifications"
            echo ""
            echo "💡 This keeps your laptop independent!"
            ;;
        4)
            log "Skipping Telegram setup"
            ;;
        *)
            error "Invalid choice"
            ;;
    esac
}

# Essential applications recovery
restore_essential_apps() {
    log "📦 Essential Applications Recovery"
    echo ""
    
    read -p "Install essential applications? [Y/n]: " install_apps
    if [[ ! "$install_apps" =~ ^[Yy]?$ ]]; then
        log "Skipping application installation"
        return 0
    fi
    
    log "Installing essential applications..."
    
    local apps=(
        # System tools
        "btop"           # System monitor
        "ranger"         # File manager
        "calcurse"       # Calendar
        "taskwarrior"    # Task management
        "neovim"         # Editor
        
        # Development
        "nodejs"         # JavaScript runtime
        "npm"           # Node package manager
        "code"          # VS Code
        
        # Multimedia
        "vlc"           # Video player
        "firefox"       # Browser
        
        # Utilities
        "curl"
        "wget" 
        "git"
        "htop"
    )
    
    for app in "${apps[@]}"; do
        if ! command_exists "$app"; then
            log "Installing $app..."
            yay -S --noconfirm "$app" || warning "Failed to install $app"
        else
            success "$app already installed"
        fi
    done
    
    success "✅ Essential applications processed"
}

# Configuration restoration
restore_configurations() {
    log "⚙️ Configuration Restoration"
    echo ""
    
    # Check if rclone is configured
    if command_exists rclone && rclone listremotes | grep -q "gdrive"; then
        read -p "Restore configurations from cloud? [Y/n]: " restore_configs
        if [[ "$restore_configs" =~ ^[Yy]?$ ]]; then
            log "Downloading configurations from cloud..."
            
            # Create backup directories
            local backup_dirs=(
                ".config/fish"
                ".config/calcurse" 
                ".config/Code/User"
                ".bashrc.backup"
            )
            
            for dir in "${backup_dirs[@]}"; do
                if rclone lsf "gdrive:backups/$dir" >/dev/null 2>&1; then
                    log "Restoring $dir..."
                    rclone sync "gdrive:backups/$dir" "$HOME/$dir"
                fi
            done
            
            success "✅ Configurations restored from cloud"
        fi
    else
        warning "rclone not configured - skipping cloud restore"
    fi
}

# Recovery completion
complete_recovery() {
    log "🎉 Recovery Completion"
    echo ""
    
    # Save recovery state
    cat > "$RECOVERY_STATE" << EOF
{
    "completed": true,
    "date": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "dotfiles_version": "$(cd "$HOME/.dotfiles" && git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
}
EOF
    
    success "✅ Recovery completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "  • System requirements: ✅"
    echo "  • Cloud sync (rclone): $(command_exists rclone && echo '✅' || echo '⏭️ skipped')"
    echo "  • Telegram integration: $([ -f "$HOME/.config/telegram.env" ] && echo '✅' || echo '⏭️ skipped')"
    echo "  • Essential apps: ✅"
    echo "  • Configurations: ✅"
    echo ""
    echo "🚀 Next steps:"
    echo "  • Use session-manager for desktop environments"
    echo "  • Check 'tele --help' for Telegram commands"
    echo "  • Desktop sync: rclone-desktop-sync.sh"
    echo ""
    echo "📝 Recovery log: $RECOVERY_LOG"
    echo "💾 Recovery state: $RECOVERY_STATE"
}

# Interactive recovery menu
recovery_menu() {
    while true; do
        echo ""
        echo "🛸 Recovery Wizard Menu:"
        echo "════════════════════════"
        echo "  [1] 🔍 Check system requirements"
        echo "  [2] ☁️  Setup cloud sync (rclone)"
        echo "  [3] 📱 Setup Telegram integration"
        echo "  [4] 📦 Install essential applications"
        echo "  [5] ⚙️  Restore configurations"
        echo "  [6] 🎯 Complete full recovery (all steps)"
        echo "  [7] 📋 Show recovery status"
        echo "  [0] 🚪 Exit"
        echo ""
        
        read -p "Choose option [0-7]: " choice
        
        case "$choice" in
            1) check_recovery_requirements ;;
            2) setup_rclone_wizard ;;
            3) setup_telegram_wizard ;;
            4) restore_essential_apps ;;
            5) restore_configurations ;;
            6) 
                log "🎯 Starting full recovery..."
                check_recovery_requirements && \
                setup_rclone_wizard && \
                setup_telegram_wizard && \
                restore_essential_apps && \
                restore_configurations && \
                complete_recovery
                ;;
            7)
                log "📋 Recovery Status:"
                if [ -f "$RECOVERY_STATE" ]; then
                    cat "$RECOVERY_STATE"
                else
                    echo "No recovery completed yet"
                fi
                ;;
            0)
                log "👋 Exiting recovery wizard"
                break
                ;;
            *)
                error "Invalid choice: $choice"
                ;;
        esac
    done
}

# Main function
main() {
    if ! check_dotfiles_env; then
        error "Dotfiles environment not found!"
        echo "Run this from ~/.dotfiles directory"
        exit 1
    fi
    
    show_welcome
    check_recovery_requirements || exit 1
    recovery_menu
    
    echo ""
    success "🛸 UFO successfully landed! Recovery wizard completed."
    echo "Welcome back to your fully restored system! 🎉"
}

# Run main function
main "$@"