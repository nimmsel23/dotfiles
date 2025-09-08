#!/bin/bash

# Git Repository Setup for nimmsel23/dotfiles
# Initialize local repository and push to GitHub
# Usage: bash setup-git-repo.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Setup git repository for dotfiles
setup_git_repo() {
    echo "═══════════════════════════════════════════"
    echo "🚀 Git Repository Setup for nimmsel23/dotfiles"
    echo "═══════════════════════════════════════════"
    echo ""
    
    # Check if git is installed
    if ! command_exists git; then
        error "Git is not installed"
        echo "Install with: sudo pacman -S git"
        return 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "session-manager" ] && [ ! -d "scripts" ]; then
        warning "This doesn't look like the dotfiles directory"
        read -p "Continue anyway? [y/N] " confirm
        [[ ! $confirm =~ ^[Yy]$ ]] && return 1
    fi
    
    # Initialize git repository if not already done
    if [ ! -d ".git" ]; then
        log "Initializing git repository..."
        git init
        success "Git repository initialized"
    else
        log "Git repository already exists"
    fi
    
    # Check git configuration
    local git_name=$(git config user.name 2>/dev/null)
    local git_email=$(git config user.email 2>/dev/null)
    
    if [ -z "$git_name" ]; then
        read -p "Enter your git username: " git_name
        git config user.name "$git_name"
        success "Git username set to: $git_name"
    else
        log "Git username: $git_name"
    fi
    
    if [ -z "$git_email" ]; then
        read -p "Enter your git email: " git_email
        git config user.email "$git_email"
        success "Git email set to: $git_email"
    else
        log "Git email: $git_email"
    fi
    
    # Setup SSH key if needed
    setup_ssh_key "$git_email"
    
    # Create directory structure
    create_directory_structure
    
    # Create/update .gitignore
    create_gitignore
    
    # Create README.md
    create_readme
    
    # Add all files
    log "Adding files to git..."
    git add .
    
    # Initial commit
    if git diff --cached --quiet; then
        log "No changes to commit"
    else
        log "Creating initial commit..."
        git commit -m "Initial modular dotfiles setup

- Simplified session-manager with desktop launcher
- Modular script system for maintainability
- Comprehensive error handling and validation
- Individual scripts for specific tasks
- Shared common functions in utils/common.sh
- Complete post-install wizard
- Optimized for IdeaPad Flex 5 with AMD Radeon"
        success "Initial commit created"
    fi
    
    # Setup remote repository
    setup_remote_repo
    
    return 0
}

# Setup SSH key for GitHub
setup_ssh_key() {
    local email="$1"
    
    log "Checking SSH key setup..."
    
    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
        warning "No SSH key found"
        echo ""
        echo "GitHub requires SSH key authentication for git operations."
        read -p "Generate SSH key now? [Y/n] " generate_ssh
        
        if [[ ! $generate_ssh =~ ^[Nn]$ ]]; then
            if [ -n "$email" ]; then
                ssh_email="$email"
            else
                read -p "Enter email for SSH key: " ssh_email
            fi
            
            if [ -n "$ssh_email" ]; then
                log "Generating SSH key..."
                ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
                
                # Start ssh-agent and add key
                eval "$(ssh-agent -s)" >/dev/null 2>&1
                ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1
                
                success "SSH key generated"
                echo ""
                echo "📋 Add this public key to GitHub:"
                echo "   https://github.com/settings/ssh/new"
                echo ""
                echo "Your public key:"
                echo "────────────────────────────────────────────"
                cat "$HOME/.ssh/id_ed25519.pub"
                echo "────────────────────────────────────────────"
                echo ""
                read -p "Press Enter after adding the key to GitHub..."
            fi
        fi
    else
        success "SSH key found"
    fi
    
    # Test SSH connection
    log "Testing GitHub SSH connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        success "GitHub SSH connection working!"
    else
        warning "GitHub SSH connection failed"
        echo "Make sure you've added your SSH key to GitHub:"
        echo "https://github.com/settings/ssh/new"
    fi
}

# Create directory structure
create_directory_structure() {
    log "Creating directory structure..."
    
    # Main directories
    mkdir -p scripts/{utils,system,post-install}
    mkdir -p config/{fish,calcurse}
    mkdir -p templates
    
    # Move files to correct locations if they exist
    if [ -f "session-manager" ]; then
        mv session-manager scripts/
        success "Moved session-manager to scripts/"
    fi
    
    # Create placeholder files for missing scripts
    local missing_scripts=(
        "scripts/system/amd-optimization.sh"
        "scripts/system/system-update.sh"
        "scripts/post-install/dev-environment.sh"
        "scripts/post-install/study-setup.sh"
        "scripts/post-install/multimedia.sh"
    )
    
    for script in "${missing_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            cat > "$script" << 'EOF'
#!/bin/bash
# TODO: Implement this script
echo "This script is not yet implemented."
echo "Check https://github.com/nimmsel23/dotfiles for updates."
exit 1
EOF
            chmod +x "$script"
        fi
    done
    
    success "Directory structure created"
}

# Create .gitignore
create_gitignore() {
    log "Creating .gitignore..."
    
    cat > .gitignore << 'EOF'
# Personal files
*.personal
*.local
.env

# Backup files
*.backup
*.bak
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo

# Log files
*.log

# Temporary files
tmp/
temp/
EOF
    
    success ".gitignore created"
}

# Create comprehensive README.md
create_readme() {
    log "Creating README.md..."
    
    cat > README.md << 'EOF'
# nimmsel23's Dotfiles

Modular dotfiles system optimized for EndeavourOS/Arch Linux with KDE Plasma, specifically configured for IdeaPad Flex 5 with AMD Radeon graphics.

## 🚀 Quick Start

### One-Line Installation
```bash
curl -fsSL https://raw.githubusercontent.com/nimmsel23/dotfiles/main/install.sh | bash
```

### Manual Installation
```bash
git clone https://github.com/nimmsel23/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh
```

## 🖥️ Session Manager

The simplified session manager provides quick access to desktop environments and system scripts:

```bash
session-manager
```

**Features:**
- Auto-detects installed desktop environments
- Quick access to CLI tools (calcurse, taskwarrior-tui, etc.)
- Direct access to system scripts
- One-key shortcuts for common tasks

## 📁 Repository Structure

```
├── scripts/
│   ├── session-manager           # Main launcher
│   ├── utils/
│   │   └── common.sh            # Shared functions
│   ├── system/
│   │   ├── setup-swap.sh        # Swap partition setup
│   │   ├── install-zen-kernel.sh # Kernel management
│   │   └── performance-tweaks.sh # Laptop optimizations
│   └── post-install/
│       ├── essential-apps.sh    # Core applications
│       ├── complete-wizard.sh   # Full system setup
│       └── ...
├── config/
│   ├── fish/                    # Fish shell config
│   └── calcurse/               # Calendar config
└── install.sh                  # Bootstrap script
```

## 🛠️ Individual Scripts

All scripts can be run independently:

### System Scripts
```bash
# Swap partition setup
bash ~/.dotfiles/scripts/system/setup-swap.sh

# Install linux-zen kernel
bash ~/.dotfiles/scripts/system/install-zen-kernel.sh

# Apply performance tweaks
bash ~/.dotfiles/scripts/system/performance-tweaks.sh
```

### Post-Install Scripts
```bash
# Install essential apps
bash ~/.dotfiles/scripts/post-install/essential-apps.sh

# Complete system setup (recommended after fresh install)
bash ~/.dotfiles/scripts/post-install/complete-wizard.sh
```

## 🎯 Optimized For

- **Hardware:** IdeaPad Flex 5 with AMD Radeon graphics
- **OS:** EndeavourOS/Arch Linux
- **DE:** KDE Plasma (Wayland), Sway, Hyprland
- **Use Cases:** 
  - Study (Vitaltrainer Ausbildung)
  - Productivity (Obsidian + calcurse workflow)
  - Development
  - Daily computing

## ⚡ Key Features

- **Modular Design:** Each script serves a specific purpose
- **Error Handling:** Comprehensive validation and recovery
- **User-Friendly:** Clear prompts and progress feedback
- **Safe Operations:** Automatic backups before system changes
- **Network Aware:** Checks connectivity before package operations
- **AMD Optimized:** Specific tweaks for AMD GPUs and laptops

## 🔧 What Gets Installed/Configured

### Complete Wizard Includes:
- System package updates
- Linux-zen kernel for better performance
- AMD GPU optimizations
- TLP power management
- Performance kernel parameters
- Essential applications (browsers, productivity tools)
- Study environment setup
- Development tools (optional)

### Essential Applications:
- **Browsers:** Brave, Falkon, Firefox Developer Edition
- **Productivity:** Obsidian, calcurse, taskwarrior-tui
- **Media:** VLC, mpv
- **System:** btop, ranger, git, curl, archive tools

## 📚 Study Environment

Optimized for Vitaltrainer Ausbildung with automatic setup of:
- Study directories (Anatomie, Physiologie, Trainingslehre, etc.)
- calcurse for exam scheduling
- Obsidian for note-taking
- taskwarrior-tui for task management

## 🔄 Updates

```bash
# Update dotfiles
cd ~/.dotfiles && git pull

# Update individual script
curl -O https://raw.githubusercontent.com/nimmsel23/dotfiles/main/scripts/system/setup-swap.sh
```

## 🤝 Contributing

Feel free to fork and adapt for your own setup. The modular design makes it easy to:
- Add new scripts
- Modify existing functionality
- Share improvements

## ⚠️ Requirements

- EndeavourOS/Arch Linux
- `yay` AUR helper
- Internet connection for package installation
- Minimum 5GB free disk space (for complete setup)

## 📄 License

MIT License - Feel free to use and modify.

---

**Note:** This setup is specifically optimized for my workflow and hardware. Adapt as needed for your system.
EOF
    
    success "README.md created"
}

# Setup GitHub remote repository
setup_remote_repo() {
    log "Setting up GitHub remote repository..."
    
    # Check if remote already exists
    if git remote get-url origin >/dev/null 2>&1; then
        log "Remote 'origin' already configured: $(git remote get-url origin)"
        read -p "Update remote URL? [y/N] " update_remote
        [[ ! $update_remote =~ ^[Yy]$ ]] && return 0
    fi
    
    # Add/update remote
    log "Adding GitHub remote..."
    git remote remove origin 2>/dev/null || true
    git remote add origin git@github.com:nimmsel23/dotfiles.git
    
    success "Remote repository configured"
    
    # Push to GitHub
    echo ""
    echo "🚀 Ready to push to GitHub!"
    echo "Make sure you have created the repository at:"
    echo "   https://github.com/nimmsel23/dotfiles"
    echo ""
    
    read -p "Push to GitHub now? [Y/n] " push_confirm
    if [[ ! $push_confirm =~ ^[Nn]$ ]]; then
        log "Pushing to GitHub..."
        
        # Check if we have commits to push
        if ! git rev-parse HEAD >/dev/null 2>&1; then
            error "No commits found. Create some files first."
            return 1
        fi
        
        # Check current branch
        local current_branch=$(git branch --show-current 2>/dev/null || echo "main")
        log "Pushing branch: $current_branch"
        
        if git push -u origin "$current_branch"; then
            success "Successfully pushed to GitHub!"
            echo ""
            echo "🎉 Repository is now available at:"
            echo "   https://github.com/nimmsel23/dotfiles"
            echo ""
            echo "🔗 One-line installer:"
            echo "   curl -fsSL https://raw.githubusercontent.com/nimmsel23/dotfiles/main/install.sh | bash"
        else
            error "Failed to push to GitHub"
            echo ""
            echo "🔧 Troubleshooting steps:"
            echo ""
            echo "1. Check if repository exists on GitHub:"
            echo "   https://github.com/nimmsel23/dotfiles"
            echo ""
            echo "2. If repository doesn't exist, create it:"
            echo "   https://github.com/new"
            echo "   Repository name: dotfiles"
            echo "   Description: Modular dotfiles for EndeavourOS with KDE Plasma"
            echo "   Make it public"
            echo ""
            echo "3. Test SSH connection:"
            echo "   ssh -T git@github.com"
            echo ""
            echo "4. If SSH fails, check your SSH key:"
            echo "   cat ~/.ssh/id_ed25519.pub"
            echo "   Add it to: https://github.com/settings/ssh/new"
            echo ""
            echo "5. Manual push after fixing:"
            echo "   git push -u origin $current_branch"
            
            return 1
        fi
    fi
}

# Main execution
main() {
    if setup_git_repo; then
        echo ""
        success "Git repository setup completed!"
        echo ""
        echo "Next steps:"
        echo "• Test the one-line installer on a fresh system"
        echo "• Add any missing scripts as needed"
        echo "• Share with others: https://github.com/nimmsel23/dotfiles"
    else
        error "Git repository setup failed"
        exit 1
    fi
}

# Run main function
main "$@"
