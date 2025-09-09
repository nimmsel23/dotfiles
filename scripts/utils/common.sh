#!/bin/bash

# Common functions for nimmsel23's dotfiles scripts
# Source this file in other scripts: source ~/.dotfiles/scripts/utils/common.sh

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling
set -o pipefail

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    local missing_deps=()
    
    # Check for yay
    if ! command_exists yay; then
        missing_deps+=("yay")
    fi
    
    # Check for sudo
    if ! command_exists sudo; then
        missing_deps+=("sudo")
    fi
    
    # Check if user has sudo privileges
    if ! sudo -v 2>/dev/null; then
        error "User does not have sudo privileges"
        return 1
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies and try again."
        return 1
    fi
    
    return 0
}

# Function to check network connectivity
check_network() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        warning "No network connectivity detected"
        echo "Some features may not work without internet access."
        read -p "Continue anyway? [y/N] " confirm
        [[ ! $confirm =~ ^[Yy]$ ]] && return 1
    fi
    return 0
}

# Function to check disk space (requires at least 2GB free)
check_disk_space() {
    local required_space=2000000  # 2GB in KB
    local available_space=$(df / | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        error "Insufficient disk space. Required: 2GB, Available: $((available_space/1000))MB"
        return 1
    fi
    return 0
}

# Safe package installation with error handling
install_packages() {
    local packages=("$@")
    local failed_packages=()
    
    if [ ${#packages[@]} -eq 0 ]; then
        error "No packages specified for installation"
        return 1
    fi
    
    log "Installing packages: ${packages[*]}"
    
    # Check each package individually first
    for package in "${packages[@]}"; do
        if ! yay -Si "$package" >/dev/null 2>&1; then
            warning "Package '$package' not found in repositories"
            failed_packages+=("$package")
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        warning "The following packages were not found: ${failed_packages[*]}"
        read -p "Continue with remaining packages? [y/N] " confirm
        [[ ! $confirm =~ ^[Yy]$ ]] && return 1
        
        # Remove failed packages from installation list
        for failed in "${failed_packages[@]}"; do
            packages=("${packages[@]/$failed}")
        done
    fi
    
    # Install remaining packages
    if [ ${#packages[@]} -gt 0 ]; then
        if yay -S --needed --noconfirm "${packages[@]}" 2>/dev/null; then
            success "Successfully installed: ${packages[*]}"
            return 0
        else
            error "Failed to install some packages: ${packages[*]}"
            return 1
        fi
    fi
    
    return 0
}

# Validate user input for numerical choices
validate_choice() {
    local input="$1"
    local max_choice="$2"
    
    # Check if input is a number
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Check if input is within valid range
    if [ "$input" -lt 0 ] || [ "$input" -gt "$max_choice" ]; then
        return 1
    fi
    
    return 0
}

# Safe file operations with backup
safe_edit_file() {
    local file="$1"
    local backup_suffix=".dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -f "$file" ]; then
        if ! sudo cp "$file" "${file}${backup_suffix}"; then
            error "Failed to create backup of $file"
            return 1
        fi
        log "Created backup: ${file}${backup_suffix}"
    fi
    
    return 0
}

# Script header for consistent output
script_header() {
    local script_name="$1"
    local description="$2"
    
    clear
    echo "═══════════════════════════════════════════"
    echo "🔧 $script_name"
    echo "═══════════════════════════════════════════"
    if [ -n "$description" ]; then
        echo "$description"
        echo ""
    fi
}

# Script footer with return prompt
script_footer() {
    local success_msg="$1"
    
    echo ""
    if [ -n "$success_msg" ]; then
        success "$success_msg"
    fi
    
    echo "Press Enter to return to session manager..."
    read
}

# Check if running in dotfiles environment
check_dotfiles_env() {
    if [ ! -d "$HOME/.dotfiles" ]; then
        error "Dotfiles not found. Install with:"
        echo "curl -fsSL https://raw.githubusercontent.com/nimmsel23/dotfiles/main/install.sh | bash"
        return 1
    fi
    return 0
}

# Get system information
get_system_info() {
    echo "System: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Shell: $SHELL"
    echo "User: $USER"
    
    if command_exists lsb_release; then
        echo "Distribution: $(lsb_release -d | cut -f2-)"
    elif [ -f /etc/os-release ]; then
        echo "Distribution: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    fi
    
    if command_exists free; then
        echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    fi
    
    if command_exists df; then
        echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
    fi
}

# Exit handler for cleanup
cleanup_and_exit() {
    local exit_code=${1:-0}
    log "Script completed with exit code: $exit_code"
    exit $exit_code
}

# Trap for cleanup
trap 'cleanup_and_exit $?' EXIT