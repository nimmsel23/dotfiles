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

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    error "Git is not installed. Please install git first:"
    echo "  sudo pacman -S git"
    exit 1
fi

echo "🚀 Setting up nimmsel23's dotfiles..."
echo "═══════════════════════════════════════════"

# Clone dotfiles repository
log "Cloning dotfiles repository..."
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
        echo "Make sure the repository exists and is accessible"
        exit 1
    fi
fi

cd "$HOME/.dotfiles"

# Create necessary directories
log "Creating directory structure..."
mkdir -p ~/.local/bin
mkdir -p ~/.config
mkdir -p ~/Documents

# Link session-manager
log "Installing session-manager..."
if [ -f "scripts/session-manager" ]; then
    ln -sf "$HOME/.dotfiles/scripts/session-manager" "$HOME/.local/bin/session-manager"
    chmod +x "$HOME/.local/bin/session-manager"
    success "Session-manager installed"
else
    error "Session-manager script not found in repository"
    exit 1
fi

# Update PATH in shell profiles
log "Updating shell profiles..."
for shell_profile in ~/.bashrc ~/.zshrc ~/.profile; do
    if [ -f "$shell_profile" ]; then
        # Add .local/bin to PATH if not already present
        if ! grep -q '/.local/bin' "$shell_profile"; then
            echo '' >> "$shell_profile"
            echo '# Added by nimmsel23 dotfiles installer' >> "$shell_profile"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_profile"
            log "Added PATH export to $(basename "$shell_profile")"
        fi
        
        # Add session-manager auto-start for TTY1
        if ! grep -q "session-manager" "$shell_profile"; then
            echo '# Auto-start session-manager on TTY1' >> "$shell_profile"
            echo '[ "$XDG_VTNR" = "1" ] && exec session-manager' >> "$shell_profile"
            log "Added session-manager auto-start to $(basename "$shell_profile")"
        fi
    fi
done

# Link configuration files (if they exist)
log "Linking configuration files..."

# Fish shell config
if [ -d "config/fish" ]; then
    ln -sf "$HOME/.dotfiles/config/fish" "$HOME/.config/fish"
    success "Fish configuration linked"
fi

# Neovim config
if [ -d "config/nvim" ]; then
    ln -sf "$HOME/.dotfiles/config/nvim" "$HOME/.config/nvim"
    success "Neovim configuration linked"
fi

# Calcurse config
if [ -d "config/calcurse" ]; then
    ln -sf "$HOME/.dotfiles/config/calcurse" "$HOME/.config/calcurse"
    success "Calcurse configuration linked"
fi

# Create study directories
log "Setting up study environment..."
study_dirs=(
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

# Copy study templates if they exist
if [ -d "study/templates" ]; then
    cp -r study/templates/* "$HOME/Documents/Studium/" 2>/dev/null || true
    success "Study templates copied"
fi

# Create useful aliases
log "Setting up aliases..."
aliases_file="$HOME/.bash_aliases"
cat > "$aliases_file" << EOF
# Added by nimmsel23 dotfiles installer
alias sm='session-manager'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias study='cd ~/Documents/Studium'
alias obs='obsidian'
alias cal='calcurse'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# System shortcuts
alias update='yay -Syu'
alias search='yay -Ss'
alias install='yay -S'
alias remove='yay -R'
alias clean='yay -Sc'
EOF

# Source aliases in bashrc if not already done
if [ -f "$HOME/.bashrc" ] && ! grep -q ".bash_aliases" "$HOME/.bashrc"; then
    echo '' >> "$HOME/.bashrc"
    echo '# Source aliases' >> "$HOME/.bashrc"
    echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "$HOME/.bashrc"
fi

success "Aliases configured"

# Set up SSH key for GitHub (if needed)
log "Checking GitHub SSH setup..."

if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
    warning "No SSH key found for GitHub"
    echo ""
    echo "To push changes to your dotfiles repository, you'll need SSH key authentication."
    echo "GitHub no longer accepts password authentication for git operations."
    echo ""
    read -p "Generate SSH key now? [y/N] " generate_ssh
    
    if [[ $generate_ssh =~ ^[Yy]$ ]]; then
        if [ -n "$git_email" ]; then
            ssh_email="$git_email"
        else
            read -p "Enter email for SSH key: " ssh_email
        fi
        
        if [ -n "$ssh_email" ]; then
            log "Generating SSH key..."
            ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
            
            # Start ssh-agent and add key
            eval "$(ssh-agent -s)"
            ssh-add "$HOME/.ssh/id_ed25519"
            
            success "SSH key generated: $HOME/.ssh/id_ed25519.pub"
            echo ""
            echo "📋 Copy this public key to GitHub:"
            echo "   https://github.com/settings/ssh/new"
            echo ""
            echo "Your public key:"
            echo "────────────────────────────────────────────"
            cat "$HOME/.ssh/id_ed25519.pub"
            echo "────────────────────────────────────────────"
            echo ""
            echo "After adding the key to GitHub, you can:"
            echo "  • Clone with: git clone git@github.com:nimmsel23/dotfiles.git"
            echo "  • Push changes with: git push"
            echo ""
            read -p "Press Enter after adding the key to GitHub..."
            
            # Test SSH connection
            log "Testing GitHub SSH connection..."
            if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
                success "GitHub SSH connection working!"
            else
                warning "GitHub SSH connection failed. Make sure you added the key correctly."
            fi
        fi
    else
        echo ""
        echo "💡 To set up SSH later:"
        echo "  1. ssh-keygen -t ed25519 -C 'your.email@example.com'"
        echo "  2. cat ~/.ssh/id_ed25519.pub"
        echo "  3. Add the public key to: https://github.com/settings/ssh/new"
    fi
else
    success "SSH key found"
    
    # Check if GitHub is in known_hosts
    if ! grep -q "github.com" "$HOME/.ssh/known_hosts" 2>/dev/null; then
        log "Adding GitHub to known hosts..."
        ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
    fi
    
    # Test connection
    log "Testing GitHub SSH connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        success "GitHub SSH connection working!"
    else
        warning "GitHub SSH connection issues. You may need to add your key to GitHub."
        echo "Add your public key at: https://github.com/settings/ssh/new"
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            echo "Your public key:"
            cat "$HOME/.ssh/id_ed25519.pub"
        elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            echo "Your public key:"
            cat "$HOME/.ssh/id_rsa.pub"
        fi
    fi
fi

# Set up git config (basic)
log "Configuring git..."
read -p "Enter your git username (or press Enter to skip): " git_username
read -p "Enter your git email (or press Enter to skip): " git_email

if [ -n "$git_username" ]; then
    git config --global user.name "$git_username"
    success "Git username set to: $git_username"
fi

if [ -n "$git_email" ]; then
    git config --global user.email "$git_email"
    success "Git email set to: $git_email"
fi

echo ""
echo "════════════════════════════════════════════"
success "Dotfiles setup complete!"
echo ""
echo "🎯 What's been set up:"
echo "   • Session-manager installed and configured"
echo "   • Shell profiles updated with PATH and auto-start"
echo "   • Basic study directory created"
echo "   • Calcurse config linked (if available)"
echo "   • Useful aliases added (sm, calc, update, install, etc.)"
echo "   • SSH setup for GitHub (if configured)"
echo ""
echo "💡 Next steps:"
echo "   1. Logout and login again (or source your shell profile)"
echo "   2. TTY1 will auto-start session-manager"
echo "   3. Use 'sm' as shortcut for session-manager"
echo "   4. Use 'update', 'install', 'search' for package management"
echo ""
echo "🔧 Repository location: ~/.dotfiles"
echo "📚 Study directory: ~/Documents/Studium"
echo ""

# Offer to start session-manager immediately
read -p "Start session-manager now? [Y/n] " start_sm
if [[ ! $start_sm =~ ^[Nn]$ ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    exec session-manager
fi

echo "Run 'session-manager' or 'sm' to start!"
