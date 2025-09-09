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

# Launch session manager
session-manager
```

### Individual Script Execution
```bash
# System scripts
bash ~/.dotfiles/scripts/system/setup-swap.sh          # Setup swap partition
bash ~/.dotfiles/scripts/system/install-zen-kernel.sh  # Install linux-zen kernel
bash ~/.dotfiles/scripts/system/performance-tweaks.sh  # Apply laptop optimizations
bash ~/.dotfiles/scripts/system/amd-optimization.sh    # AMD GPU optimizations
bash ~/.dotfiles/scripts/system/system-update.sh       # System package updates
bash ~/.dotfiles/scripts/system/setup-cronie.sh        # Setup cron daemon for scheduled tasks

# Utility scripts
bash ~/.dotfiles/scripts/utils/rclone-desktop-sync.sh  # Bidirectional Desktop cloud sync

# Post-install scripts
bash ~/.dotfiles/scripts/post-install/essential-apps.sh    # Install core applications
bash ~/.dotfiles/scripts/post-install/dev-environment.sh   # Development environment setup
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
- AMD Radeon graphics (GPU driver configuration)
- Laptop power management (TLP configuration)
- IdeaPad Flex 5 specific tweaks (thermal management, performance profiles)
- Wayland compositor support (Sway, Hyprland, KDE Plasma Wayland)

## Requirements
- EndeavourOS/Arch Linux base system
- `yay` AUR helper installed
- Internet connection for package installation
- Minimum 5GB free disk space for complete setup
- User with sudo privileges (scripts check and refuse to run as root)
- Optional: rclone for Desktop synchronization features