#!/bin/bash

# Laptop Performance Tweaks Script
# Part of nimmsel23's dotfiles system scripts
# Optimized for IdeaPad Flex 5 with AMD Radeon
# Usage: bash ~/.dotfiles/scripts/system/performance-tweaks.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Performance tweak categories
declare -A TWEAK_CATEGORIES=(
    ["power_management"]="TLP power management and laptop optimization"
    ["kernel_params"]="Kernel parameters for better performance"
    ["amd_gpu"]="AMD GPU power management and optimization"
    ["network"]="Network stack optimizations (BBR, etc.)"
    ["storage"]="SSD and I/O optimizations"
    ["preload"]="Application preloading for faster startup"
)

# Install and configure TLP power management
setup_power_management() {
    log "Setting up TLP power management..."
    
    if ! install_packages tlp tlp-rdw powertop; then
        error "Failed to install power management packages"
        return 1
    fi
    
    # Enable and start TLP
    if sudo systemctl enable tlp && sudo systemctl start tlp; then
        success "TLP power management enabled"
    else
        error "Failed to enable TLP service"
        return 1
    fi
    
    # Install additional power tools
    if install_packages auto-cpufreq; then
        log "Enabling auto-cpufreq for better CPU scaling..."
        sudo systemctl enable auto-cpufreq --now
        success "auto-cpufreq enabled"
    else
        warning "auto-cpufreq installation failed (optional)"
    fi
    
    return 0
}

# Apply kernel parameters for performance
setup_kernel_params() {
    log "Applying performance kernel parameters..."
    
    local sysctl_file="/etc/sysctl.d/99-performance.conf"
    
    if [ -f "$sysctl_file" ]; then
        warning "Performance parameters already exist"
        read -p "Overwrite existing configuration? [y/N] " overwrite
        [[ ! $overwrite =~ ^[Yy]$ ]] && return 0
    fi
    
    # Backup existing file if present
    if [ -f "$sysctl_file" ]; then
        safe_edit_file "$sysctl_file"
    fi
    
    # Create optimized sysctl configuration
    sudo tee "$sysctl_file" > /dev/null << 'EOF'
# Performance tweaks for laptop with dedicated swap partition
# Optimized for IdeaPad Flex 5 with AMD Radeon

# Memory Management
# Lower swappiness - only use swap when really needed
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Dirty page handling optimized for SSD
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# Virtual memory optimizations
vm.overcommit_memory = 1
vm.overcommit_ratio = 50

# Network performance
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# I/O scheduler optimizations
# Disable scheduler autogroup for better responsiveness
kernel.sched_autogroup_enabled = 0

# Security optimizations that also improve performance
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 1
EOF
    
    if [ $? -eq 0 ]; then
        success "Performance kernel parameters applied"
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
    
    # Add AMD GPU parameters to GRUB
    local grub_file="/etc/default/grub"
    
    if ! grep -q "amdgpu.si_support=1" "$grub_file" 2>/dev/null; then
        log "Adding AMD GPU parameters to GRUB..."
        
        if safe_edit_file "$grub_file"; then
            # Add AMD GPU parameters
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&amdgpu.si_support=1 amdgpu.cik_support=1 /' "$grub_file"
            
            # Update GRUB configuration
            if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
                success "AMD GPU parameters added to GRUB"
            else
                warning "GRUB update failed, manual update may be required"
            fi
        else
            warning "Failed to backup GRUB config"
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

# Setup network optimizations
setup_network_optimizations() {
    log "Applying network optimizations..."
    
    # Network parameters are already included in kernel params
    # But let's ensure NetworkManager optimizations
    
    local nm_conf="/etc/NetworkManager/conf.d/performance.conf"
    
    if [ ! -f "$nm_conf" ]; then
        log "Creating NetworkManager performance configuration..."
        
        sudo tee "$nm_conf" > /dev/null << 'EOF'
[connection]
# Optimize WiFi power management
wifi.powersave = 2

[main]
# DNS optimization
dns = systemd-resolved

[connectivity]
# Faster connectivity checks
uri = http://ping.archlinux.org
interval = 300
EOF
        
        success "NetworkManager optimizations applied"
        
        # Restart NetworkManager to apply changes
        if sudo systemctl restart NetworkManager; then
            log "NetworkManager restarted"
        else
            warning "Failed to restart NetworkManager"
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
    
    if [ ! -f "$udev_rule" ]; then
        log "Setting up I/O scheduler rules..."
        
        if $is_ssd; then
            # SSD optimization
            sudo tee "$udev_rule" > /dev/null << 'EOF'
# Set deadline scheduler for SSDs
ACTION=="add|change", KERNEL=="sd[a-z]*|nvme*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# Set BFQ for HDDs
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
        else
            # HDD optimization
            sudo tee "$udev_rule" > /dev/null << 'EOF'
# Set BFQ scheduler for HDDs
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
# Set deadline for SSDs
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

# Apply all performance tweaks
apply_all_tweaks() {
    local failed_categories=()
    
    log "Applying all performance tweaks..."
    echo ""
    
    # Apply each category
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
            network)
                if setup_network_optimizations; then
                    success "✅ Network optimizations"
                else
                    failed_categories+=("network")
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
    
    # Summary
    echo "Performance Tweaks Summary:"
    echo "═══════════════════════════════"
    
    if [ ${#failed_categories[@]} -eq 0 ]; then
        success "All performance tweaks applied successfully!"
    else
        warning "Some tweaks had issues:"
        for category in "${failed_categories[@]}"; do
            echo "  ⚠️  $category"
        done
    fi
    
    return 0
}

# Interactive tweak selection
interactive_tweaks() {
    echo "Select performance tweaks to apply:"
    echo "═══════════════════════════════════"
    echo ""
    
    local categories=("power_management" "kernel_params" "amd_gpu" "network" "storage" "preload")
    local selected_categories=()
    
    # Show options with descriptions
    for i in "${!categories[@]}"; do
        local num=$((i + 1))
        local category="${categories[$i]}"
        local description="${TWEAK_CATEGORIES[$category]}"
        echo "  [$num] $category - $description"
    done
    echo "  [a] All tweaks"
    echo "  [0] Cancel"
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
    echo "Selected tweaks:"
    for category in "${selected_categories[@]}"; do
        local description="${TWEAK_CATEGORIES[$category]}"
        echo "  • $category - $description"
    done
    echo ""
    
    read -p "Apply these tweaks? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        warning "Performance tweaks cancelled"
        return 0
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
            network)
                if setup_network_optimizations; then
                    success "✅ Network optimizations"
                else
                    failed_categories+=("network")
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
    
    # Summary
    if [ ${#failed_categories[@]} -eq 0 ]; then
        success "All selected tweaks applied successfully!"
    else
        warning "Some tweaks had issues: ${failed_categories[*]}"
    fi
    
    return 0
}

# Show current system performance status
show_performance_status() {
    echo "Current Performance Status:"
    echo "═══════════════════════════════"
    echo ""
    
    # TLP status
    if systemctl is-active tlp >/dev/null 2>&1; then
        success "TLP power management: Active"
    else
        warning "TLP power management: Inactive"
    fi
    
    # Kernel parameters
    if [ -f /etc/sysctl.d/99-performance.conf ]; then
        success "Performance kernel parameters: Configured"
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
    echo "  • Check TLP status: sudo tlp-stat"
    echo "  • Monitor performance: btop or htop"
    echo ""
    echo "📊 Performance Monitoring:"
    echo "  • GPU monitoring: radeontop (if AMD GPU tools installed)"
    echo "  • Power usage: powertop"
    echo "  • I/O performance: iotop"
    echo ""
    echo "⚙️  Fine-tuning:"
    echo "  • TLP configuration: /etc/tlp.conf"
    echo "  • Kernel parameters: /etc/sysctl.d/99-performance.conf"
    echo "  • GRUB parameters: /etc/default/grub"
    echo ""
    echo "🔋 Battery Optimization:"
    echo "  • TLP automatically optimizes for AC/battery"
    echo "  • Manual power profile: sudo tlp ac/bat"
    echo "  • Check battery health: upower -i /org/freedesktop/UPower/devices/BAT0"
    echo ""
    
    read -p "Reboot now to activate all optimizations? [y/N] " reboot_confirm
    if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
        log "Rebooting system..."
        sudo reboot
    fi
}

# Main performance tweaks function
main_tweaks() {
    script_header "Laptop Performance Tweaks" "Optimize your IdeaPad Flex 5 for better performance and battery life"
    
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
    echo "Performance Optimization Options:"
    echo "═══════════════════════════════════"
    echo "  [1] Apply all performance tweaks (recommended)"
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
        script_footer "Performance tweaks completed"
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