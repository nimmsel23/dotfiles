#!/bin/bash

# Snapshot Management Setup Script
# Configures timeshift and snapper for btrfs snapshots with automatic scheduling
# Usage: bash ~/.dotfiles/scripts/system/setup-timeshift.sh

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

TIMESHIFT_CONFIG="/etc/timeshift/timeshift.json"
TIMESHIFT_LOG_DIR="$HOME/.dotfiles/logs"

# Create logs directory
mkdir -p "$TIMESHIFT_LOG_DIR"

# Check system requirements for timeshift
check_timeshift_requirements() {
    script_header "Timeshift Requirements Check" "Verifying system compatibility"
    
    # Check if root filesystem is btrfs
    if ! df -T / | grep -q btrfs; then
        error "Root filesystem is not btrfs!"
        echo "Timeshift btrfs mode requires root filesystem to be btrfs"
        echo "Current filesystem:"
        df -T /
        return 1
    fi
    
    success "✅ Root filesystem is btrfs"
    
    # Check if timeshift is installed
    if ! command_exists timeshift; then
        log "Installing timeshift..."
        install_packages timeshift
        
        # Also install timeshift-gtk if not available
        if ! command_exists timeshift-gtk; then
            log "Installing timeshift-gtk for GUI..."
            install_packages timeshift-gtk || warning "timeshift-gtk installation failed, continuing with CLI only"
        fi
    else
        success "✅ Timeshift is already installed"
    fi
    
    # Check if snapper is installed (alternative/additional tool)
    if ! command_exists snapper; then
        log "Installing snapper (alternative btrfs snapshot tool)..."
        install_packages snapper
    else
        success "✅ Snapper is already installed"
    fi
    
    # Check if we have btrfs-progs
    if ! command_exists btrfs; then
        log "Installing btrfs-progs..."
        install_packages btrfs-progs
    fi
    
    success "✅ System requirements met for timeshift btrfs"
    return 0
}

# Configure timeshift for btrfs
configure_timeshift_btrfs() {
    script_header "Timeshift BTRFS Configuration" "Setting up automatic btrfs snapshots"
    
    # Create timeshift directory if it doesn't exist
    sudo mkdir -p /etc/timeshift
    
    log "Configuring timeshift for btrfs mode..."
    
    # Create timeshift configuration
    cat > /tmp/timeshift.json << 'EOF'
{
  "backup_device_uuid" : "",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "/home/**",
    "/root/**",
    "/tmp/**",
    "/proc/**",
    "/sys/**",
    "/dev/**",
    "/run/**",
    "/mnt/**",
    "/media/**",
    "/lost+found/**",
    "/var/log/**",
    "/var/cache/**",
    "/var/tmp/**",
    "/var/crash/**",
    "/var/lock/**"
  ],
  "exclude_apps" : []
}
EOF
    
    # Install configuration with proper permissions
    sudo cp /tmp/timeshift.json "$TIMESHIFT_CONFIG"
    sudo chmod 644 "$TIMESHIFT_CONFIG"
    sudo chown root:root "$TIMESHIFT_CONFIG"
    rm /tmp/timeshift.json
    
    success "✅ Timeshift configured for btrfs mode"
    
    # Show configuration
    log "Timeshift configuration:"
    echo "  • Mode: BTRFS"
    echo "  • Daily snapshots: 5 kept"
    echo "  • Weekly snapshots: 3 kept"  
    echo "  • Monthly snapshots: 2 kept"
    echo "  • /home excluded (separate backups recommended)"
    
    return 0
}

# Create initial snapshot
create_initial_snapshot() {
    log "Creating initial timeshift snapshot..."
    
    if sudo timeshift --create --comments "Initial setup snapshot" --tags D; then
        success "✅ Initial snapshot created successfully"
    else
        warning "⚠️ Initial snapshot creation failed, but timeshift is configured"
        echo "You can create snapshots manually later with: sudo timeshift --create"
    fi
}

# Setup timeshift cron job
setup_timeshift_cron() {
    log "Setting up timeshift cron automation..."
    
    # Check if timeshift cron is already configured
    if sudo crontab -l 2>/dev/null | grep -q timeshift; then
        success "✅ Timeshift cron already configured"
        return 0
    fi
    
    # Create temporary cron file
    sudo crontab -l 2>/dev/null > /tmp/root_cron || echo "# Root crontab" > /tmp/root_cron
    
    # Add timeshift cron jobs
    cat >> /tmp/root_cron << 'EOF'

# Timeshift automatic snapshots
# Daily snapshot at 1 AM
0 1 * * * /usr/bin/timeshift --create --scripted --comments "Daily automatic backup" --tags D >> /var/log/timeshift-cron.log 2>&1

# Weekly snapshot on Sundays at 2 AM  
0 2 * * 0 /usr/bin/timeshift --create --scripted --comments "Weekly automatic backup" --tags W >> /var/log/timeshift-cron.log 2>&1

# Monthly snapshot on 1st day at 3 AM
0 3 1 * * /usr/bin/timeshift --create --scripted --comments "Monthly automatic backup" --tags M >> /var/log/timeshift-cron.log 2>&1
EOF
    
    # Install new crontab
    sudo crontab /tmp/root_cron
    rm /tmp/root_cron
    
    success "✅ Timeshift cron jobs configured"
    echo "  • Daily: 1:00 AM (5 snapshots kept)"
    echo "  • Weekly: Sunday 2:00 AM (3 snapshots kept)"
    echo "  • Monthly: 1st day 3:00 AM (2 snapshots kept)"
}

# Test timeshift configuration
test_timeshift_config() {
    script_header "Timeshift Configuration Test" "Verifying timeshift setup"
    
    log "Testing timeshift configuration..."
    
    # Test timeshift list (should work without sudo after proper setup)
    if sudo timeshift --list > /tmp/timeshift_test.log 2>&1; then
        success "✅ Timeshift list command works"
        
        # Show current snapshots
        local snapshot_count=$(sudo timeshift --list | grep -c "^>" || echo "0")
        log "Current snapshots: $snapshot_count"
        
        if [ "$snapshot_count" -gt 0 ]; then
            echo "Recent snapshots:"
            sudo timeshift --list | head -10
        fi
    else
        error "❌ Timeshift test failed"
        cat /tmp/timeshift_test.log
        return 1
    fi
    
    # Check btrfs subvolumes
    log "BTRFS subvolumes:"
    sudo btrfs subvolume list / | grep -E "(timeshift|@)" || echo "No timeshift subvolumes found yet"
    
    success "✅ Timeshift configuration test completed"
    return 0
}

# Fix timeshift-gtk issues
fix_timeshift_gtk() {
    log "Fixing timeshift-gtk issues..."
    
    # Check if timeshift-gtk exists
    if ! command_exists timeshift-gtk; then
        log "Installing timeshift-gtk..."
        install_packages timeshift-gtk || {
            warning "timeshift-gtk not available in repos, trying alternative"
            return 0
        }
    fi
    
    # Create desktop file for timeshift-gtk if missing
    local desktop_file="/usr/share/applications/timeshift-gtk.desktop"
    if [ ! -f "$desktop_file" ]; then
        log "Creating timeshift-gtk desktop file..."
        
        sudo tee "$desktop_file" > /dev/null << 'EOF'
[Desktop Entry]
Type=Application
Name=Timeshift
Comment=System Restore Utility
Categories=System;Settings;
Keywords=backup;restore;snapshot;system;
Exec=pkexec timeshift-gtk
Icon=timeshift
StartupNotify=true
EOF
        
        success "✅ timeshift-gtk desktop file created"
    fi
    
    # Fix permissions and PolicyKit integration
    if [ -f "/usr/share/polkit-1/actions/in.teejeetech.pkexec.timeshift.policy" ]; then
        success "✅ timeshift PolicyKit integration already configured"
    else
        log "Setting up PolicyKit for timeshift..."
        # This should be handled by the package, but let's ensure it works
        sudo mkdir -p /usr/share/polkit-1/actions/
    fi
    
    success "✅ timeshift-gtk configuration completed"
}

# Configure snapper for btrfs
configure_snapper() {
    script_header "Snapper Configuration" "Setting up snapper for btrfs snapshots"
    
    log "Configuring snapper for root filesystem..."
    
    # Check if root config already exists
    if snapper list-configs | grep -q "root"; then
        success "✅ Snapper root config already exists"
    else
        log "Creating snapper root configuration..."
        sudo snapper -c root create-config /
        
        if snapper list-configs | grep -q "root"; then
            success "✅ Snapper root config created"
        else
            error "❌ Failed to create snapper root config"
            return 1
        fi
    fi
    
    # Configure snapper settings
    log "Optimizing snapper configuration..."
    
    # Set timeline cleanup (keep more snapshots than default)
    sudo snapper -c root set-config "TIMELINE_MIN_AGE=1800"      # 30 minutes
    sudo snapper -c root set-config "TIMELINE_LIMIT_HOURLY=24"   # 24 hourly
    sudo snapper -c root set-config "TIMELINE_LIMIT_DAILY=7"     # 7 daily  
    sudo snapper -c root set-config "TIMELINE_LIMIT_WEEKLY=4"    # 4 weekly
    sudo snapper -c root set-config "TIMELINE_LIMIT_MONTHLY=6"   # 6 monthly
    sudo snapper -c root set-config "TIMELINE_LIMIT_YEARLY=2"    # 2 yearly
    
    # Enable timeline snapshots
    sudo snapper -c root set-config "TIMELINE_CREATE=yes"
    
    # Set number cleanup 
    sudo snapper -c root set-config "NUMBER_MIN_AGE=1800"        # 30 minutes
    sudo snapper -c root set-config "NUMBER_LIMIT=50"           # Max 50 snapshots
    sudo snapper -c root set-config "NUMBER_LIMIT_IMPORTANT=10" # Max 10 important
    
    success "✅ Snapper configuration optimized"
    
    # Enable snapper systemd services
    log "Enabling snapper systemd services..."
    
    if systemctl is-enabled snapper-timeline.timer >/dev/null 2>&1; then
        success "✅ snapper-timeline.timer already enabled"
    else
        sudo systemctl enable snapper-timeline.timer
        sudo systemctl start snapper-timeline.timer
        success "✅ snapper-timeline.timer enabled and started"
    fi
    
    if systemctl is-enabled snapper-cleanup.timer >/dev/null 2>&1; then
        success "✅ snapper-cleanup.timer already enabled"
    else
        sudo systemctl enable snapper-cleanup.timer  
        sudo systemctl start snapper-cleanup.timer
        success "✅ snapper-cleanup.timer enabled and started"
    fi
    
    return 0
}

# Create initial snapper snapshot
create_initial_snapper_snapshot() {
    log "Creating initial snapper snapshot..."
    
    if sudo snapper -c root create --description "Initial system setup" --type single; then
        success "✅ Initial snapper snapshot created"
    else
        warning "⚠️ Initial snapper snapshot creation failed"
    fi
}

# Show snapper status
show_snapper_status() {
    log "📊 Snapper Status:"
    echo ""
    
    # List configurations
    echo "Configurations:"
    snapper list-configs 2>/dev/null || echo "No configurations found"
    echo ""
    
    # List snapshots for root config if it exists
    if snapper list-configs | grep -q "root"; then
        echo "Recent snapshots:"
        sudo snapper -c root list | tail -10 || echo "No snapshots found"
        echo ""
        
        # Show cleanup status
        echo "Cleanup algorithms:"
        sudo snapper -c root get-config | grep -E "(TIMELINE|NUMBER)_" || echo "Config not accessible"
    fi
}

# Show timeshift management commands
show_timeshift_usage() {
    script_header "Timeshift Usage Guide" "Essential commands and tips"
    
    echo "📋 Timeshift Commands:"
    echo "  sudo timeshift --list                    # List all snapshots"
    echo "  sudo timeshift --create --comments 'msg' # Create snapshot with comment"
    echo "  sudo timeshift --restore                 # Restore from snapshot (interactive)"
    echo "  sudo timeshift --delete --snapshot 'name' # Delete specific snapshot"
    echo "  timeshift-gtk                            # Open GUI (if installed)"
    echo ""
    echo "📋 Snapper Commands:"
    echo "  sudo snapper -c root list                # List all snapshots"
    echo "  sudo snapper -c root create -d 'msg'     # Create snapshot with description"
    echo "  sudo snapper -c root undochange 1..2     # Undo changes between snapshots"
    echo "  sudo snapper -c root delete 42           # Delete snapshot number 42"
    echo "  systemctl status snapper-timeline.timer  # Check automatic snapshots"
    echo ""
    echo "📋 BTRFS Commands:"
    echo "  sudo btrfs subvolume list /              # List all subvolumes"
    echo "  sudo btrfs filesystem show               # Show filesystem info"
    echo "  sudo btrfs filesystem usage /           # Show space usage"
    echo ""
    echo "📋 Snapshot Locations:"
    echo "  Timeshift: /run/timeshift/backup/timeshift-btrfs/snapshots/"
    echo "  Snapper:   /.snapshots/"
    echo ""
    echo "📋 Configuration:"
    echo "  /etc/timeshift/timeshift.json           # Timeshift configuration"
    echo "  /etc/snapper/configs/root               # Snapper configuration"
    echo "  /var/log/timeshift-cron.log             # Timeshift cron logs"
    echo ""
    echo "💡 Tips:"
    echo "  • Both timeshift and snapper can coexist"
    echo "  • Snapper integrates better with pacman hooks"
    echo "  • Snapshots are created automatically via systemd timers"
    echo "  • Boot from live USB to restore if system is broken"
    echo "  • /home is excluded - use separate backup strategy"
    echo "  • Create snapshot before major system changes"
}

# Interactive timeshift menu
timeshift_menu() {
    while true; do
        echo ""
        echo "🕰️ Snapshot Management Menu:"
        echo "═══════════════════════════"
        echo "  [1] 🔍 Check requirements"
        echo "  [2] ⚙️  Configure timeshift for btrfs"
        echo "  [3] 🔧 Configure snapper for btrfs"
        echo "  [4] 📸 Create initial snapshots"
        echo "  [5] ⏰ Setup cron automation"
        echo "  [6] 🧪 Test configuration"
        echo "  [7] 🖥️  Fix timeshift-gtk"
        echo "  [8] 🎯 Complete setup (both tools)"
        echo "  [9] 📋 Show usage guide"
        echo "  [A] 📊 Current status"
        echo "  [0] 🚪 Exit"
        echo ""
        
        read -p "Choose option [0-9]: " choice
        
        case "$choice" in
            1) check_timeshift_requirements ;;
            2) configure_timeshift_btrfs ;;
            3) configure_snapper ;;
            4) 
                create_initial_snapshot
                create_initial_snapper_snapshot
                ;;
            5) setup_timeshift_cron ;;
            6) test_timeshift_config ;;
            7) fix_timeshift_gtk ;;
            8)
                log "🎯 Starting complete snapshot management setup..."
                check_timeshift_requirements && \
                configure_timeshift_btrfs && \
                configure_snapper && \
                create_initial_snapshot && \
                create_initial_snapper_snapshot && \
                setup_timeshift_cron && \
                fix_timeshift_gtk && \
                test_timeshift_config && \
                show_timeshift_usage
                ;;
            9) show_timeshift_usage ;;
            A|a)
                log "📊 Current Snapshot Status:"
                echo ""
                echo "=== TIMESHIFT ==="
                if sudo timeshift --list >/dev/null 2>&1; then
                    sudo timeshift --list
                else
                    error "Timeshift not properly configured"
                fi
                echo ""
                echo "=== SNAPPER ==="
                show_snapper_status
                ;;
            0)
                log "👋 Exiting snapshot management setup"
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
        exit 1
    fi
    
    if ! check_requirements; then
        error "System requirements not met"
        exit 1
    fi
    
    case "${1:-}" in
        --auto)
            log "🎯 Running automatic timeshift setup..."
            check_timeshift_requirements && \
            configure_timeshift_btrfs && \
            create_initial_snapshot && \
            setup_timeshift_cron && \
            fix_timeshift_gtk && \
            test_timeshift_config
            ;;
        --help)
            echo "Timeshift Setup Script"
            echo ""
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --auto      Run complete setup automatically"
            echo "  --help      Show this help"
            echo ""
            echo "Interactive mode: Run without arguments"
            ;;
        "")
            timeshift_menu
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
    
    script_footer "Timeshift Setup"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi