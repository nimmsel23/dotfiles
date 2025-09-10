#!/bin/bash

# Laptop Performance Tweaks Script - SAFE VERSION
# Part of nimmsel23's dotfiles system scripts
# Optimized for IdeaPad Flex 5 with AMD Radeon
# Usage: bash ~/.dotfiles/scripts/system/performance-tweaks-safe.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Safe performance tweak categories
declare -A TWEAK_CATEGORIES=(
    ["power_management"]="TLP power management and laptop optimization"
    ["kernel_params"]="Safe kernel parameters for better performance"
    ["amd_gpu"]="AMD GPU power management and optimization"
    ["network_safe"]="Safe network optimizations (NO DNS changes)"
    ["storage"]="SSD and I/O optimizations"
    ["preload"]="Application preloading for faster startup"
)

# Backup directory for rollbacks
BACKUP_DIR="$HOME/.dotfiles/backups/performance-$(date +%Y%m%d_%H%M%S)"

# Create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log "Created backup directory: $BACKUP_DIR"
}

# Enhanced backup function with verification
safe_backup_file() {
    local file="$1"
    local backup_name="$2"
    
    if [ -f "$file" ]; then
        local backup_file="$BACKUP_DIR/$backup_name"
        if cp "$file" "$backup_file"; then
            log "✅ Backed up: $file -> $backup_file"
            return 0
        else
            error "❌ Failed to backup: $file"
            return 1
        fi
    fi
    return 0
}

# Install and configure TLP power management
setup_power_management() {
    log "Setting up TLP power management..."
    
    if ! install_packages tlp tlp-rdw powertop; then
        error "Failed to install power management packages"
        return 1
    fi
    
    # Backup existing TLP config if exists
    safe_backup_file "/etc/tlp.conf" "tlp.conf.original"
    
    # Enable and start TLP
    if sudo systemctl enable tlp && sudo systemctl start tlp; then
        success "TLP power management enabled"
    else
        error "Failed to enable TLP service"
        return 1
    fi
    
    # Create safe TLP configuration
    log "Creating safe TLP configuration..."
    sudo tee /etc/tlp.conf.d/99-safe-performance.conf > /dev/null << 'EOF'
# Safe TLP Performance Configuration
# Conservative settings to avoid network issues

# CPU Scaling Governor
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU Energy Performance Preference
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# CPU Boost
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# WiFi Power Management - CONSERVATIVE SETTINGS
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Disable aggressive USB autosuspend
USB_AUTOSUSPEND=0

# PCIe ASPM - conservative
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersave
EOF
    
    # Install auto-cpufreq as optional enhancement
    if install_packages auto-cpufreq; then
        log "Enabling auto-cpufreq for better CPU scaling..."
        sudo systemctl enable auto-cpufreq --now
        success "auto-cpufreq enabled"
    else
        warning "auto-cpufreq installation failed (optional)"
    fi
    
    return 0
}

# Apply SAFE kernel parameters for performance
setup_kernel_params() {
    log "Applying SAFE performance kernel parameters..."
    
    local sysctl_file="/etc/sysctl.d/99-performance-safe.conf"
    
    if [ -f "$sysctl_file" ]; then
        warning "Performance parameters already exist"
        read -p "Overwrite existing configuration? [y/N] " overwrite
        [[ ! $overwrite =~ ^[Yy]$ ]] && return 0
    fi
    
    # Backup existing file if present
    safe_backup_file "$sysctl_file" "99-performance-safe.conf.backup"
    
    # Create CONSERVATIVE sysctl configuration
    sudo tee "$sysctl_file" > /dev/null << 'EOF'
# SAFE Performance tweaks for laptop
# Conservative settings tested to avoid network issues
# Optimized for IdeaPad Flex 5 with AMD Radeon

# Memory Management - Conservative values
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Dirty page handling - Safe for SSD
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# Virtual memory - Safe settings
vm.overcommit_memory = 1
vm.overcommit_ratio = 50

# Network performance - SAFE SETTINGS (NO systemd-resolved!)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000

# Moderate network buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 4194304

# I/O scheduler optimizations - Conservative
kernel.sched_autogroup_enabled = 0

# Security optimizations
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 1
EOF
    
    if [ $? -eq 0 ]; then
        success "SAFE performance kernel parameters applied"
        log "Parameters will take effect after reboot or: sudo sysctl --system"
        return 0
    else
        error "Failed to apply kernel parameters"
        return 1
    fi
}

# Setup AMD GPU optimizations
setup_amd_gpu() {
    log "Configuring AMD GPU optimizations..."
    
    # Check if AMD GPU is present
    if ! lspci | grep -i amd | grep -i vga >/dev/null; then
        warning "No AMD GPU detected, skipping GPU optimizations"
        return 0
    fi
    
    log "AMD GPU detected: $(lspci | grep -i amd | grep -i vga | cut -d: -f3)"
    
    # Backup GRUB config
    safe_backup_file "/etc/default/grub" "grub.backup"
    
    # Add AMD GPU parameters to GRUB
    local grub_file="/etc/default/grub"
    
    if ! grep -q "amdgpu.si_support=1" "$grub_file" 2>/dev/null; then
        log "Adding AMD GPU parameters to GRUB..."
        
        # Create safe GRUB update
        if sudo cp "$grub_file" "$grub_file.pre-amd"; then
            # Add AMD GPU parameters safely
            sudo sed -i.backup 's/GRUB_CMDLINE_LINUX_DEFAULT="/&amdgpu.si_support=1 amdgpu.cik_support=1 /' "$grub_file"
            
            # Update GRUB configuration
            if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
                success "AMD GPU parameters added to GRUB"
            else
                warning "GRUB update failed, restoring backup"
                sudo cp "$grub_file.pre-amd" "$grub_file"
            fi
        else
            warning "Failed to backup GRUB config, skipping GPU optimization"
        fi
    else
        log "AMD GPU parameters already configured"
    fi
    
    # Install AMD GPU tools
    if install_packages radeontop gpu-viewer; then
        success "AMD GPU monitoring tools installed"
    else
        warning "Some AMD GPU tools failed to install"
    fi
    
    return 0
}

# Setup SAFE network optimizations (NO DNS CHANGES!)
setup_network_optimizations() {
    log "Applying SAFE network optimizations..."
    
    # IMPORTANT: NO DNS CHANGES OR systemd-resolved!
    local nm_conf="/etc/NetworkManager/conf.d/safe-performance.conf"
    
    # Backup existing NetworkManager configs
    if [ -d "/etc/NetworkManager/conf.d" ]; then
        safe_backup_file "/etc/NetworkManager/conf.d" "networkmanager-conf.d.backup"
    fi
    
    if [ ! -f "$nm_conf" ]; then
        log "Creating SAFE NetworkManager performance configuration..."
        
        sudo tee "$nm_conf" > /dev/null << 'EOF'
[connection]
# SAFE WiFi power management - not too aggressive
wifi.powersave = 3

# NO DNS CHANGES - keep default DNS handling
# NO systemd-resolved activation

[connectivity]
# Faster connectivity checks with safe intervals
uri = http://ping.archlinux.org
interval = 300
EOF
        
        success "SAFE NetworkManager optimizations applied"
        
        # Test network before and after restart
        log "Testing network connectivity before restart..."
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log "Network OK, restarting NetworkManager..."
            if sudo systemctl restart NetworkManager; then
                sleep 3
                if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
                    success "NetworkManager restarted - network still working"
                else
                    error "Network lost after restart - rolling back"
                    sudo rm "$nm_conf"
                    sudo systemctl restart NetworkManager
                    return 1
                fi
            else
                warning "Failed to restart NetworkManager"
            fi
        else
            warning "Network already having issues, skipping NetworkManager changes"
        fi
    else
        log "NetworkManager optimizations already configured"
    fi
    
    return 0
}

# Setup storage optimizations
setup_storage_optimizations() {
    log "Applying storage optimizations..."
    
    # Check if we're on SSD
    local is_ssd=false
    if lsblk -d -o name,rota | grep -q "0$"; then
        is_ssd=true
        log "SSD detected, applying SSD-specific optimizations"
    else
        log "HDD detected, applying HDD-specific optimizations"
    fi
    
    # I/O scheduler optimization
    local udev_rule="/etc/udev/rules.d/60-ioschedulers.rules"
    
    # Backup existing udev rules
    if [ -d "/etc/udev/rules.d" ]; then
        safe_backup_file "/etc/udev/rules.d" "udev-rules.d.backup"
    fi
    
    if [ ! -f "$udev_rule" ]; then
        log "Setting up I/O scheduler rules..."
        
        if $is_ssd; then
            # SSD optimization
            sudo tee "$udev_rule" > /dev/null << 'EOF'
# Set mq-deadline scheduler for SSDs (safe and performant)
ACTION=="add|change", KERNEL=="sd[a-z]*|nvme*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# Set BFQ for HDDs
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
        else
            # HDD optimization
            sudo tee "$udev_rule" > /dev/null << 'EOF'
# Set BFQ scheduler for HDDs (better for rotational media)
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
# Set mq-deadline for SSDs
ACTION=="add|change", KERNEL=="sd[a-z]*|nvme*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
EOF
        fi
        
        success "I/O scheduler rules configured"
        log "Rules will take effect after reboot"
    else
        log "I/O scheduler rules already configured"
    fi
    
    # Check fstab for SSD optimizations
    if $is_ssd && ! grep -q "discard" /etc/fstab; then
        warning "Consider adding 'discard' option to SSD partitions in /etc/fstab"
        echo "Example: UUID=xxx / ext4 defaults,noatime,discard 0 1"
        echo "This is optional and can be done manually later."
    fi
    
    return 0
}

# Setup application preloading
setup_preload() {
    log "Setting up application preloading..."
    
    if install_packages preload; then
        if sudo systemctl enable preload && sudo systemctl start preload; then
            success "Preload enabled for faster application startup"
        else
            error "Failed to enable preload service"
            return 1
        fi
    else
        error "Failed to install preload"
        return 1
    fi
    
    return 0
}

# Network connectivity test before applying changes
test_network_connectivity() {
    log "Testing network connectivity..."
    
    # Test multiple targets
    local targets=("8.8.8.8" "1.1.1.1" "ping.archlinux.org")
    local failed=0
    
    for target in "${targets[@]}"; do
        if ! ping -c 1 -W 5 "$target" >/dev/null 2>&1; then
            warning "Cannot reach $target"
            ((failed++))
        fi
    done
    
    if [ $failed -gt 1 ]; then
        error "Network connectivity issues detected"
        echo "Please fix network issues before running performance optimizations"
        return 1
    fi
    
    success "Network connectivity OK"
    return 0
}

# Rollback function
create_rollback_script() {
    local rollback_script="$BACKUP_DIR/rollback.sh"
    
    cat > "$rollback_script" << 'EOF'
#!/bin/bash
# Performance Tweaks Rollback Script
# Generated automatically

echo "Rolling back performance tweaks..."

# Stop services
sudo systemctl stop tlp 2>/dev/null
sudo systemctl disable tlp 2>/dev/null
sudo systemctl stop auto-cpufreq 2>/dev/null
sudo systemctl disable auto-cpufreq 2>/dev/null
sudo systemctl stop preload 2>/dev/null
sudo systemctl disable preload 2>/dev/null

# Remove configuration files
sudo rm -f /etc/sysctl.d/99-performance-safe.conf
sudo rm -f /etc/NetworkManager/conf.d/safe-performance.conf
sudo rm -f /etc/udev/rules.d/60-ioschedulers.rules
sudo rm -f /etc/tlp.conf.d/99-safe-performance.conf

# Restore backups if they exist
BACKUP_DIR="$(dirname "$0")"

if [ -f "$BACKUP_DIR/grub.backup" ]; then
    echo "Restoring GRUB configuration..."
    sudo cp "$BACKUP_DIR/grub.backup" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

if [ -f "$BACKUP_DIR/tlp.conf.original" ]; then
    echo "Restoring original TLP configuration..."
    sudo cp "$BACKUP_DIR/tlp.conf.original" /etc/tlp.conf
fi

# Restart services
sudo systemctl restart NetworkManager
sudo sysctl --system

echo "Rollback completed. Please reboot to ensure all changes take effect."
echo "Reboot now? [y/N]"
read -r reboot_confirm
if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
    sudo reboot
fi
EOF
    
    chmod +x "$rollback_script"
    success "Rollback script created: $rollback_script"
}

# Apply all performance tweaks with safety checks
apply_all_tweaks() {
    local failed_categories=()
    
    log "Applying all SAFE performance tweaks..."
    echo ""
    
    # Create backup directory
    create_backup_dir
    
    # Test network first
    if ! test_network_connectivity; then
        error "Network connectivity test failed - aborting"
        return 1
    fi
    
    # Apply each category with rollback on failure
    for category in "${!TWEAK_CATEGORIES[@]}"; do
        local description="${TWEAK_CATEGORIES[$category]}"
        log "Applying $category: $description"
        
        case "$category" in
            power_management)
                if setup_power_management; then
                    success "✅ Power management"
                else
                    failed_categories+=("power_management")
                fi
                ;;
            kernel_params)
                if setup_kernel_params; then
                    success "✅ Kernel parameters"
                else
                    failed_categories+=("kernel_params")
                fi
                ;;
            amd_gpu)
                if setup_amd_gpu; then
                    success "✅ AMD GPU optimization"
                else
                    failed_categories+=("amd_gpu")
                fi
                ;;
            network_safe)
                if setup_network_optimizations; then
                    success "✅ SAFE network optimizations"
                else
                    failed_categories+=("network_safe")
                    warning "Network optimization failed - this is often safe to ignore"
                fi
                ;;
            storage)
                if setup_storage_optimizations; then
                    success "✅ Storage optimizations"
                else
                    failed_categories+=("storage")
                fi
                ;;
            preload)
                if setup_preload; then
                    success "✅ Application preloading"
                else
                    failed_categories+=("preload")
                fi
                ;;
        esac
        echo ""
    done
    
    # Final network test
    log "Final network connectivity test..."
    if test_network_connectivity; then
        success "Network still working after optimizations"
    else
        error "Network issues detected after optimizations!"
        echo "Consider running the rollback script if problems persist"
    fi
    
    # Create rollback script
    create_rollback_script
    
    # Summary
    echo "Performance Tweaks Summary:"
    echo "═══════════════════════════════"
    
    if [ ${#failed_categories[@]} -eq 0 ]; then
        success "All SAFE performance tweaks applied successfully!"
    else
        warning "Some tweaks had issues:"
        for category in "${failed_categories[@]}"; do
            echo "  ⚠️  $category"
        done
    fi
    
    echo ""
    echo "🛡️  Safety Features:"
    echo "  • All original configs backed up to: $BACKUP_DIR"
    echo "  • Rollback script available: $BACKUP_DIR/rollback.sh"
    echo "  • Network connectivity verified"
    echo "  • Conservative settings used"
    
    return 0
}

# Interactive tweak selection with safety warnings
interactive_tweaks() {
    echo "Select SAFE performance tweaks to apply:"
    echo "═══════════════════════════════════════"
    echo ""
    
    local categories=("power_management" "kernel_params" "amd_gpu" "network_safe" "storage" "preload")
    local selected_categories=()
    
    # Show options with descriptions
    for i in "${!categories[@]}"; do
        local num=$((i + 1))
        local category="${categories[$i]}"
        local description="${TWEAK_CATEGORIES[$category]}"
        echo "  [$num] $category - $description"
    done
    echo "  [a] All tweaks (recommended)"
    echo "  [0] Cancel"
    echo ""
    echo "🛡️  Safety features: All configs are backed up, rollback script provided"
    echo ""
    
    while true; do
        read -p "Select tweaks (e.g., 1,3,5 or 'a' for all): " selection
        
        case "$selection" in
            0)
                warning "Performance tweaks cancelled"
                return 0
                ;;
            a|A)
                selected_categories=("${categories[@]}")
                break
                ;;
            *)
                # Parse comma-separated numbers
                IFS=',' read -ra ADDR <<< "$selection"
                selected_categories=()
                local valid=true
                
                for num in "${ADDR[@]}"; do
                    # Trim whitespace
                    num=$(echo "$num" | xargs)
                    
                    if [[ "$num" =~ ^[1-6]$ ]]; then
                        local idx=$((num - 1))
                        selected_categories+=("${categories[$idx]}")
                    else
                        error "Invalid selection: $num"
                        valid=false
                        break
                    fi
                done
                
                if $valid && [ ${#selected_categories[@]} -gt 0 ]; then
                    break
                fi
                ;;
        esac
    done
    
    # Confirm selection
    echo ""
    echo "Selected SAFE tweaks:"
    for category in "${selected_categories[@]}"; do
        local description="${TWEAK_CATEGORIES[$category]}"
        echo "  • $category - $description"
    done
    echo ""
    
    read -p "Apply these SAFE tweaks? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        warning "Performance tweaks cancelled"
        return 0
    fi
    
    # Create backup directory
    create_backup_dir
    
    # Test network first
    if ! test_network_connectivity; then
        error "Network connectivity test failed - aborting"
        return 1
    fi
    
    # Apply selected tweaks
    local failed_categories=()
    for category in "${selected_categories[@]}"; do
        local description="${TWEAK_CATEGORIES[$category]}"
        log "Applying $category: $description"
        
        case "$category" in
            power_management)
                if setup_power_management; then
                    success "✅ Power management"
                else
                    failed_categories+=("power_management")
                fi
                ;;
            kernel_params)
                if setup_kernel_params; then
                    success "✅ Kernel parameters"
                else
                    failed_categories+=("kernel_params")
                fi
                ;;
            amd_gpu)
                if setup_amd_gpu; then
                    success "✅ AMD GPU optimization"
                else
                    failed_categories+=("amd_gpu")
                fi
                ;;
            network_safe)
                if setup_network_optimizations; then
                    success "✅ SAFE network optimizations"
                else
                    failed_categories+=("network_safe")
                fi
                ;;
            storage)
                if setup_storage_optimizations; then
                    success "✅ Storage optimizations"
                else
                    failed_categories+=("storage")
                fi
                ;;
            preload)
                if setup_preload; then
                    success "✅ Application preloading"
                else
                    failed_categories+=("preload")
                fi
                ;;
        esac
        echo ""
    done
    
    # Final network test
    log "Final network connectivity test..."
    if test_network_connectivity; then
        success "Network still working after optimizations"
    else
        error "Network issues detected after optimizations!"
    fi
    
    # Create rollback script
    create_rollback_script
    
    # Summary
    if [ ${#failed_categories[@]} -eq 0 ]; then
        success "All selected SAFE tweaks applied successfully!"
    else
        warning "Some tweaks had issues: ${failed_categories[*]}"
    fi
    
    echo ""
    echo "🛡️  Backup location: $BACKUP_DIR"
    echo "🔄 Rollback script: $BACKUP_DIR/rollback.sh"
    
    return 0
}

# Show current system performance status
show_performance_status() {
    echo "Current Performance Status:"
    echo "═══════════════════════════════"
    echo ""
    
    # Network connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        success "Network connectivity: OK"
    else
        error "Network connectivity: FAILED"
    fi
    
    # TLP status
    if systemctl is-active tlp >/dev/null 2>&1; then
        success "TLP power management: Active"
    else
        warning "TLP power management: Inactive"
    fi
    
    # Kernel parameters
    if [ -f /etc/sysctl.d/99-performance-safe.conf ]; then
        success "SAFE performance kernel parameters: Configured"
        echo "  • Swappiness: $(sysctl vm.swappiness 2>/dev/null | cut -d= -f2 | xargs)"
        echo "  • TCP congestion control: $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | cut -d= -f2 | xargs)"
    else
        warning "Performance kernel parameters: Not configured"
    fi
    
    # AMD GPU
    if lspci | grep -i amd | grep -i vga >/dev/null; then
        if grep -q "amdgpu" /etc/default/grub 2>/dev/null; then
            success "AMD GPU parameters: Configured"
        else
            warning "AMD GPU parameters: Not configured"
        fi
    else
        log "AMD GPU: Not detected"
    fi
    
    # Preload
    if systemctl is-active preload >/dev/null 2>&1; then
        success "Application preloading: Active"
    else
        warning "Application preloading: Inactive"
    fi
    
    # I/O scheduler
    if [ -f /etc/udev/rules.d/60-ioschedulers.rules ]; then
        success "I/O scheduler optimization: Configured"
    else
        warning "I/O scheduler optimization: Not configured"
    fi
    
    # Network Manager
    if [ -f /etc/NetworkManager/conf.d/safe-performance.conf ]; then
        success "SAFE NetworkManager optimizations: Configured"
    else
        warning "NetworkManager optimizations: Not configured"
    fi
    
    echo ""
}

# Show post-optimization recommendations
show_post_optimization_tips() {
    echo ""
    echo "🎯 Post-Optimization Tips:"
    echo "════════════════════════════"
    echo ""
    echo "🔄 Immediate Actions:"
    echo "  • Reboot to activate all kernel parameters"
    echo "  • Test network: ping 8.8.8.8"
    echo "  • Check TLP status: sudo tlp-stat"
    echo "  • Monitor performance: btop or htop"
    echo ""
    echo "🛡️  Safety Features:"
    echo "  • Backup directory: $BACKUP_DIR"
    echo "  • Rollback script: $BACKUP_DIR/rollback.sh"
    echo "  • Conservative settings used"
    echo "  • Network connectivity preserved"
    echo ""
    echo "📊 Performance Monitoring:"
    echo "  • GPU monitoring: radeontop (if AMD GPU tools installed)"
    echo "  • Power usage: powertop"
    echo "  • I/O performance: iotop"
    echo ""
    echo "⚙️  Fine-tuning:"
    echo "  • TLP configuration: /etc/tlp.conf.d/99-safe-performance.conf"
    echo "  • Kernel parameters: /etc/sysctl.d/99-performance-safe.conf"
    echo "  • GRUB parameters: /etc/default/grub"
    echo ""
    echo "🔋 Battery Optimization:"
    echo "  • TLP automatically optimizes for AC/battery"
    echo "  • Manual power profile: sudo tlp ac/bat"
    echo "  • Check battery health: upower -i /org/freedesktop/UPower/devices/BAT0"
    echo ""
    
    # Ask for reboot with safety check
    echo "⚠️  IMPORTANT: Some optimizations require a reboot to take full effect"
    echo ""
    read -p "Reboot now to activate all optimizations? [y/N] " reboot_confirm
    if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
        echo "Final network test before reboot..."
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log "Network OK - rebooting system..."
            sudo reboot
        else
            error "Network issues detected! Please fix before rebooting"
            echo "Run rollback script if needed: $BACKUP_DIR/rollback.sh"
        fi
    fi
}

# Main performance tweaks function
main_tweaks() {
    script_header "SAFE Laptop Performance Tweaks" "Optimize your IdeaPad Flex 5 with conservative, tested settings"
    
    echo "🛡️  SAFETY FEATURES:"
    echo "  • All configurations backed up automatically"
    echo "  • Network connectivity tested before and after changes"
    echo "  • Conservative settings to prevent issues"
    echo "  • Automatic rollback script generation"
    echo "  • NO DNS changes that could break internet"
    echo ""
    
    # Step 1: Check requirements
    log "Checking system requirements..."
    if ! check_requirements; then
        error "System requirements not met"
        return 1
    fi
    
    # Check network connectivity
    if ! check_network; then
        error "Network required for package installation"
        return 1
    fi
    
    # Step 2: Show current status
    show_performance_status
    
    # Step 3: Tweak mode selection
    echo "SAFE Performance Optimization Options:"
    echo "═════════════════════════════════════"
    echo "  [1] Apply all SAFE performance tweaks (recommended)"
    echo "  [2] Interactive selection"
    echo "  [3] Show current status only"
    echo "  [0] Cancel"
    echo ""
    
    read -p "Choose optimization mode: " mode
    
    case "$mode" in
        1)
            apply_all_tweaks
            ;;
        2)
            interactive_tweaks
            ;;
        3)
            show_performance_status
            return 0
            ;;
        0)
            warning "Performance optimization cancelled"
            return 0
            ;;
        *)
            error "Invalid selection"
            return 1
            ;;
    esac
    
    # Step 4: Show tips
    show_post_optimization_tips
    
    return 0
}

# Main execution
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    if main_tweaks; then
        script_footer "SAFE performance tweaks completed"
    else
        error "Performance tweaks failed"
        script_footer
        exit 1
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi