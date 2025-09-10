#!/bin/bash

# WiFi Power Management Fix Script
# Fixes WiFi disconnection issues caused by aggressive power management
# Usage: bash wifi-power-fix.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Script header
script_header() {
    echo "═══════════════════════════════════════════════════════════════"
    echo "          WiFi Power Management Fix Script"
    echo "     Fixes: WiFi asking for password / random disconnects"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Get WiFi interface name
get_wifi_interface() {
    local interface=$(nmcli -t -f DEVICE,TYPE device | grep wifi | head -n1 | cut -d: -f1)
    if [ -z "$interface" ]; then
        interface=$(ip link | grep -E "wl[a-z0-9]+" | head -n1 | cut -d: -f2 | xargs)
    fi
    echo "$interface"
}

# Get WiFi driver
get_wifi_driver() {
    local interface="$1"
    if [ -n "$interface" ]; then
        readlink "/sys/class/net/$interface/device/driver" | xargs basename 2>/dev/null
    fi
}

# Show current WiFi status
show_wifi_status() {
    log "Current WiFi Status:"
    echo "────────────────────────────────────────"
    
    local interface=$(get_wifi_interface)
    local driver=$(get_wifi_driver "$interface")
    
    if [ -n "$interface" ]; then
        success "WiFi Interface: $interface"
        [ -n "$driver" ] && success "WiFi Driver: $driver"
        
        # NetworkManager power save status
        local nm_powersave=$(nmcli -f WIFI-PROPERTIES.POWERSAVE device show "$interface" 2>/dev/null | grep POWERSAVE | awk '{print $2}')
        if [ -n "$nm_powersave" ]; then
            if [ "$nm_powersave" = "enabled" ]; then
                warning "NetworkManager WiFi PowerSave: ENABLED (problematic)"
            else
                success "NetworkManager WiFi PowerSave: DISABLED"
            fi
        fi
        
        # Kernel power save status (for iwlwifi)
        if [ "$driver" = "iwlwifi" ]; then
            local kernel_powersave=$(cat /sys/module/iwlwifi/parameters/power_save 2>/dev/null)
            if [ "$kernel_powersave" = "Y" ] || [ "$kernel_powersave" = "1" ]; then
                warning "Kernel iwlwifi PowerSave: ENABLED (problematic)"
            else
                success "Kernel iwlwifi PowerSave: DISABLED"
            fi
        fi
        
        # TLP WiFi settings
        if command -v tlp-stat >/dev/null 2>&1; then
            local tlp_ac=$(sudo tlp-stat -c 2>/dev/null | grep "WIFI_PWR_ON_AC" | cut -d= -f2 | xargs)
            local tlp_bat=$(sudo tlp-stat -c 2>/dev/null | grep "WIFI_PWR_ON_BAT" | cut -d= -f2 | xargs)
            
            if [ "$tlp_ac" = "on" ] || [ "$tlp_bat" = "on" ]; then
                warning "TLP WiFi PowerSave: ENABLED (AC: $tlp_ac, BAT: $tlp_bat)"
            else
                success "TLP WiFi PowerSave: DISABLED (AC: $tlp_ac, BAT: $tlp_bat)"
            fi
        fi
        
        # Connection status
        local connection_status=$(nmcli -t -f DEVICE,STATE device | grep "$interface" | cut -d: -f2)
        if [ "$connection_status" = "connected" ]; then
            success "Connection Status: CONNECTED"
        else
            warning "Connection Status: $connection_status"
        fi
        
    else
        error "No WiFi interface found!"
        return 1
    fi
    
    echo ""
}

# Create backup directory
create_backup() {
    local backup_dir="$HOME/.wifi-power-fix-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing configs
    [ -f /etc/NetworkManager/conf.d/wifi-powersave.conf ] && sudo cp /etc/NetworkManager/conf.d/wifi-powersave.conf "$backup_dir/"
    [ -f /etc/modprobe.d/iwlwifi.conf ] && sudo cp /etc/modprobe.d/iwlwifi.conf "$backup_dir/"
    [ -f /etc/tlp.conf ] && sudo cp /etc/tlp.conf "$backup_dir/"
    
    # Create rollback script
    cat > "$backup_dir/rollback.sh" << 'EOF'
#!/bin/bash
echo "Rolling back WiFi power management fixes..."

# Remove our configs
sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave.conf
sudo rm -f /etc/NetworkManager/conf.d/no-wifi-powersave.conf
sudo rm -f /etc/modprobe.d/iwlwifi.conf

# Restore backups if they exist
BACKUP_DIR="$(dirname "$0")"
[ -f "$BACKUP_DIR/wifi-powersave.conf" ] && sudo cp "$BACKUP_DIR/wifi-powersave.conf" /etc/NetworkManager/conf.d/
[ -f "$BACKUP_DIR/iwlwifi.conf" ] && sudo cp "$BACKUP_DIR/iwlwifi.conf" /etc/modprobe.d/
[ -f "$BACKUP_DIR/tlp.conf" ] && sudo cp "$BACKUP_DIR/tlp.conf" /etc/

# Restart services
sudo systemctl restart NetworkManager
[ -f /etc/tlp.conf ] && sudo systemctl restart tlp

echo "Rollback completed. Please reboot to ensure all changes take effect."
EOF
    
    chmod +x "$backup_dir/rollback.sh"
    echo "$backup_dir"
}

# Fix NetworkManager WiFi power save
fix_networkmanager_powersave() {
    log "Fixing NetworkManager WiFi PowerSave..."
    
    # Remove conflicting configs
    sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave.conf 2>/dev/null
    sudo rm -f /etc/NetworkManager/conf.d/performance.conf 2>/dev/null
    
    # Create new safe config
    sudo tee /etc/NetworkManager/conf.d/no-wifi-powersave.conf > /dev/null << 'EOF'
[connection]
# Disable WiFi power save to prevent random disconnects
wifi.powersave = 2

[device]
# Disable MAC randomization that can cause issues
wifi.scan-rand-mac-address=no

# Faster connectivity checks
[connectivity]
uri = http://ping.archlinux.org
interval = 300
response = Arch Linux
EOF
    
    if [ $? -eq 0 ]; then
        success "NetworkManager WiFi PowerSave disabled"
        return 0
    else
        error "Failed to configure NetworkManager"
        return 1
    fi
}

# Fix iwlwifi kernel driver power save
fix_iwlwifi_powersave() {
    local driver=$(get_wifi_driver "$(get_wifi_interface)")
    
    if [ "$driver" = "iwlwifi" ]; then
        log "Fixing iwlwifi kernel driver PowerSave..."
        
        # Create iwlwifi config
        sudo tee /etc/modprobe.d/iwlwifi.conf > /dev/null << 'EOF'
# Disable iwlwifi power save to prevent WiFi disconnects
options iwlwifi power_save=0

# Additional stability options for iwlwifi
options iwlwifi led_mode=1
options iwlwifi swcrypto=0
EOF
        
        if [ $? -eq 0 ]; then
            success "iwlwifi PowerSave disabled"
            
            # Apply immediately (requires module reload)
            log "Reloading iwlwifi module..."
            sudo modprobe -r iwlwifi 2>/dev/null || true
            sudo modprobe iwlwifi power_save=0
            
            return 0
        else
            error "Failed to configure iwlwifi"
            return 1
        fi
    else
        log "Not using iwlwifi driver, skipping iwlwifi configuration"
        return 0
    fi
}

# Fix TLP WiFi power save
fix_tlp_powersave() {
    if command -v tlp >/dev/null 2>&1; then
        log "Fixing TLP WiFi PowerSave..."
        
        # Create TLP override config
        sudo mkdir -p /etc/tlp.conf.d
        sudo tee /etc/tlp.conf.d/99-wifi-fix.conf > /dev/null << 'EOF'
# WiFi Power Management Fix
# Disable WiFi power save to prevent random disconnects

# WiFi power save mode: on=enable, off=disable
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=off

# Disable USB autosuspend for WiFi adapters
USB_BLACKLIST_WWAN=1

# Runtime PM for PCIe bus devices: on=disable, auto=enable
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
EOF
        
        if [ $? -eq 0 ]; then
            success "TLP WiFi PowerSave disabled"
            
            # Restart TLP
            sudo systemctl restart tlp
            return 0
        else
            error "Failed to configure TLP"
            return 1
        fi
    else
        log "TLP not installed, skipping TLP configuration"
        return 0
    fi
}

# Additional stability fixes
apply_additional_fixes() {
    log "Applying additional WiFi stability fixes..."
    
    # Disable aggressive power management for all network devices
    sudo tee /etc/udev/rules.d/81-wifi-powersave.rules > /dev/null << 'EOF'
# Disable power management for all WiFi devices
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="/bin/sh -c 'echo off > /sys/class/net/%k/device/power/control'"

# Disable power management for USB WiFi adapters
ACTION=="add", SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="0e", RUN+="/bin/sh -c 'echo on > /sys/bus/usb/devices/%k/power/control'"
EOF
    
    success "Additional stability fixes applied"
}

# Test WiFi stability
test_wifi_stability() {
    log "Testing WiFi stability..."
    
    local interface=$(get_wifi_interface)
    
    if [ -n "$interface" ]; then
        # Test connectivity
        log "Testing connectivity to multiple targets..."
        
        local targets=("8.8.8.8" "1.1.1.1" "ping.archlinux.org")
        local success_count=0
        
        for target in "${targets[@]}"; do
            if ping -c 3 -W 5 "$target" >/dev/null 2>&1; then
                success "✅ Can reach $target"
                ((success_count++))
            else
                warning "❌ Cannot reach $target"
            fi
        done
        
        if [ $success_count -ge 2 ]; then
            success "WiFi connectivity test PASSED ($success_count/3 targets reachable)"
            return 0
        else
            error "WiFi connectivity test FAILED ($success_count/3 targets reachable)"
            return 1
        fi
    else
        error "No WiFi interface found for testing"
        return 1
    fi
}

# Show post-fix recommendations
show_recommendations() {
    echo ""
    log "Post-Fix Recommendations:"
    echo "────────────────────────────────────────"
    echo ""
    echo "🔄 Immediate Actions:"
    echo "  • Reboot to ensure all changes take effect"
    echo "  • Monitor WiFi stability for the next few hours"
    echo "  • Check if password prompts stop appearing"
    echo ""
    echo "📊 Monitoring Commands:"
    echo "  • Watch connection: watch -n 1 'nmcli device status'"
    echo "  • Check logs: sudo journalctl -u NetworkManager -f"
    echo "  • Power status: cat /sys/class/net/$(get_wifi_interface)/device/power/control"
    echo ""
    echo "🔧 If Issues Persist:"
    echo "  • Try different WiFi channels on your router"
    echo "  • Update WiFi drivers: sudo pacman -S linux-firmware"
    echo "  • Check router DHCP lease time (should be > 2 hours)"
    echo ""
    echo "🔙 Rollback:"
    echo "  • Use rollback script: $backup_dir/rollback.sh"
    echo ""
}

# Main fix function
apply_all_fixes() {
    local failed_fixes=()
    
    log "Applying comprehensive WiFi power management fixes..."
    echo ""
    
    # Create backup
    backup_dir=$(create_backup)
    success "Backup created: $backup_dir"
    
    # Apply fixes
    if fix_networkmanager_powersave; then
        success "✅ NetworkManager fix applied"
    else
        failed_fixes+=("NetworkManager")
    fi
    
    if fix_iwlwifi_powersave; then
        success "✅ iwlwifi driver fix applied"
    else
        failed_fixes+=("iwlwifi")
    fi
    
    if fix_tlp_powersave; then
        success "✅ TLP fix applied"
    else
        failed_fixes+=("TLP")
    fi
    
    if apply_additional_fixes; then
        success "✅ Additional stability fixes applied"
    else
        failed_fixes+=("Additional fixes")
    fi
    
    # Restart NetworkManager to apply changes
    log "Restarting NetworkManager..."
    if sudo systemctl restart NetworkManager; then
        success "NetworkManager restarted"
        sleep 3
        
        # Test stability
        if test_wifi_stability; then
            success "✅ WiFi stability test passed"
        else
            warning "⚠️ WiFi stability test failed - may need reboot"
        fi
    else
        error "Failed to restart NetworkManager"
        failed_fixes+=("NetworkManager restart")
    fi
    
    # Summary
    echo ""
    echo "WiFi Power Management Fix Summary:"
    echo "════════════════════════════════════"
    
    if [ ${#failed_fixes[@]} -eq 0 ]; then
        success "🎉 All fixes applied successfully!"
        echo ""
        echo "Your WiFi should now be stable and stop asking for passwords randomly."
    else
        warning "Some fixes had issues:"
        for fix in "${failed_fixes[@]}"; do
            echo "  ⚠️  $fix"
        done
    fi
    
    return 0
}

# Show logs for troubleshooting
show_logs() {
    log "Recent WiFi-related logs:"
    echo "────────────────────────────────────────"
    
    echo ""
    echo "🔍 NetworkManager logs (last 20 lines):"
    sudo journalctl -u NetworkManager -n 20 --no-pager
    
    echo ""
    echo "🔍 Kernel WiFi logs:"
    dmesg | grep -i -E "(wifi|wlan|iwl)" | tail -10
    
    echo ""
    echo "🔍 Power management events:"
    journalctl | grep -i -E "(suspend|resume|power)" | tail -5
}

# Interactive mode
interactive_mode() {
    echo "WiFi Power Management Fix Options:"
    echo "═════════════════════════════════════"
    echo "  [1] Apply all fixes (recommended)"
    echo "  [2] Show current WiFi status"
    echo "  [3] Show recent logs"
    echo "  [4] Test WiFi stability only"
    echo "  [0] Exit"
    echo ""
    
    read -p "Choose option: " choice
    
    case "$choice" in
        1)
            apply_all_fixes
            show_recommendations
            ;;
        2)
            show_wifi_status
            ;;
        3)
            show_logs
            ;;
        4)
            test_wifi_stability
            ;;
        0)
            log "Exiting..."
            exit 0
            ;;
        *)
            error "Invalid choice"
            return 1
            ;;
    esac
}

# Main function
main() {
    script_header
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Don't run this script as root!"
        exit 1
    fi
    
    # Check for required commands
    if ! command -v nmcli >/dev/null 2>&1; then
        error "NetworkManager not found! Please install networkmanager package."
        exit 1
    fi
    
    # Show current status first
    show_wifi_status
    
    # Run interactive mode
    interactive_mode
    
    echo ""
    log "WiFi Power Management Fix completed!"
}

# Run main function
main "$@"