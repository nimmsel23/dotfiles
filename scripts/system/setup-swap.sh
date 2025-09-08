#!/bin/bash

# Dedicated Swap Partition Setup Script
# Part of nimmsel23's dotfiles system scripts
# Usage: bash ~/.dotfiles/scripts/system/setup-swap.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Script-specific functions

# Detect available partitions
detect_partitions() {
    log "Detecting available partitions..."
    
    if ! command_exists lsblk; then
        error "lsblk command not found. Cannot detect partitions."
        return 1
    fi
    
    echo "Available storage devices:"
    sudo fdisk -l 2>/dev/null | grep "Disk /dev" | grep -E "(sd|nvme|mmc)"
    echo ""
    
    echo "Current partition table:"
    sudo fdisk -l 2>/dev/null | grep -E "^/dev/(sd|nvme|mmc)" | while read line; do
        dev=$(echo $line | awk '{print $1}')
        size=$(echo $line | awk '{print $4}')
        type=$(echo $line | awk '{print $6}')
        
        # Check if mounted
        mount_point=$(findmnt -n -o TARGET "$dev" 2>/dev/null || echo "unmounted")
        
        echo "  $dev ($size) [$type] → $mount_point"
    done
    echo ""
}

# Validate swap partition
validate_swap_partition() {
    local partition="$1"
    local errors=()
    
    # Check if partition exists
    if [ ! -b "/dev/$partition" ]; then
        errors+=("Partition /dev/$partition does not exist")
    fi
    
    # Check if mounted
    if mountpoint -q "/dev/$partition" 2>/dev/null; then
        errors+=("Partition is currently mounted")
    fi
    
    # Check if already swap
    if swapon --show=NAME 2>/dev/null | grep -q "/dev/$partition"; then
        errors+=("Partition is already active swap")
    fi
    
    # Check if partition is in use
    if sudo fuser "/dev/$partition" 2>/dev/null; then
        errors+=("Partition is in use by another process")
    fi
    
    # Check partition size (should be reasonable for swap)
    local size_bytes=$(sudo blockdev --getsize64 "/dev/$partition" 2>/dev/null || echo "0")
    local size_gb=$((size_bytes / 1024 / 1024 / 1024))
    
    if [ "$size_gb" -lt 1 ]; then
        errors+=("Partition too small for swap (${size_gb}GB)")
    elif [ "$size_gb" -gt 32 ]; then
        errors+=("Partition very large for swap (${size_gb}GB) - are you sure?")
    fi
    
    if [ ${#errors[@]} -gt 0 ]; then
        error "Validation failed:"
        for err in "${errors[@]}"; do
            echo "  ❌ $err"
        done
        return 1
    fi
    
    log "Partition validation passed (${size_gb}GB)"
    return 0
}

# Check existing swap configuration
check_existing_swap() {
    echo "Current swap configuration:"
    echo "──────────────────────────────"
    
    # Show current swap
    if swapon --show 2>/dev/null | grep -q .; then
        swapon --show
        echo ""
        
        # Check for specific types
        if swapon --show | grep -q zram; then
            warning "zram swap detected!"
            echo "You have zram active. Adding partition swap will work alongside it."
            read -p "Continue with both zram and partition swap? [y/N] " confirm
            [[ ! $confirm =~ ^[Yy]$ ]] && return 1
        fi
        
        if swapon --show | grep -q "/dev/"; then
            warning "Existing partition swap detected!"
            echo "You already have partition swap active."
            read -p "Continue to add another swap partition? [y/N] " confirm
            [[ ! $confirm =~ ^[Yy]$ ]] && return 1
        fi
    else
        echo "No active swap found"
    fi
    
    return 0
}

# Get partition UUID
get_partition_uuid() {
    local partition="$1"
    local uuid
    
    # Try multiple methods
    uuid=$(sudo blkid -s UUID -o value "/dev/$partition" 2>/dev/null)
    
    if [ -z "$uuid" ]; then
        # Fallback: force filesystem detection
        uuid=$(sudo blkid "/dev/$partition" 2>/dev/null | grep -o 'UUID="[^"]*"' | cut -d'"' -f2)
    fi
    
    echo "$uuid"
}

# Add swap to fstab
add_swap_to_fstab() {
    local uuid="$1"
    local fstab_entry="UUID=$uuid none swap defaults 0 0"
    
    # Backup fstab
    if ! safe_edit_file /etc/fstab; then
        return 1
    fi
    
    # Check if UUID already in fstab
    if grep -q "$uuid" /etc/fstab; then
        warning "UUID already in fstab, skipping"
        return 0
    fi
    
    # Add entry
    if echo "$fstab_entry" | sudo tee -a /etc/fstab > /dev/null; then
        success "Added swap entry to /etc/fstab"
    else
        error "Failed to update /etc/fstab"
        return 1
    fi
    
    # Validate fstab syntax
    if ! sudo mount -a --fake 2>/dev/null; then
        error "fstab syntax error, restoring backup"
        sudo cp /etc/fstab.dotfiles-backup-* /etc/fstab 2>/dev/null
        return 1
    fi
    
    return 0
}

# Main swap setup function
setup_swap_partition() {
    script_header "Swap Partition Setup" "Configure dedicated swap partition for your system"
    
    # Step 1: Check requirements
    log "Checking system requirements..."
    if ! check_requirements; then
        error "System requirements not met"
        return 1
    fi
    
    # Check if user has sufficient privileges
    if ! sudo -v; then
        error "Sudo privileges required for swap setup"
        return 1
    fi
    
    # Step 2: Show current state
    if ! check_existing_swap; then
        return 1
    fi
    
    # Step 3: Detect partitions
    if ! detect_partitions; then
        return 1
    fi
    
    # Step 4: Get user input with validation
    local swap_partition
    while true; do
        echo ""
        read -p "Enter swap partition (e.g., sda2, nvme0n1p3): " swap_partition
        
        if [ -z "$swap_partition" ]; then
            error "No partition specified"
            continue
        fi
        
        # Clean input
        swap_partition="${swap_partition#/dev/}"
        
        # Validate
        if validate_swap_partition "$swap_partition"; then
            break
        fi
        
        read -p "Try different partition? [y/N] " retry
        [[ ! $retry =~ ^[Yy]$ ]] && return 1
    done
    
    # Step 5: Final confirmation with details
    echo ""
    echo "⚠️  FINAL CONFIRMATION"
    echo "════════════════════════"
    echo "Partition: /dev/$swap_partition"
    sudo fdisk -l "/dev/$swap_partition" 2>/dev/null | head -5
    echo ""
    echo "This will:"
    echo "  1. Format /dev/$swap_partition as swap (DATA WILL BE LOST)"
    echo "  2. Enable swap immediately"  
    echo "  3. Add to /etc/fstab for permanent use"
    echo ""
    
    read -p "Type 'CONFIRM' to proceed: " final_confirm
    if [ "$final_confirm" != "CONFIRM" ]; then
        warning "Operation cancelled"
        return 1
    fi
    
    # Step 6: Execute with error handling
    log "Creating swap filesystem..."
    if ! sudo mkswap "/dev/$swap_partition"; then
        error "Failed to create swap filesystem"
        return 1
    fi
    
    log "Enabling swap..."
    if ! sudo swapon "/dev/$swap_partition"; then
        error "Failed to enable swap"
        return 1
    fi
    
    log "Getting UUID..."
    local uuid=$(get_partition_uuid "$swap_partition")
    if [ -z "$uuid" ]; then
        error "Failed to get UUID"
        sudo swapoff "/dev/$swap_partition" 2>/dev/null
        return 1
    fi
    
    log "Adding to fstab..."
    if ! add_swap_to_fstab "$uuid"; then
        error "Failed to update fstab"
        sudo swapoff "/dev/$swap_partition" 2>/dev/null
        return 1
    fi
    
    # Step 7: Verify everything works
    log "Verifying setup..."
    if ! swapon --show | grep -q "/dev/$swap_partition"; then
        error "Swap verification failed"
        return 1
    fi
    
    success "Swap setup completed successfully!"
    echo ""
    echo "📊 Current swap status:"
    swapon --show
    free -h | grep -i swap
    
    return 0
}

# Main execution
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    if setup_swap_partition; then
        script_footer "Swap partition setup completed"
    else
        error "Swap partition setup failed"
        script_footer
        exit 1
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi