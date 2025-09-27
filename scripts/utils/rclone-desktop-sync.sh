#!/bin/bash

# Rclone Desktop Bisync Script
# Part of nimmsel23's dotfiles utils scripts
# Daily bidirectional sync of Desktop folder to cloud storage
# Usage: bash ~/.dotfiles/scripts/utils/rclone-desktop-sync.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
SYNC_CONFIG="$HOME/.dotfiles/config/rclone/desktop-sync.conf"
LOG_FILE="$HOME/.dotfiles/logs/rclone-desktop-sync.log"
LOCK_FILE="/tmp/rclone-desktop-sync.lock"

# Default configuration
DEFAULT_LOCAL_PATH="$HOME/Desktop"
DEFAULT_REMOTE_NAME="gdrive"
DEFAULT_REMOTE_PATH="Desktop"
DEFAULT_MAX_DELETES="10"

# Load sync configuration
load_sync_config() {
    if [ -f "$SYNC_CONFIG" ]; then
        source "$SYNC_CONFIG"
        log "Loaded configuration from $SYNC_CONFIG"
    else
        warning "Configuration not found, using defaults"
        LOCAL_PATH="$DEFAULT_LOCAL_PATH"
        REMOTE_NAME="$DEFAULT_REMOTE_NAME"
        REMOTE_PATH="$DEFAULT_REMOTE_PATH"
        MAX_DELETES="$DEFAULT_MAX_DELETES"
    fi
}

# Create sync configuration
create_sync_config() {
    script_header "Rclone Desktop Sync Configuration" "Setup bidirectional sync for Desktop folder"
    
    echo "Available rclone remotes:"
    if ! rclone listremotes 2>/dev/null; then
        error "No rclone remotes configured"
        echo ""
        echo "Setup rclone first with: rclone config"
        echo "Common providers: Google Drive, OneDrive, Dropbox, etc."
        return 1
    fi
    echo ""
    
    # Get configuration from user
    read -p "Local Desktop path [$DEFAULT_LOCAL_PATH]: " local_input
    LOCAL_PATH="${local_input:-$DEFAULT_LOCAL_PATH}"
    
    read -p "Remote name (from list above) [$DEFAULT_REMOTE_NAME]: " remote_input
    REMOTE_NAME="${remote_input:-$DEFAULT_REMOTE_NAME}"
    
    read -p "Remote path [$DEFAULT_REMOTE_PATH]: " remote_path_input
    REMOTE_PATH="${remote_path_input:-$DEFAULT_REMOTE_PATH}"
    
    read -p "Max deletes per sync (safety) [$DEFAULT_MAX_DELETES]: " max_deletes_input
    MAX_DELETES="${max_deletes_input:-$DEFAULT_MAX_DELETES}"
    
    # Validate inputs
    if [ ! -d "$LOCAL_PATH" ]; then
        error "Local path does not exist: $LOCAL_PATH"
        return 1
    fi
    
    # Test remote connection
    log "Testing remote connection..."
    if ! rclone lsd "$REMOTE_NAME:" >/dev/null 2>&1; then
        error "Cannot connect to remote: $REMOTE_NAME"
        echo "Check your rclone configuration with: rclone config"
        return 1
    fi
    
    # Create config directory
    mkdir -p "$(dirname "$SYNC_CONFIG")"
    
    # Save configuration
    cat > "$SYNC_CONFIG" << EOF
# Rclone Desktop Sync Configuration
# Generated on $(date)

LOCAL_PATH="$LOCAL_PATH"
REMOTE_NAME="$REMOTE_NAME"
REMOTE_PATH="$REMOTE_PATH"
MAX_DELETES="$MAX_DELETES"

# Sync options
RCLONE_OPTIONS="--verbose --progress --checksum --exclude '*.tmp' --exclude '.DS_Store' --exclude 'Thumbs.db'"

# Bisync options
BISYNC_OPTIONS="--create-empty-src-dirs --compare checksum --slow-hash-sync-only"
EOF
    
    success "Configuration saved to $SYNC_CONFIG"
    return 0
}

# Check if bisync is initialized
check_bisync_init() {
    local remote_full="${REMOTE_NAME}:${REMOTE_PATH}"
    
    # Check if .bisync directory exists
    if ! rclone lsf "$remote_full/.bisync" >/dev/null 2>&1 && [ ! -d "$LOCAL_PATH/.bisync" ]; then
        warning "Bisync not initialized"
        return 1
    fi
    
    return 0
}

# Initialize bisync
init_bisync() {
    local remote_full="${REMOTE_NAME}:${REMOTE_PATH}"
    
    log "Initializing bisync between $LOCAL_PATH and $remote_full"
    echo ""
    echo "⚠️  IMPORTANT: Bisync initialization will:"
    echo "   • Compare local and remote files"
    echo "   • Create .bisync metadata directories"
    echo "   • Ensure both sides are in sync before starting"
    echo ""
    echo "Make sure both locations have the files you want to keep!"
    echo ""
    
    read -p "Continue with bisync initialization? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        warning "Initialization cancelled"
        return 1
    fi
    
    # Run bisync initialization
    log "Running bisync --resync..."
    if rclone bisync "$LOCAL_PATH" "$remote_full" \
        --resync \
        $RCLONE_OPTIONS \
        $BISYNC_OPTIONS \
        --log-file="$LOG_FILE" \
        --log-level=INFO; then
        success "Bisync initialized successfully"
        return 0
    else
        error "Bisync initialization failed"
        echo "Check log file: $LOG_FILE"
        return 1
    fi
}

# Perform bisync
perform_bisync() {
    local remote_full="${REMOTE_NAME}:${REMOTE_PATH}"
    
    # Check for lock file
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            error "Another sync is already running (PID: $lock_pid)"
            return 1
        else
            warning "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    # Create lock file
    echo $$ > "$LOCK_FILE"
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "Starting bisync: $LOCAL_PATH ↔ $remote_full"
    
    # Perform the sync
    local sync_success=true
    if rclone bisync "$LOCAL_PATH" "$remote_full" \
        $RCLONE_OPTIONS \
        $BISYNC_OPTIONS \
        --max-delete="$MAX_DELETES" \
        --log-file="$LOG_FILE" \
        --log-level=INFO; then
        success "Desktop bisync completed successfully"
    else
        local exit_code=$?
        error "Bisync failed with exit code: $exit_code"
        
        case $exit_code in
            1)
                error "Syntax or usage error"
                ;;
            2)
                error "Error not otherwise categorised"
                ;;
            3)
                error "Directory not found"
                ;;
            4)
                error "File not found"
                ;;
            6)
                error "--max-delete threshold was reached"
                echo "Too many deletes detected (safety limit: $MAX_DELETES)"
                echo "Check both locations manually before next sync"
                ;;
            *)
                error "Unknown error occurred"
                ;;
        esac
        
        sync_success=false
    fi
    
    # Remove lock file
    rm -f "$LOCK_FILE"
    
    # Send telegram notification if available
    if command_exists tele && [ -f "$HOME/.dotfiles/config/telegram/tele.env" ]; then
        if $sync_success; then
            tele "✅ Desktop sync completed successfully" 2>/dev/null || true
        else
            tele "❌ Desktop sync failed - check logs" 2>/dev/null || true
        fi
    fi
    
    return $($sync_success && echo 0 || echo 1)
}

# Show sync status
show_sync_status() {
    local remote_full="${REMOTE_NAME}:${REMOTE_PATH}"
    
    echo "Desktop Sync Status:"
    echo "═══════════════════════════"
    echo "Local Path: $LOCAL_PATH"
    echo "Remote: $remote_full"
    echo "Max Deletes: $MAX_DELETES"
    echo ""
    
    # Check if initialized
    if check_bisync_init; then
        success "Bisync initialized"
    else
        warning "Bisync not initialized"
    fi
    
    # Check lock file
    if [ -f "$LOCK_FILE" ]; then
        warning "Sync currently running (PID: $(cat "$LOCK_FILE"))"
    else
        log "No sync currently running"
    fi
    
    # Show last log entries
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "Recent log entries:"
        echo "─────────────────────────"
        tail -10 "$LOG_FILE" | grep -E "(INFO|ERROR|NOTICE)" | tail -5
    fi
    
    # Check crontab
    echo ""
    if crontab -l 2>/dev/null | grep -q "rclone-desktop-sync.sh"; then
        success "Cron job configured"
        echo "Schedule: $(crontab -l 2>/dev/null | grep "rclone-desktop-sync.sh" | cut -d' ' -f1-5)"
    else
        warning "Cron job not configured"
    fi
}

# Setup cron job
setup_cron() {
    local script_path="$HOME/.dotfiles/scripts/utils/rclone-desktop-sync.sh"
    
    echo "Cron Schedule Options:"
    echo "═══════════════════════════"
    echo "1. Daily at 2 AM"
    echo "2. Every 6 hours" 
    echo "3. Daily at specific time"
    echo "4. Custom schedule"
    echo "5. Remove existing cron job"
    echo ""
    
    read -p "Choose option [1-5]: " cron_option
    
    local cron_schedule=""
    case "$cron_option" in
        1)
            cron_schedule="0 2 * * *"
            ;;
        2)
            cron_schedule="0 */6 * * *"
            ;;
        3)
            read -p "Enter hour (0-23): " hour
            cron_schedule="0 ${hour:-2} * * *"
            ;;
        4)
            read -p "Enter cron schedule (e.g., '0 */4 * * *'): " custom_schedule
            cron_schedule="$custom_schedule"
            ;;
        5)
            log "Removing existing cron job..."
            crontab -l 2>/dev/null | grep -v "rclone-desktop-sync.sh" | crontab -
            success "Cron job removed"
            return 0
            ;;
        *)
            error "Invalid option"
            return 1
            ;;
    esac
    
    if [ -z "$cron_schedule" ]; then
        error "No schedule specified"
        return 1
    fi
    
    # Add cron job
    log "Adding cron job: $cron_schedule"
    
    # Get existing crontab, remove old entry, add new entry
    (crontab -l 2>/dev/null | grep -v "rclone-desktop-sync.sh"; 
     echo "$cron_schedule $script_path sync >> $HOME/.dotfiles/logs/cron.log 2>&1") | crontab -
    
    success "Cron job configured: $cron_schedule"
    echo "Next run: $(date -d "$(echo "$cron_schedule" | awk '{print $2":"$1}')" 2>/dev/null || echo "Check with: crontab -l")"
}

# Main function
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    # Check dependencies
    if ! command_exists rclone; then
        error "rclone is not installed"
        echo "Install with: install rclone"
        exit 1
    fi
    
    # Check if rclone is configured
    if [ ! -f "$RCLONE_CONFIG" ]; then
        error "rclone is not configured"
        echo "Run: rclone config"
        exit 1
    fi
    
    # Load configuration
    load_sync_config
    
    case "${1:-menu}" in
        sync)
            if [ ! -f "$SYNC_CONFIG" ]; then
                error "Sync not configured. Run: $0 config"
                exit 1
            fi
            
            if ! check_bisync_init; then
                warning "Bisync not initialized"
                init_bisync || exit 1
            fi
            
            perform_bisync
            ;;
        config)
            create_sync_config
            ;;
        init)
            if [ ! -f "$SYNC_CONFIG" ]; then
                error "Create configuration first with: $0 config"
                exit 1
            fi
            init_bisync
            ;;
        status)
            show_sync_status
            ;;
        cron)
            setup_cron
            ;;
        menu|*)
            script_header "Rclone Desktop Sync" "Bidirectional sync of Desktop folder to cloud storage"
            
            echo "Options:"
            echo "  sync     - Perform sync now"
            echo "  config   - Setup sync configuration"  
            echo "  init     - Initialize bisync (first time)"
            echo "  status   - Show sync status"
            echo "  cron     - Setup/manage cron job"
            echo ""
            
            if [ ! -f "$SYNC_CONFIG" ]; then
                warning "Not configured yet. Run: $0 config"
            else
                show_sync_status
            fi
            ;;
    esac
}

# Cleanup on exit
cleanup() {
    [ -f "$LOCK_FILE" ] && rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi