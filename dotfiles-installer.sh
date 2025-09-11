#!/bin/bash
# Dotfiles installer for nimmsel23
# Usage: curl -fsSL https://raw.githubusercontent.com/nimmsel23/dotfiles/main/install.sh | bash

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check system requirements
check_requirements() {
    local missing_deps=()
    
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        echo "Install with: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
}

# Main installation
main() {
    echo "🚀 Setting up nimmsel23's dotfiles..."
    echo "═══════════════════════════════════════════"
    echo ""
    
    # Check requirements
    check_requirements
    
    # Clone or update dotfiles
    log "Setting up dotfiles repository..."
    if [ -d "$HOME/.dotfiles" ]; then
        warning "Dotfiles directory already exists. Updating..."
        cd "$HOME/.dotfiles"
        git pull origin main || {
            error "Failed to update dotfiles"
            exit 1
        }
    else
        if git clone https://github.com/nimmsel23/dotfiles.git "$HOME/.dotfiles"; then
            success "Dotfiles cloned successfully"
        else
            error "Failed to clone dotfiles repository"
            exit 1
        fi
    fi
    
    cd "$HOME/.dotfiles"
    
    # Create basic directory structure
    log "Creating directory structure..."
    mkdir -p ~/.local/bin
    mkdir -p ~/.config
    mkdir -p ~/Documents
    
    # Install session-manager as main entry point
    log "Installing session-manager..."
    if [ -f "session-manager.sh" ]; then
        # Link session-manager to global location
        ln -sf "$HOME/.dotfiles/session-manager.sh" "$HOME/.local/bin/session-manager"
        chmod +x "$HOME/.local/bin/session-manager"
        chmod +x "$HOME/.dotfiles/session-manager.sh"
        success "Session-manager installed"
    else
        error "Session-manager script not found"
        exit 1
    fi
    
    # Update PATH in shell profiles
    log "Updating shell configuration..."
    for shell_rc in ~/.bashrc ~/.zshrc; do
        if [ -f "$shell_rc" ]; then
            # Add .local/bin to PATH if not present
            if ! grep -q '.local/bin' "$shell_rc"; then
                echo '' >> "$shell_rc"
                echo '# Added by nimmsel23 dotfiles' >> "$shell_rc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
                log "Updated PATH in $(basename "$shell_rc")"
            fi
        fi
    done
    
    # Set up useful aliases
    log "Setting up aliases..."
    cat > "$HOME/.bash_aliases" << 'EOF'
# nimmsel23 dotfiles aliases
alias sm='session-manager'
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline'

# System management
alias update='yay -Syu'
alias search='yay -Ss'
alias install='yay -S'
alias remove='yay -R'
alias clean='yay -Sc'

# Quick tools
alias calc='calcurse'
alias tasks='taskwarrior-tui'
alias monitor='btop'
EOF
    
    # Source aliases in bashrc
    if [ -f "$HOME/.bashrc" ] && ! grep -q ".bash_aliases" "$HOME/.bashrc"; then
        echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "$HOME/.bashrc"
    fi
    
    success "Aliases configured"
    
    # Link essential configs if they exist
    log "Linking configuration files..."
    
    # Fish shell
    if [ -d "config/fish" ]; then
        ln -sf "$HOME/.dotfiles/config/fish" "$HOME/.config/"
        success "Fish configuration linked"
    fi
    
    # Calcurse (study tool)
    if [ -d "config/calcurse" ]; then
        ln -sf "$HOME/.dotfiles/config/calcurse" "$HOME/.config/"
        success "Calcurse configuration linked"
    fi
    
    # Git configuration
    setup_git_config
    
    # Installation complete
    echo ""
    echo "════════════════════════════════════════════"
    success "Dotfiles installation complete!"
    echo ""
    echo "🎯 What's been installed:"
    echo "   • Session-manager (run with 'sm' or 'session-manager')"
    echo "   • Useful aliases (update, install, gs, gc, etc.)"
    echo "   • PATH updated for ~/.local/bin"
    echo "   • Configuration files linked"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Restart your terminal or run: source ~/.bashrc"
    echo "   2. Run 'session-manager' to access all tools"
    echo "   3. Use post-install scripts via session manager"
    echo ""
    echo "🔧 Repository: ~/.dotfiles"
    echo "📱 Quick start: sm"
    echo ""
    
    # Offer immediate start
    read -p "Start session-manager now? [Y/n] " start_now
    if [[ ! $start_now =~ ^[Nn]$ ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        exec session-manager
    fi
    
    echo "Run 'session-manager' or 'sm' when ready!"
}

# Git configuration setup
setup_git_config() {
    log "Git configuration..."
    
    # Check if git is already configured
    if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
        local current_name=$(git config --global user.name)
        local current_email=$(git config --global user.email)
        success "Git already configured: $current_name <$current_email>"
        return 0
    fi
    
    # Quick setup for common case
    echo ""
    echo "🔧 Git Configuration:"
    read -p "Git username (or press Enter to skip): " git_username
    read -p "Git email (or press Enter to skip): " git_email
    
    if [ -n "$git_username" ]; then
        git config --global user.name "$git_username"
        success "Git username: $git_username"
    fi
    
    if [ -n "$git_email" ]; then
        git config --global user.email "$git_email"
        success "Git email: $git_email"
    fi
    
    if [ -n "$git_username" ] || [ -n "$git_email" ]; then
        # Basic git settings
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        log "Basic git settings applied"
    fi
    
    # SSH key check (non-interactive)
    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
        warning "No SSH key found for GitHub"
        echo "Generate one later with: ssh-keygen -t ed25519 -C 'your@email.com'"
        echo "Then add to GitHub: https://github.com/settings/ssh/new"
    else
        success "SSH key found"
    fi
}

# Run main installation
main "$@"