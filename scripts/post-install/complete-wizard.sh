#!/bin/bash

# Complete Post-Install Wizard Script
# Part of nimmsel23's dotfiles post-install scripts
# One-click system setup for IdeaPad Flex 5 with AMD Radeon
# Usage: bash ~/.dotfiles/scripts/post-install/complete-wizard.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Wizard configuration
declare -A WIZARD_STEPS=(
    ["system_update"]="Update system packages (pacman + AUR)"
    ["zen_kernel"]="Install linux-zen kernel for better performance"
    ["amd_gpu"]="Setup AMD GPU optimization"
    ["performance"]="Apply laptop performance tweaks"
    ["essential_apps"]="Install essential applications"
    ["development"]="Setup development environment (optional)"
    ["study_env"]="Setup study environment for Vitaltrainer"
    ["final_config"]="Apply final configurations and cleanup"
)

# Step tracking
declare -a COMPLETED_STEPS=()
declare -a FAILED_STEPS=()
declare -a SKIPPED_STEPS=()

# Pre-flight checks
run_preflight_checks() {
    log "Running comprehensive pre-flight checks..."
    
    local checks_passed=true
    
    # Check if running as root (bad idea)
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root!"
        return 1
    fi
    
    # Check system requirements
    if ! check_requirements; then
        error "System requirements not met"
        checks_passed=false
    fi
    
    # Check network connectivity
    if ! check_network; then
        error "Network connectivity required"
        checks_passed=false
    fi
    
    # Check disk space (need more space for complete setup)
    local required_space=5000000  # 5GB in KB
    local available_space=$(df / | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        error "Insufficient disk space. Required: 5GB, Available: $((available_space/1000))MB"
        checks_passed=false
    fi
    
    # Check if this looks like a fresh system
    if [ -f ~/.config/wizard-completed ]; then
        warning "Wizard appears to have been run before"
        echo "Previous completion: $(cat ~/.config/wizard-completed)"
        read -p "Continue anyway? [y/N] " continue_anyway
        [[ ! $continue_anyway =~ ^[Yy]$ ]] && return 1
    fi
    
    if $checks_passed; then
        success "All pre-flight checks passed"
        return 0
    else
        error "Pre-flight checks failed"
        return 1
    fi
}

# Step 1: System Update
step_system_update() {
    log "Step 1: Updating system packages..."
    
    echo "This will update all system packages including AUR packages."
    echo "This may take several minutes depending on your system."
    echo ""
    
    read -p "Proceed with system update? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("system_update")
        return 0
    fi
    
    # Update package databases
    if yay -Sy; then
        log "Package databases updated"
    else
        error "Failed to update package databases"
        return 1
    fi
    
    # Check for updates
    local updates_available=$(yay -Qu | wc -l)
    log "$updates_available packages available for update"
    
    if [ "$updates_available" -gt 0 ]; then
        log "Installing updates..."
        if yay -Su --noconfirm; then
            success "System update completed ($updates_available packages updated)"
            COMPLETED_STEPS+=("system_update")
            return 0
        else
            error "System update failed"
            return 1
        fi
    else
        success "System is already up to date"
        COMPLETED_STEPS+=("system_update")
        return 0
    fi
}

# Step 2: Install Zen Kernel
step_zen_kernel() {
    log "Step 2: Installing linux-zen kernel..."
    
    # Check if already installed
    if pacman -Qi linux-zen >/dev/null 2>&1; then
        log "Linux-zen already installed, skipping"
        COMPLETED_STEPS+=("zen_kernel")
        return 0
    fi
    
    echo "Linux-zen provides better desktop performance and lower latency."
    read -p "Install linux-zen kernel? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("zen_kernel")
        return 0
    fi
    
    # Install zen kernel
    if install_packages linux-zen linux-zen-headers; then
        # Update GRUB
        if [ -f /boot/grub/grub.cfg ]; then
            log "Updating GRUB configuration..."
            sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
        fi
        success "Linux-zen kernel installed"
        COMPLETED_STEPS+=("zen_kernel")
        return 0
    else
        error "Failed to install linux-zen kernel"
        return 1
    fi
}

# Step 3: AMD GPU Setup
step_amd_gpu() {
    log "Step 3: Setting up AMD GPU optimization..."
    
    # Check if AMD GPU is present
    if ! lspci | grep -i amd | grep -i vga >/dev/null; then
        log "No AMD GPU detected, skipping GPU optimization"
        SKIPPED_STEPS+=("amd_gpu")
        return 0
    fi
    
    log "AMD GPU detected: $(lspci | grep -i amd | grep -i vga | cut -d: -f3)"
    
    # Install AMD packages
    local amd_packages=("mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon" "amd-ucode")
    
    if install_packages "${amd_packages[@]}"; then
        # Add GRUB parameters
        if ! grep -q "amdgpu.si_support=1" /etc/default/grub 2>/dev/null; then
            log "Adding AMD GPU parameters to GRUB..."
            safe_edit_file /etc/default/grub
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&amdgpu.si_support=1 amdgpu.cik_support=1 /' /etc/default/grub
            
            if [ -f /boot/grub/grub.cfg ]; then
                sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
            fi
        fi
        
        success "AMD GPU optimization completed"
        COMPLETED_STEPS+=("amd_gpu")
        return 0
    else
        error "Failed to install AMD GPU packages"
        return 1
    fi
}

# Step 4: Performance Tweaks
step_performance() {
    log "Step 4: Applying performance tweaks..."
    
    echo "This will optimize your laptop for better performance and battery life."
    read -p "Apply performance tweaks? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("performance")
        return 0
    fi
    
    # Install power management
    if install_packages tlp tlp-rdw; then
        sudo systemctl enable tlp >/dev/null 2>&1
        sudo systemctl start tlp >/dev/null 2>&1
    else
        warning "Failed to install TLP power management"
    fi
    
    # Apply kernel parameters
    local sysctl_file="/etc/sysctl.d/99-performance.conf"
    if [ ! -f "$sysctl_file" ]; then
        log "Applying kernel performance parameters..."
        sudo tee "$sysctl_file" >/dev/null << 'EOF'
# Performance tweaks for laptop
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
kernel.sched_autogroup_enabled = 0
EOF
    fi
    
    # Install preload for faster app startup
    if install_packages preload; then
        sudo systemctl enable preload >/dev/null 2>&1
    else
        warning "Failed to install preload"
    fi
    
    success "Performance tweaks applied"
    COMPLETED_STEPS+=("performance")
    return 0
}

# Step 5: Essential Apps
step_essential_apps() {
    log "Step 5: Installing essential applications..."
    
    echo "This will install browsers, productivity apps, and system utilities."
    read -p "Install essential applications? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("essential_apps")
        return 0
    fi
    
    # Core applications
    local essential_apps=(
        "brave-bin"           # Browser
        "falkon"              # Qt browser
        "obsidian-bin"        # Notes
        "vlc"                 # Media player
        "calcurse"            # Calendar
        "taskwarrior-tui"     # Tasks
        "ranger"              # File manager
        "btop"                # System monitor
        "neofetch"            # System info
        "git"                 # Version control
        "wget"                # Download tool
        "curl"                # HTTP tool
        "unzip"               # Archive tool
        "unrar"               # Archive tool
        "p7zip"               # Archive tool
    )
    
    local failed_apps=()
    local installed_count=0
    
    for app in "${essential_apps[@]}"; do
        if yay -S --needed --noconfirm "$app" >/dev/null 2>&1; then
            ((installed_count++))
        else
            failed_apps+=("$app")
        fi
    done
    
    if [ ${#failed_apps[@]} -eq 0 ]; then
        success "All essential applications installed ($installed_count apps)"
    else
        warning "Some applications failed to install: ${failed_apps[*]}"
        success "$installed_count applications installed successfully"
    fi
    
    COMPLETED_STEPS+=("essential_apps")
    return 0
}

# Step 6: Development Environment (Optional)
step_development() {
    log "Step 6: Setting up development environment..."
    
    echo "This will install development tools (VS Code, Python, Node.js, etc.)"
    read -p "Install development environment? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        SKIPPED_STEPS+=("development")
        return 0
    fi
    
    local dev_packages=(
        "code"                # VS Code
        "python"              # Python
        "python-pip"          # Python package manager
        "nodejs"              # Node.js
        "npm"                 # Node package manager
        "git"                 # Version control
        "neovim"              # Text editor
    )
    
    if install_packages "${dev_packages[@]}"; then
        # Install Claude Code if requested
        read -p "Install Claude Code (AI coding assistant)? [y/N] " claude_confirm
        if [[ $claude_confirm =~ ^[Yy]$ ]]; then
            if command_exists npm; then
                npm install -g @anthropic-ai/claude-code 2>/dev/null && success "Claude Code installed"
            fi
        fi
        
        success "Development environment setup completed"
        COMPLETED_STEPS+=("development")
        return 0
    else
        error "Failed to install development packages"
        return 1
    fi
}

# Step 7: Study Environment
step_study_env() {
    log "Step 7: Setting up study environment..."
    
    echo "This will create directories and install tools for your Vitaltrainer studies."
    read -p "Setup study environment? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("study_env")
        return 0
    fi
    
    # Create study directories
    log "Creating study directory structure..."
    local study_dirs=(
        "Anatomie"
        "Physiologie"
        "Trainingslehre"
        "Ernährungslehre"
        "Entspannungslehre"
        "Prüfungen"
        "Notizen"
    )
    
    for dir in "${study_dirs[@]}"; do
        mkdir -p "$HOME/Documents/Studium/$dir"
    done
    
    # Install study-related tools
    local study_packages=("libreoffice-fresh" "okular" "anki")
    
    if install_packages "${study_packages[@]}"; then
        success "Study tools installed"
    else
        warning "Some study tools failed to install"
    fi
    
    success "Study environment setup completed"
    success "Study directories created in ~/Documents/Studium/"
    COMPLETED_STEPS+=("study_env")
    return 0
}

# Step 8: Final Configuration
step_final_config() {
    log "Step 8: Applying final configurations..."
    
    # Create useful aliases
    local aliases_file="$HOME/.bash_aliases"
    log "Setting up shell aliases..."
    
    cat > "$aliases_file" << 'EOF'
# Essential shortcuts (added by wizard)
alias sm='session-manager'
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias study='cd ~/Documents/Studium'

# Applications
alias obsidian='obsidian-bin'
alias calc='calcurse'
alias tasks='taskwarrior-tui'
alias files='ranger'
alias monitor='btop'

# System shortcuts
alias update='yay -Syu --noconfirm'
alias search='yay -Ss'
alias install='yay -S --noconfirm'
alias remove='yay -R --noconfirm'
alias clean='yay -Sc --noconfirm'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
EOF
    
    # Source aliases in bashrc
    if [ -f "$HOME/.bashrc" ] && ! grep -q ".bash_aliases" "$HOME/.bashrc"; then
        echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "$HOME/.bashrc"
    fi
    
    # Mark wizard as completed
    echo "$(date)" > ~/.config/wizard-completed
    
    success "Final configuration completed"
    COMPLETED_STEPS+=("final_config")
    return 0
}

# Show installation summary
show_summary() {
    echo ""
    echo "════════════════════════════════════════════"
    echo "🎉 INSTALLATION SUMMARY"
    echo "════════════════════════════════════════════"
    echo ""
    
    if [ ${#COMPLETED_STEPS[@]} -gt 0 ]; then
        success "Completed steps:"
        for step in "${COMPLETED_STEPS[@]}"; do
            echo "  ✅ ${WIZARD_STEPS[$step]}"
        done
        echo ""
    fi
    
    if [ ${#SKIPPED_STEPS[@]} -gt 0 ]; then
        warning "Skipped steps:"
        for step in "${SKIPPED_STEPS[@]}"; do
            echo "  ⏭️  ${WIZARD_STEPS[$step]}"
        done
        echo ""
    fi
    
    if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
        error "Failed steps:"
        for step in "${FAILED_STEPS[@]}"; do
            echo "  ❌ ${WIZARD_STEPS[$step]}"
        done
        echo ""
    fi
    
    echo "🎯 Your system is now optimized for:"
    echo "   • Study (Vitaltrainer Ausbildung)"
    echo "   • Productivity (Obsidian workflow)"
    echo "   • Performance (AMD GPU + linux-zen)"
    echo "   • Daily computing tasks"
    echo ""
    
    if grep -q "zen" /boot/grub/grub.cfg 2>/dev/null || [ ${#COMPLETED_STEPS[@]} -gt 0 ]; then
        echo "💡 Reboot recommended to activate all optimizations"
        echo ""
        
        read -p "Reboot now? [y/N] " reboot_confirm
        if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
            log "Rebooting system..."
            sudo reboot
        fi
    fi
}

# Execute wizard step with error handling
execute_step() {
    local step_name="$1"
    local step_function="$2"
    
    log "Executing: ${WIZARD_STEPS[$step_name]}"
    
    if $step_function; then
        success "✅ $step_name completed"
        return 0
    else
        error "❌ $step_name failed"
        FAILED_STEPS+=("$step_name")
        
        read -p "Continue with remaining steps? [Y/n] " continue_confirm
        [[ $continue_confirm =~ ^[Nn]$ ]] && return 1
        
        return 0
    fi
}

# Main wizard execution
main_wizard() {
    script_header "Complete Post-Install Wizard" "One-click setup for your IdeaPad Flex 5 with AMD Radeon"
    
    echo "This wizard will set up your system for optimal performance and productivity."
    echo "The process includes system updates, kernel installation, AMD GPU optimization,"
    echo "performance tweaks, essential applications, and study environment setup."
    echo ""
    echo "Estimated time: 15-30 minutes (depending on internet speed)"
    echo "Required space: ~5GB"
    echo ""
    
    read -p "Start complete system setup? [Y/n] " start_confirm
    if [[ $start_confirm =~ ^[Nn]$ ]]; then
        warning "Wizard cancelled"
        return 0
    fi
    
    # Pre-flight checks
    if ! run_preflight_checks; then
        error "Pre-flight checks failed. Please resolve issues and try again."
        return 1
    fi
    
    success "Starting complete system setup..."
    echo ""
    
    # Execute all steps
    execute_step "system_update" "step_system_update" || return 1
    execute_step "zen_kernel" "step_zen_kernel" || return 1
    execute_step "amd_gpu" "step_amd_gpu" || return 1
    execute_step "performance" "step_performance" || return 1
    execute_step "essential_apps" "step_essential_apps" || return 1
    execute_step "development" "step_development" || return 1
    execute_step "study_env" "step_study_env" || return 1
    execute_step "final_config" "step_final_config" || return 1
    
    # Show summary
    show_summary
    
    return 0
}

# Main execution
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    if main_wizard; then
        script_footer "Complete system setup finished"
    else
        error "Complete system setup failed"
        script_footer
        exit 1
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi