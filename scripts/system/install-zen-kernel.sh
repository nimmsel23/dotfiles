#!/bin/bash

# Linux-zen Kernel Installation Script
# Part of nimmsel23's dotfiles system scripts
# Usage: bash ~/.dotfiles/scripts/system/install-zen-kernel.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Check current kernel information
show_kernel_info() {
    echo "Current system information:"
    echo "──────────────────────────────"
    echo "Current kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
    
    echo "Installed kernels:"
    if ls /boot/vmlinuz-* >/dev/null 2>&1; then
        ls /boot/vmlinuz-* 2>/dev/null | sed 's/\/boot\/vmlinuz-/  • /' | sort
    else
        echo "  • No kernels found in /boot"
    fi
    echo ""
}

# Explain linux-zen benefits
explain_zen_benefits() {
    echo "Linux-zen kernel benefits:"
    echo "────────────────────────────"
    echo "• Lower latency for desktop/gaming performance"
    echo "• Better responsiveness and interactivity"
    echo "• Advanced scheduler (MuQSS) for better multitasking"
    echo "• Latest features backported from mainline"
    echo "• Optimized for desktop/laptop usage"
    echo "• Better performance for AMD GPUs"
    echo ""
    echo "Perfect for your IdeaPad Flex 5 with AMD Radeon!"
    echo ""
}

# Check if zen kernel is already installed
check_zen_installed() {
    if pacman -Qi linux-zen >/dev/null 2>&1; then
        warning "Linux-zen is already installed"
        echo "Current zen version: $(pacman -Q linux-zen 2>/dev/null | awk '{print $2}')"
        echo ""
        read -p "Reinstall/update anyway? [y/N] " confirm
        [[ ! $confirm =~ ^[Yy]$ ]] && return 1
    fi
    return 0
}

# Install zen kernel and headers
install_zen_kernel() {
    log "Installing linux-zen kernel and headers..."
    
    local packages=("linux-zen" "linux-zen-headers")
    
    if install_packages "${packages[@]}"; then
        success "Linux-zen kernel installed successfully"
        return 0
    else
        error "Failed to install linux-zen kernel"
        return 1
    fi
}

# Update GRUB configuration
update_grub_config() {
    log "Updating GRUB configuration..."
    
    # Check if GRUB is the bootloader
    if [ ! -f /boot/grub/grub.cfg ]; then
        warning "GRUB not found. You may be using systemd-boot or another bootloader."
        echo "Manual bootloader configuration may be required."
        return 0
    fi
    
    # Backup GRUB config
    if ! safe_edit_file /boot/grub/grub.cfg; then
        warning "Failed to backup GRUB config"
    fi
    
    # Update GRUB
    if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
        success "GRUB configuration updated"
        return 0
    else
        error "Failed to update GRUB configuration"
        echo "You may need to update manually after reboot"
        return 1
    fi
}

# Show post-installation information
show_post_install_info() {
    echo ""
    echo "📋 Post-installation information:"
    echo "════════════════════════════════"
    
    echo "Installed kernels:"
    if ls /boot/vmlinuz-* >/dev/null 2>&1; then
        ls /boot/vmlinuz-* 2>/dev/null | sed 's/\/boot\/vmlinuz-/  • /' | sort
        echo ""
    fi
    
    echo "Current kernel: $(uname -r)"
    echo ""
    
    echo "💡 Next steps:"
    echo "  1. Reboot your system"
    echo "  2. Select 'linux-zen' in GRUB boot menu"
    echo "  3. Enjoy improved performance!"
    echo ""
    
    if command_exists grub-reboot; then
        echo "🚀 Advanced: You can set zen as next boot kernel with:"
        echo "  sudo grub-reboot 'Arch Linux, with Linux linux-zen'"
        echo ""
    fi
    
    read -p "Reboot now to use zen kernel? [y/N] " reboot_confirm
    if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
        log "Rebooting system..."
        sudo reboot
    fi
}

# Remove old kernels (optional cleanup)
cleanup_old_kernels() {
    echo ""
    read -p "Remove old kernel packages to save space? [y/N] " cleanup_confirm
    
    if [[ $cleanup_confirm =~ ^[Yy]$ ]]; then
        log "Checking for old kernels to remove..."
        
        # List installed kernels
        local installed_kernels
        installed_kernels=$(pacman -Q | grep -E '^linux(-lts|-hardened)? ' | awk '{print $1}')
        
        if [ -n "$installed_kernels" ]; then
            echo "Found old kernels:"
            echo "$installed_kernels" | sed 's/^/  • /'
            echo ""
            
            read -p "Remove these old kernels? [y/N] " remove_confirm
            if [[ $remove_confirm =~ ^[Yy]$ ]]; then
                # Convert to array and remove
                local kernels_array=($installed_kernels)
                for kernel in "${kernels_array[@]}"; do
                    if [[ $kernel != "linux-zen" ]]; then
                        log "Removing $kernel..."
                        if sudo pacman -R --noconfirm "$kernel" "${kernel}-headers" 2>/dev/null; then
                            success "Removed $kernel"
                        else
                            warning "Failed to remove $kernel (may not have headers)"
                        fi
                    fi
                done
                
                # Update GRUB after removal
                update_grub_config
            fi
        else
            log "No old kernels found to remove"
        fi
    fi
}

# Main zen kernel installation function
main_install() {
    script_header "Linux-zen Kernel Installation" "Install high-performance desktop kernel"
    
    # Step 1: Check requirements
    log "Checking system requirements..."
    if ! check_requirements; then
        error "System requirements not met"
        return 1
    fi
    
    # Check network connectivity
    if ! check_network; then
        error "Network required for kernel installation"
        return 1
    fi
    
    # Check disk space
    if ! check_disk_space; then
        return 1
    fi
    
    # Step 2: Show current kernel info
    show_kernel_info
    
    # Step 3: Explain benefits
    explain_zen_benefits
    
    # Step 4: Check if already installed
    if ! check_zen_installed; then
        return 0
    fi
    
    # Step 5: Confirm installation
    read -p "Install linux-zen kernel? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        warning "Installation cancelled"
        return 0
    fi
    
    # Step 6: Install kernel
    if ! install_zen_kernel; then
        return 1
    fi
    
    # Step 7: Update bootloader
    update_grub_config
    
    # Step 8: Optional cleanup
    cleanup_old_kernels
    
    # Step 9: Show post-install info
    show_post_install_info
    
    return 0
}

# Main execution
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    if main_install; then
        script_footer "Linux-zen kernel installation completed"
    else
        error "Linux-zen kernel installation failed"
        script_footer
        exit 1
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi