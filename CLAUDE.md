# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a modular dotfiles system optimized for EndeavourOS/Arch Linux with KDE Plasma, specifically configured for IdeaPad Flex 5 with AMD Radeon graphics. The system provides automated setup scripts, session management, and configuration management for Linux desktop environments.

## Common Commands

### Installation and Setup
```bash
# Install entire dotfiles system
curl -fsSL https://raw.githubusercontent.com/nimmsel23/dotfiles/main/install.sh | bash

# Run complete system setup wizard (post-install)
bash ~/.dotfiles/scripts/post-install/complete-wizard.sh

# Post-reinstall recovery wizard (rclone, telegram, apps)
bash ~/.dotfiles/scripts/post-install/recovery-wizard.sh

# Launch session managers
session-manager                 # Main bash launcher
session-manager-tui             # Blessed.js TUI interface (TTY3)
session-manager-modular         # Performance optimized
session-manager-fast            # Ultra-fast launcher (0.003s startup)
```

### Individual Script Execution
```bash
# System scripts
bash ~/.dotfiles/scripts/system/setup-swap.sh              # Setup swap partition
bash ~/.dotfiles/scripts/system/install-zen-kernel.sh      # Install linux-zen kernel
bash ~/.dotfiles/scripts/system/performance-tweaks.sh      # Apply laptop optimizations
bash ~/.dotfiles/scripts/system/amd-optimization.sh        # AMD GPU optimizations
bash ~/.dotfiles/scripts/system/system-update.sh           # System package updates
bash ~/.dotfiles/scripts/system/setup-cronie.sh            # Setup cron daemon
bash ~/.dotfiles/scripts/system/systemd-timer-manager.sh   # Manage systemd timers
bash ~/.dotfiles/scripts/system/setup-timeshift.sh         # Setup Timeshift snapshots
bash ~/.dotfiles/scripts/system/setup-tty3-session-manager.sh  # TTY3 auto-launch

# Utility scripts
bash ~/.dotfiles/scripts/utils/rclone-desktop-sync.sh init   # Initialize Desktop sync
bash ~/.dotfiles/scripts/utils/rclone-desktop-sync.sh sync   # Run manual sync
bash ~/.dotfiles/scripts/utils/rclone-desktop-sync.sh status # Check sync status
bash ~/.dotfiles/scripts/utils/telegram/tele.sh --setup      # Setup Telegram CLI

# Post-install scripts
bash ~/.dotfiles/scripts/post-install/essential-apps.sh    # Install core applications
bash ~/.dotfiles/scripts/post-install/dev-environment.sh   # Development environment
bash ~/.dotfiles/scripts/post-install/study-setup.sh       # Study environment (Vitaltrainer)
bash ~/.dotfiles/scripts/post-install/multimedia.sh        # Multimedia codecs
```

### Development Commands
The system uses standard package management:
```bash
# Package installation (uses yay AUR helper)
yay -S package-name

# System update
yay -Syu

# Check package info
yay -Si package-name
```

## Architecture

### Script Organization
- **scripts/utils/common.sh**: Shared utility functions used by all scripts
  - Color-coded logging functions (`log`, `success`, `error`, `warning`)
  - Package installation with error handling (`install_packages`)
  - System validation (`check_requirements`, `check_network`, `check_disk_space`)
  - Safe file operations with automatic backup (`safe_edit_file`)
  
- **scripts/system/**: System-level configuration scripts
  - Hardware-specific optimizations (AMD GPU, laptop performance)
  - Kernel management (linux-zen installation)
  - System service configuration (swap, performance tweaks)

- **scripts/post-install/**: Application and environment setup
  - Modular application installation scripts
  - Study environment with directory structure for Vitaltrainer Ausbildung
  - Development environment with tools and configurations

- **scripts/utils/**: Utility scripts for maintenance and sync
  - rclone-desktop-sync.sh: Bidirectional Desktop cloud synchronization with safety checks
  - common.sh: Shared functions for all scripts

- **scripts/session-manager**: Interactive CLI launcher
  - Auto-detects available desktop environments (KDE, Sway, Hyprland, COSMIC)
  - Quick access to CLI tools (calcurse, taskwarrior-tui, btop, ranger)
  - Direct script execution interface

### Key Components

#### Common Functions Pattern
All scripts source `scripts/utils/common.sh` for consistent behavior:
- Error handling with `set -o pipefail`
- Standardized logging with timestamps and color coding
- Package installation with validation and retry logic
- Automatic backup creation before system file modifications
- Network connectivity checks before remote operations

#### Wizard System
The `complete-wizard.sh` implements a step-by-step setup process:
- Pre-flight system validation
- Modular step execution with progress tracking
- Error recovery and step skipping capabilities
- Comprehensive system optimization for IdeaPad Flex 5 hardware

#### Session Management
The session manager provides a unified interface for:
- Desktop environment launching with proper environment variables
- CLI tool access with automatic return to menu
- System script execution with status feedback
- Hardware-specific optimizations

### Configuration Management
- **config/fish/**: Fish shell configuration
- **config/calcurse/**: Calendar application settings for study scheduling
- **config/hypr/**: Hyprland window manager configurations
  - **modules/**: Modular Hyprland config (hardware.conf, keybinds.conf, decoration.conf, etc.)
  - IdeaPad Flex 5 specific: touchpad gestures, AMD GPU optimizations, AT/DE keyboard layout
  - Merge strategy: nwg-shell base config + modular enhancements
- **config/rclone/**: Cloud storage sync configurations
- **templates/**: Template files for various configurations

### Key Features

#### Automated Task Scheduling
- **setup-cronie.sh**: Comprehensive cron daemon setup
  - Installs and configures cronie with systemd service
  - Creates template crontab with common tasks (system updates, backups, cleanup)
  - Interactive crontab editor with multiple editor options
  - Automatic log rotation and error handling
  - Test functionality to validate cron setup

#### Cloud Synchronization  
- **rclone-desktop-sync.sh**: Bidirectional Desktop folder sync
  - Uses rclone bisync for safe two-way synchronization
  - Configurable with any rclone-supported cloud provider (Google Drive, OneDrive, etc.)
  - Safety features: max-delete limits, lock files, comprehensive logging
  - Automatic cron job setup with flexible scheduling options
  - Telegram notifications for sync status (if configured)

### Hardware Optimizations
The system includes specific optimizations for:
- **AMD Radeon graphics**: Vulkan RADV driver, WLR environment variables for Wayland compositors
- **Laptop power management**: TLP configuration with laptop-specific profiles
- **IdeaPad Flex 5 tweaks**: 3-finger workspace swipe gestures, touchpad tap-to-click, convertible mode support
- **Wayland compositors**: Native support for Sway, Hyprland (including nwg-shell), KDE Plasma Wayland, COSMIC
- **Keyboard layout**: AT/DE layout with nodeadkeys variant, ALT+SHIFT to toggle

### Hyprland Configuration Strategy
When working with Hyprland configs in this repository:
- **Active config**: `~/.config/hypr/hyprland.conf` (merged nwg-shell + modular enhancements)
- **Modular source**: `~/.dotfiles/config/hypr/modules/` (hardware.conf, keybinds.conf, etc.)
- **Backup before changes**: Always create timestamped backups of hyprland.conf
- **Keybind conflicts**: Check for conflicts between nwg-shell and custom keybinds (e.g., SUPER+L for lock)
- **Theme notes**: Nord color scheme available but commented out by default
- **Testing changes**: Reload with `hyprctl reload` or restart Hyprland session

## Requirements
- EndeavourOS/Arch Linux base system
- `yay` AUR helper installed
- Internet connection for package installation
- Minimum 5GB free disk space for complete setup
- User with sudo privileges (scripts check and refuse to run as root)
- Optional: rclone for Desktop synchronization features