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

Multiple session manager interfaces available for different use cases:

### Blessed.js TUI Interface (TTY3)
Modern terminal user interface with visual focus indicators:
```bash
# Auto-launches on TTY3 (Ctrl+Alt+F3)
session-manager-tui
```

**Features:**
- Professional ASCII interface without emoji (TTY-compatible)
- Auto-detects installed desktop environments (KDE, Sway, Hyprland, COSMIC, XFCE, i3)
- CLI tools integration (calcurse, taskwarrior-tui, btop, ranger, neovim)
- System actions (Recovery Wizard, Telegram Setup, System Status)
- TAB navigation with visual focus indicators
- Built-in help system (F1 key)
- ESC key launches bash fallback

### Modular Bash Interface
Performance-optimized with on-demand loading:
```bash
session-manager-modular
```

### Ultra-Fast Launcher
Minimal desktop selector (0.003s startup):
```bash
session-manager-fast
```

## 📁 Repository Structure

```
├── scripts/
│   ├── session-manager           # Main bash launcher
│   ├── session-manager-tui.js    # Blessed.js TUI interface
│   ├── session-manager-modular   # Performance optimized
│   ├── session-manager-fast      # Ultra-fast launcher
│   ├── utils/
│   │   ├── common.sh            # Shared functions
│   │   └── telegram/tele.sh     # Telegram CLI
│   ├── system/
│   │   ├── setup-swap.sh        # Swap partition setup
│   │   ├── install-zen-kernel.sh # Kernel management
│   │   ├── performance-tweaks.sh # Laptop optimizations
│   │   └── setup-tty3-session-manager.sh # TTY3 configuration
│   └── post-install/
│       ├── essential-apps.sh    # Core applications
│       ├── complete-wizard.sh   # Full system setup
│       └── recovery-wizard.sh   # Post-reinstall recovery
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

# Post-reinstall recovery wizard (rclone, telegram, apps)
bash ~/.dotfiles/scripts/post-install/recovery-wizard.sh
```

### Session Manager Setup
```bash
# Setup TTY3 auto-launch for TUI interface
bash ~/.dotfiles/scripts/system/setup-tty3-session-manager.sh

# Setup telegram CLI integration
bash ~/.dotfiles/scripts/utils/telegram/tele.sh --setup
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
