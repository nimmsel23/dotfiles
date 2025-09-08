#!/bin/bash

# Essential Apps Installation Script
# Part of nimmsel23's dotfiles post-install scripts
# Usage: bash ~/.dotfiles/scripts/post-install/essential-apps.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Define app categories
declare -A APP_CATEGORIES=(
    ["browsers"]="brave-bin falkon firefox-developer-edition"
    ["productivity"]="obsidian-bin"
    ["media"]="vlc mpv"
    ["file_tools"]="ranger lf unzip unrar p7zip file-roller"
    ["system_utils"]="htop btop neofetch tree git wget curl"
    ["cli_productivity"]="calcurse taskwarrior-tui"
    ["development"]="vim neovim"
)

# Show available apps
show_available_apps() {
    echo "Essential Apps Categories:"
    echo "════════════════════════════"
    echo ""
    
    echo "🌐 Browsers:"
    echo "  • Brave - Privacy-focused, ad-blocking"
    echo "  • Falkon - Qt-native, KDE integration"
    echo "  • Firefox Developer Edition - Web development"
    echo ""
    
    echo "📝 Productivity:"
    echo "  • Obsidian - Note-taking and knowledge management"
    echo "  • calcurse - Terminal-based calendar"
    echo "  • taskwarrior-tui - Task management"
    echo ""
    
    echo "🎬 Media:"
    echo "  • VLC - Universal media player"
    echo "  • mpv - Lightweight video player"
    echo ""
    
    echo "📁 File Management:"
    echo "  • ranger - Terminal file manager"
    echo "  • lf - Fast terminal file manager"
    echo "  • Archive tools (zip, rar, 7z support)"
    echo ""
    
    echo "⚙️ System Utilities:"
    echo "  • btop/htop - System monitoring"
    echo "  • neofetch - System information"
    echo "  • git, wget, curl - Essential tools"
    echo ""
    
    echo "👨‍💻 Development:"
    echo "  • Neovim - Modern Vim editor"
    echo "  • Vim - Classic text editor"
    echo ""
}

# Install category of apps
install_category() {
    local category="$1"
    local apps="${APP_CATEGORIES[$category]}"
    
    if [ -z "$apps" ]; then
        error "Unknown category: $category"
        return 1
    fi
    
    log "Installing $category apps..."
    
    # Convert string to array
    local apps_array=($apps)
    
    if install_packages "${apps_array[@]}"; then
        success "$category apps installed successfully"
        return 0
    else
        warning "Some $category apps failed to install"
        return 1
    fi
}

# Install all essential apps
install_all_apps() {
    local failed_categories=()
    
    log "Installing all essential applications..."
    echo ""
    
    # Install each category
    for category in "${!APP_CATEGORIES[@]}"; do
        if install_category "$category"; then
            success "✅ $category"
        else
            warning "⚠️  $category (some failures)"
            failed_categories+=("$category")
        fi
        echo ""
    done
    
    # Summary
    echo "Installation Summary:"
    echo "══════════════════════"
    
    if [ ${#failed_categories[@]} -eq 0 ]; then
        success "All app categories installed successfully!"
    else
        warning "Some categories had issues:"
        for category in "${failed_categories[@]}"; do
            echo "  ⚠️  $category"
        done
        echo ""
        echo "Check individual package availability with: yay -Ss <package>"
    fi
    
    return 0
}

# Interactive category selection
interactive_install() {
    echo "Select categories to install:"
    echo "═══════════════════════════════"
    echo ""
    
    local categories=("browsers" "productivity" "media" "file_tools" "system_utils" "cli_productivity" "development")
    local selected_categories=()
    
    # Show options
    for i in "${!categories[@]}"; do
        local num=$((i + 1))
        local category="${categories[$i]}"
        echo "  [$num] $category"
    done
    echo "  [a] All categories"
    echo "  [0] Cancel"
    echo ""
    
    while true; do
        read -p "Select categories (e.g., 1,3,5 or 'a' for all): " selection
        
        case "$selection" in
            0)
                warning "Installation cancelled"
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
                    
                    if [[ "$num" =~ ^[1-7]$ ]]; then
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
    echo "Selected categories:"
    for category in "${selected_categories[@]}"; do
        echo "  • $category"
    done
    echo ""
    
    read -p "Install these categories? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        warning "Installation cancelled"
        return 0
    fi
    
    # Install selected categories
    local failed_categories=()
    for category in "${selected_categories[@]}"; do
        if install_category "$category"; then
            success "✅ $category"
        else
            warning "⚠️  $category (some failures)"
            failed_categories+=("$category")
        fi
        echo ""
    done
    
    # Summary
    if [ ${#failed_categories[@]} -eq 0 ]; then
        success "All selected categories installed successfully!"
    else
        warning "Some categories had issues: ${failed_categories[*]}"
    fi
    
    return 0
}

# Setup application configurations
setup_app_configs() {
    log "Setting up application configurations..."
    
    # Create application directories
    mkdir -p ~/.config/{ranger,calcurse}
    
    # Setup useful aliases
    local aliases_file="$HOME/.bash_aliases"
    
    # Add/update aliases if not already present
    if [ ! -f "$aliases_file" ] || ! grep -q "Essential Apps Aliases" "$aliases_file"; then
        log "Adding essential app aliases..."
        
        cat >> "$aliases_file" << 'EOF'

# Essential Apps Aliases (added by dotfiles)
alias ff='firefox-developer-edition'
alias brave='brave-bin'
alias obs='obsidian-bin'
alias cal='calcurse'
alias tasks='taskwarrior-tui'
alias files='ranger'
alias monitor='btop'
alias sysinfo='neofetch'

# Quick shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF
        
        success "Aliases added to ~/.bash_aliases"
    else
        log "Aliases already configured"
    fi
    
    # Source aliases in bashrc if not already done
    if [ -f "$HOME/.bashrc" ] && ! grep -q ".bash_aliases" "$HOME/.bashrc"; then
        echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "$HOME/.bashrc"
        log "Enabled aliases in ~/.bashrc"
    fi
    
    success "Application configurations completed"
}

# Show post-installation tips
show_post_install_tips() {
    echo ""
    echo "🎯 Post-Installation Tips:"
    echo "════════════════════════════"
    echo ""
    echo "📱 Quick Access:"
    echo "  • Type 'obs' for Obsidian"
    echo "  • Type 'cal' for calcurse calendar"
    echo "  • Type 'tasks' for task management"
    echo "  • Type 'files' for ranger file manager"
    echo ""
    echo "🌐 Browsers:"
    echo "  • Brave: Privacy-focused with ad blocking"
    echo "  • Falkon: Integrates well with KDE"
    echo "  • Firefox Dev: Best for web development"
    echo ""
    echo "📝 Productivity Setup:"
    echo "  • Configure Obsidian vault location"
    echo "  • Import/setup calcurse calendar"
    echo "  • Configure taskwarrior projects"
    echo ""
    echo "💡 Tip: Reload your shell or logout/login to activate aliases"
}

# Main installation function
main_install() {
    script_header "Essential Apps Installation" "Install core applications for daily productivity"
    
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
    
    # Check disk space
    if ! check_disk_space; then
        return 1
    fi
    
    # Step 2: Show available apps
    show_available_apps
    
    # Step 3: Installation mode selection
    echo "Installation Options:"
    echo "══════════════════════"
    echo "  [1] Install all essential apps"
    echo "  [2] Interactive category selection"
    echo "  [0] Cancel"
    echo ""
    
    read -p "Choose installation mode: " mode
    
    case "$mode" in
        1)
            install_all_apps
            ;;
        2)
            interactive_install
            ;;
        0)
            warning "Installation cancelled"
            return 0
            ;;
        *)
            error "Invalid selection"
            return 1
            ;;
    esac
    
    # Step 4: Setup configurations
    setup_app_configs
    
    # Step 5: Show tips
    show_post_install_tips
    
    return 0
}

# Main execution
main() {
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    if main_install; then
        script_footer "Essential apps installation completed"
    else
        error "Essential apps installation failed"
        script_footer
        exit 1
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi