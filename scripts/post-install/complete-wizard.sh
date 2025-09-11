#!/bin/bash

# Complete Post-Install Wizard Script - UPDATED
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
    ["performance_safe"]="Apply SAFE laptop performance tweaks"
    ["wifi_fix"]="Fix WiFi power management issues"
    ["amd_gpu"]="Setup AMD GPU optimization"
    ["essential_apps"]="Install essential applications"
    ["development"]="Setup development environment (optional)"
    ["study_env"]="Setup study environment for Vitaltrainer"
    ["systemd_timers"]="Setup automated maintenance timers"
    ["final_config"]="Apply final configurations and cleanup"
)

# Step tracking
declare -a COMPLETED_STEPS=()
declare -a FAILED_STEPS=()
declare -a SKIPPED_STEPS=()

# Create backup directory for wizard
WIZARD_BACKUP_DIR="$HOME/.dotfiles/backups/wizard-$(date +%Y%m%d_%H%M%S)"

# Pre-flight checks
run_preflight_checks() {
    log "Running comprehensive pre-flight checks..."
    
    local checks_passed=true
    
    # Check if running as root (bad idea)
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root!"
        return 1
    fi
    
    # Check dotfiles environment
    if ! check_dotfiles_env; then
        error "Dotfiles environment not found"
        checks_passed=false
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
    if ! check_disk_space; then
        error "Insufficient disk space"
        checks_passed=false
    fi
    
    # Create backup directory
    mkdir -p "$WIZARD_BACKUP_DIR"
    log "Backup directory: $WIZARD_BACKUP_DIR"
    
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
    
    # Update package databases first
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
    
    # Install zen kernel and headers
    if install_packages linux-zen linux-zen-headers; then
        # Update GRUB safely
        if [ -f /boot/grub/grub.cfg ]; then
            log "Updating GRUB configuration..."
            if sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1; then
                success "GRUB updated"
            else
                warning "GRUB update failed, but kernel installed"
            fi
        fi
        success "Linux-zen kernel installed"
        COMPLETED_STEPS+=("zen_kernel")
        return 0
    else
        error "Failed to install linux-zen kernel"
        return 1
    fi
}

# Step 3: SAFE Performance Tweaks
step_performance_safe() {
    log "Step 3: Applying SAFE performance tweaks..."
    
    echo "This will apply conservative performance optimizations without breaking networking."
    read -p "Apply SAFE performance tweaks? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("performance_safe")
        return 0
    fi
    
    # Use the safe performance script we created
    local perf_script="${DOTFILES_DIR}/scripts/system/performance-tweaks-safe.sh"
    if [ -f "$perf_script" ]; then
        log "Running SAFE performance tweaks script..."
        if bash "$perf_script" <<< "1"; then  # Auto-select option 1 (apply all)
            success "SAFE performance tweaks applied"
            COMPLETED_STEPS+=("performance_safe")
            return 0
        else
            error "Performance tweaks failed"
            return 1
        fi
    else
        # Fallback to basic performance tweaks
        warning "SAFE performance script not found, applying basic tweaks"
        
        # Install TLP power management
        if install_packages tlp tlp-rdw; then
            sudo systemctl enable tlp >/dev/null 2>&1
            sudo systemctl start tlp >/dev/null 2>&1
            success "TLP power management enabled"
        else
            warning "Failed to install TLP"
        fi
        
        COMPLETED_STEPS+=("performance_safe")
        return 0
    fi
}

# Step 4: WiFi Power Fix
step_wifi_fix() {
    log "Step 4: Fixing WiFi power management..."
    
    echo "This will prevent WiFi from randomly disconnecting or asking for passwords."
    read -p "Apply WiFi power management fix? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("wifi_fix")
        return 0
    fi
    
    # Use the WiFi fix script we created
    local wifi_script="${DOTFILES_DIR}/scripts/system/wifi-power-fix.sh"
    if [ -f "$wifi_script" ]; then
        log "Running WiFi power management fix..."
        if bash "$wifi_script" <<< "1"; then  # Auto-select option 1 (apply all fixes)
            success "WiFi power management fixed"
            COMPLETED_STEPS+=("wifi_fix")
            return 0
        else
            warning "WiFi fix had issues but may still work"
            COMPLETED_STEPS+=("wifi_fix")
            return 0
        fi
    else
        # Fallback to basic WiFi fix
        warning "WiFi fix script not found, applying basic fix"
        
        # Basic NetworkManager WiFi power save fix
        sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf >/dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF
        sudo systemctl restart NetworkManager
        
        success "Basic WiFi fix applied"
        COMPLETED_STEPS+=("wifi_fix")
        return 0
    fi
}

# Step 5: AMD GPU Setup
step_amd_gpu() {
    log "Step 5: Setting up AMD GPU optimization..."
    
    # Check if AMD GPU is present
    if ! lspci | grep -i amd | grep -i vga >/dev/null; then
        log "No AMD GPU detected, skipping GPU optimization"
        SKIPPED_STEPS+=("amd_gpu")
        return 0
    fi
    
    log "AMD GPU detected: $(lspci | grep -i amd | grep -i vga | cut -d: -f3)"
    
    echo "This will install AMD GPU drivers and optimization."
    read -p "Setup AMD GPU optimization? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("amd_gpu")
        return 0
    fi
    
    # Install AMD packages
    local amd_packages=("mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon" "amd-ucode")
    
    if install_packages "${amd_packages[@]}"; then
        # Backup and modify GRUB safely
        if ! grep -q "amdgpu.si_support=1" /etc/default/grub 2>/dev/null; then
            log "Adding AMD GPU parameters to GRUB..."
            
            # Backup GRUB config
            sudo cp /etc/default/grub "$WIZARD_BACKUP_DIR/grub.backup"
            
            # Add AMD GPU parameters
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&amdgpu.si_support=1 amdgpu.cik_support=1 /' /etc/default/grub
            
            # Update GRUB safely
            if [ -f /boot/grub/grub.cfg ]; then
                if sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1; then
                    success "GRUB updated with AMD parameters"
                else
                    warning "GRUB update failed, restoring backup"
                    sudo cp "$WIZARD_BACKUP_DIR/grub.backup" /etc/default/grub
                fi
            fi
        fi
        
        # Install GPU monitoring tools
        install_packages radeontop >/dev/null 2>&1
        
        success "AMD GPU optimization completed"
        COMPLETED_STEPS+=("amd_gpu")
        return 0
    else
        error "Failed to install AMD GPU packages"
        return 1
    fi
}

# Step 6: Essential Apps
step_essential_apps() {
    log "Step 6: Installing essential applications..."
    
    echo "This will install browsers, productivity apps, and system utilities."
    read -p "Install essential applications? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("essential_apps")
        return 0
    fi
    
    # Core applications with fallbacks
    local essential_apps=(
        "brave-bin"           # Browser
        "firefox"             # Fallback browser
        "obsidian-bin"        # Notes (your primary tool)
        "vlc"                 # Media player
        "calcurse"            # Calendar (for studies)
        "taskwarrior-tui"     # Tasks
        "ranger"              # File manager
        "btop"                # System monitor
        "neofetch"            # System info
        "git"                 # Version control
        "wget"                # Download tool
        "curl"                # HTTP tool
        "unzip"               # Archive tool
        "p7zip"               # Archive tool
        "fish"                # Better shell
    )
    
    local failed_apps=()
    local installed_count=0
    
    for app in "${essential_apps[@]}"; do
        if yay -S --needed --noconfirm "$app" >/dev/null 2>&1; then
            ((installed_count++))
            log "Installed: $app"
        else
            failed_apps+=("$app")
            warning "Failed to install: $app"
        fi
    done
    
    if [ ${#failed_apps[@]} -eq 0 ]; then
        success "All essential applications installed ($installed_count apps)"
    else
        warning "Some applications failed: ${failed_apps[*]}"
        success "$installed_count/$((installed_count + ${#failed_apps[@]})) applications installed"
    fi
    
    COMPLETED_STEPS+=("essential_apps")
    return 0
}

# Step 7: Development Environment (Optional)
step_development() {
    log "Step 7: Setting up development environment..."
    
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
        "neovim"              # Text editor
        "docker"              # Containerization
        "base-devel"          # Build tools
    )
    
    if install_packages "${dev_packages[@]}"; then
        # Enable Docker service
        if command_exists docker; then
            sudo systemctl enable docker >/dev/null 2>&1
            sudo usermod -aG docker "$USER" >/dev/null 2>&1
            log "Docker enabled (reboot required for group membership)"
        fi
        
        success "Development environment setup completed"
        COMPLETED_STEPS+=("development")
        return 0
    else
        error "Failed to install some development packages"
        COMPLETED_STEPS+=("development")  # Mark as completed even if partial
        return 0
    fi
}

# Step 8: Study Environment for Vitaltrainer
step_study_env() {
    log "Step 8: Setting up study environment for Vitaltrainer..."
    
    echo "This will create directories and install tools for your Vitaltrainer studies."
    read -p "Setup study environment? [Y/n] " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        SKIPPED_STEPS+=("study_env")
        return 0
    fi
    
    # Create study directories
    log "Creating study directory structure..."
    local study_base="$HOME/Documents/Studium"
    local study_dirs=(
        "Anatomie"
        "Physiologie" 
        "Trainingslehre"
        "Ernährungslehre"
        "Entspannungslehre"
        "Differenziertes_Krafttraining"
        "Wirbelsäule_Präventionspezialisierung"
        "Prüfungen"
        "Notizen"
        "Literatur"
    )
    
    for dir in "${study_dirs[@]}"; do
        mkdir -p "$study_base/$dir"
    done
    
    # Install study-related tools
    local study_packages=(
        "libreoffice-fresh"   # Office suite
        "okular"              # PDF reader
        "anki"                # Flashcards
        "calibre"             # E-book management
    )
    
    local study_failed=()
    for package in "${study_packages[@]}"; do
        if ! yay -S --needed --noconfirm "$package" >/dev/null 2>&1; then
            study_failed+=("$package")
        fi
    done
    
    if [ ${#study_failed[@]} -eq 0 ]; then
        success "All study tools installed"
    else
        warning "Some study tools failed to install: ${study_failed[*]}"
    fi
    
    # Create study schedule template
    cat > "$study_base/Stundenplan_Template.md" << 'EOF'
# Vitaltrainer Ausbildung - Stundenplan

## Woche 1
- [ ] Anatomie: Grundlagen
- [ ] Physiologie: Herz-Kreislauf-System
- [ ] Trainingslehre: Grundprinzipien

## Woche 2
- [ ] Ernährungslehre: Makronährstoffe
- [ ] Entspannungslehre: Stressmanagement
- [ ] Krafttraining: Biomechanik

## Prüfungsvorbereitung
- [ ] Theorie wiederholen
- [ ] Praktische Übungen
- [ ] Mock-Prüfungen

## Notizen
...
EOF
    
    success "Study environment setup completed"
    success "Study directories created in $study_base"
    COMPLETED_STEPS+=("study_env")
    return 0
}

# Step 9: Systemd Timers Setup
step_systemd_timers() {
    log "Step 9: Setting up automated maintenance timers..."
    
    echo "This will setup automated backups, system cleanup, and study reminders."
    read -p "Setup automated timers? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        SKIPPED_STEPS+=("systemd_timers")
        return 0
    fi
    
    # Use the systemd timer manager we created
    local timer_script="${DOTFILES_DIR}/scripts/system/systemd-timer-manager.sh"
    if [ -f "$timer_script" ]; then
        log "Setting up systemd timers..."
        if bash "$timer_script" create; then
            success "Automated maintenance timers configured"
            COMPLETED_STEPS+=("systemd_timers")
            return 0
        else
            warning "Timer setup had issues"
            COMPLETED_STEPS+=("systemd_timers")
            return 0
        fi
    else
        warning "Systemd timer manager not found, skipping"
        SKIPPED_STEPS+=("systemd_timers")
        return 0
    fi
}

# Step 10: Final Configuration
step_final_config() {
    log "Step 10: Applying final configurations..."
    
    # Create useful aliases
    local aliases_file="$HOME/.bash_aliases"
    log "Setting up shell aliases..."
    
    cat > "$aliases_file" << 'EOF'
# Essential shortcuts (added by complete wizard)
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
alias update='yay -Syu'
alias search='yay -Ss'
alias install='yay -S'
alias remove='yay -R'
alias clean='yay -Sc'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline'

# Study shortcuts
alias anatomy='cd ~/Documents/Studium/Anatomie'
alias physio='cd ~/Documents/Studium/Physiologie'
alias training='cd ~/Documents/Studium/Trainingslehre'
alias nutrition='cd ~/Documents/Studium/Ernährungslehre'
EOF
    
    # Source aliases in shell configs
    for shell_rc in ~/.bashrc ~/.zshrc; do
        if [ -f "$shell_rc" ] && ! grep -q ".bash_aliases" "$shell_rc"; then
            echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "$shell_rc"
        fi
    done
    
    # Set Fish as default shell if installed and requested
    if command_exists fish; then
        read -p "Set Fish as your default shell? [y/N] " fish_confirm
        if [[ $fish_confirm =~ ^[Yy]$ ]]; then
            if chsh -s "$(which fish)"; then
                success "Fish shell set as default"
            else
                warning "Failed to set Fish as default shell"
            fi
        fi
    fi
    
    # Create desktop shortcuts for study apps
    if [ -d "$HOME/Desktop" ]; then
        cat > "$HOME/Desktop/Study_Apps.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Link
Name=Study Applications
Comment=Quick access to study tools
Icon=applications-education
URL=file:///home/$USER/Documents/Studium
EOF
        chmod +x "$HOME/Desktop/Study_Apps.desktop"
    fi
    
    # Mark wizard as completed
    echo "$(date) - Complete Wizard v2.0" > ~/.config/wizard-completed
    
    success "Final configuration completed"
    COMPLETED_STEPS+=("final_config")
    return 0
}

# Show installation summary
show_summary() {
    echo ""
    echo "════════════════════════════════════════════"
    echo "🎉 COMPLETE WIZARD SUMMARY"
    echo "════════════════════════════════════════════"
    echo ""
    
    if [ ${#COMPLETED_STEPS[@]} -gt 0 ]; then
        success "Completed steps (${#COMPLETED_STEPS[@]}):"
        for step in "${COMPLETED_STEPS[@]}"; do
            echo "  ✅ ${WIZARD_STEPS[$step]}"
        done
        echo ""
    fi
    
    if [ ${#SKIPPED_STEPS[@]} -gt 0 ]; then
        warning "Skipped steps (${#SKIPPED_STEPS[@]}):"
        for step in "${SKIPPED_STEPS[@]}"; do
            echo "  ⏭️  ${WIZARD_STEPS[$step]}"
        done
        echo ""
    fi
    
    if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
        error "Failed steps (${#FAILED_STEPS[@]}):"
        for step in "${FAILED_STEPS[@]}"; do
            echo "  ❌ ${WIZARD_STEPS[$step]}"
        done
        echo ""
    fi
    
    echo "🎯 Your IdeaPad Flex 5 is now optimized for:"
    echo "   📚 Study (Vitaltrainer Ausbildung with Obsidian workflow)"
    echo "   ⚡ Performance (AMD GPU + linux-zen + SAFE tweaks)"
    echo "   📡 Connectivity (WiFi power management fixed)"
    echo "   🛠️  Productivity (Essential apps + development tools)"
    echo "   🔄 Automation (Systemd timers for maintenance)"
    echo ""
    
    echo "🔗 Quick Commands:"
    echo "   sm              - Session Manager"
    echo "   study           - Go to study directory"
    echo "   calc            - Open calcurse calendar"
    echo "   obsidian        - Open Obsidian"
    echo "   update          - System update"
    echo ""
    
    if [ ${#COMPLETED_STEPS[@]} -ge 3 ]; then
        echo "💡 Reboot recommended to activate all optimizations"
        echo "   (Especially important for linux-zen kernel and AMD GPU)"
        echo ""
        
        read -p "Reboot now? [y/N] " reboot_confirm
        if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
            log "Rebooting system in 5 seconds..."
            sleep 5
            sudo reboot
        fi
    fi
    
    echo "📦 Backup directory: $WIZARD_BACKUP_DIR"
    echo "🏠 Study directory: ~/Documents/Studium"
}

# Execute wizard step with error handling
execute_step() {
    local step_name="$1"
    local step_function="$2"
    
    echo ""
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
    script_header "Complete Post-Install Wizard v2.0" "Comprehensive setup for your IdeaPad Flex 5 with AMD Radeon"
    
    echo "This updated wizard includes:"
    echo "• SAFE performance tweaks (no networking issues)"
    echo "• WiFi power management fix (stops random disconnects)"
    echo "• Study environment optimized for Vitaltrainer Ausbildung"
    echo "• Automated maintenance with systemd timers"
    echo "• AMD GPU optimization"
    echo "• Essential productivity applications"
    echo ""
    echo "Estimated time: 20-40 minutes (depending on internet speed)"
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
    
    # Execute all steps in order
    execute_step "system_update" "step_system_update" || return 1
    execute_step "zen_kernel" "step_zen_kernel" || return 1
    execute_step "performance_safe" "step_performance_safe" || return 1
    execute_step "wifi_fix" "step_wifi_fix" || return 1
    execute_step "amd_gpu" "step_amd_gpu" || return 1
    execute_step "essential_apps" "step_essential_apps" || return 1
    execute_step "development" "step_development" || return 1
    execute_step "study_env" "step_study_env" || return 1
    execute_step "systemd_timers" "step_systemd_timers" || return 1
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
        script_footer "Complete system setup finished successfully"
    else
        error "Complete system setup encountered issues"
        script_footer
        exit 1
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi