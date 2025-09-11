#!/bin/bash

# Dotfiles Symlink Management Script
# Part of nimmsel23's dotfiles system scripts
# Manages symlinks for essential dotfiles
# Usage: bash ~/.dotfiles/scripts/utils/manage-dotfiles-symlinks.sh

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Dotfiles configuration mapping
declare -A DOTFILES_MAP=(
    # Bash configuration
    ["$HOME/.bashrc"]="$HOME/.dotfiles/config/bash/bashrc"
    ["$HOME/.bash_profile"]="$HOME/.dotfiles/config/bash/bash_profile"
    ["$HOME/.bash_aliases"]="$HOME/.dotfiles/config/bash/bash_aliases"
    
    # Git configuration
    ["$HOME/.gitconfig"]="$HOME/.dotfiles/config/git/gitconfig"
    ["$HOME/.gitignore_global"]="$HOME/.dotfiles/config/git/gitignore_global"
    
    # SSH configuration
    ["$HOME/.ssh/config"]="$HOME/.dotfiles/config/ssh/config"
    
    # Vim configuration
    ["$HOME/.vimrc"]="$HOME/.dotfiles/config/vim/vimrc"
    
    # Shell configuration
    ["$HOME/.profile"]="$HOME/.dotfiles/config/shell/profile"
    ["$HOME/.inputrc"]="$HOME/.dotfiles/config/shell/inputrc"
)

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    local dirs=(
        "$HOME/.dotfiles/config/bash"
        "$HOME/.dotfiles/config/git" 
        "$HOME/.dotfiles/config/ssh"
        "$HOME/.dotfiles/config/vim"
        "$HOME/.dotfiles/config/shell"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log "Created directory: $dir"
        fi
    done
}

# Backup existing files
backup_existing_files() {
    local backup_dir="$HOME/.dotfiles/backups/symlink-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log "Backing up existing files to: $backup_dir"
    
    for target in "${!DOTFILES_MAP[@]}"; do
        if [ -f "$target" ] && [ ! -L "$target" ]; then
            log "Backing up: $target"
            cp "$target" "$backup_dir/$(basename "$target")"
        fi
    done
    
    echo "$backup_dir"
}

# Create dotfiles symlinks
create_symlinks() {
    local force="$1"
    local created=0
    local skipped=0
    local errors=0
    
    log "Creating dotfiles symlinks..."
    
    for target in "${!DOTFILES_MAP[@]}"; do
        local source="${DOTFILES_MAP[$target]}"
        
        # Skip if source doesn't exist
        if [ ! -f "$source" ]; then
            warning "Source file missing: $source (skipping)"
            ((skipped++))
            continue
        fi
        
        # Handle existing files/symlinks
        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ -L "$target" ]; then
                local current_target=$(readlink "$target")
                if [ "$current_target" = "$source" ]; then
                    log "✅ Already linked: $(basename "$target")"
                    continue
                else
                    log "🔄 Updating symlink: $(basename "$target")"
                    rm "$target"
                fi
            else
                if [ "$force" = "true" ]; then
                    log "🔄 Replacing existing file: $(basename "$target")"
                    rm "$target"
                else
                    error "❌ File exists (use --force to replace): $target"
                    ((errors++))
                    continue
                fi
            fi
        fi
        
        # Create parent directory if needed
        local target_dir=$(dirname "$target")
        [ ! -d "$target_dir" ] && mkdir -p "$target_dir"
        
        # Create symlink
        if ln -s "$source" "$target"; then
            success "✅ Linked: $(basename "$target")"
            ((created++))
        else
            error "❌ Failed to link: $(basename "$target")"
            ((errors++))
        fi
    done
    
    echo ""
    echo "Symlink Creation Summary:"
    echo "═══════════════════════════"
    echo "  Created: $created"
    echo "  Skipped: $skipped" 
    echo "  Errors:  $errors"
    
    return $errors
}

# Remove dotfiles symlinks
remove_symlinks() {
    local removed=0
    local not_found=0
    
    log "Removing dotfiles symlinks..."
    
    for target in "${!DOTFILES_MAP[@]}"; do
        if [ -L "$target" ]; then
            local source="${DOTFILES_MAP[$target]}"
            local current_target=$(readlink "$target")
            
            if [ "$current_target" = "$source" ]; then
                rm "$target"
                success "✅ Removed: $(basename "$target")"
                ((removed++))
            else
                warning "⚠️ Symlink points elsewhere: $(basename "$target") -> $current_target"
            fi
        elif [ -e "$target" ]; then
            warning "⚠️ Not a symlink: $(basename "$target")"
        else
            log "Not found: $(basename "$target")"
            ((not_found++))
        fi
    done
    
    echo ""
    echo "Symlink Removal Summary:"
    echo "══════════════════════════"
    echo "  Removed:   $removed"
    echo "  Not found: $not_found"
}

# Show current status
show_status() {
    log "Dotfiles Symlink Status:"
    echo "═══════════════════════════"
    echo ""
    
    for target in "${!DOTFILES_MAP[@]}"; do
        local source="${DOTFILES_MAP[$target]}"
        local basename_target=$(basename "$target")
        
        if [ -L "$target" ]; then
            local current_target=$(readlink "$target")
            if [ "$current_target" = "$source" ]; then
                success "✅ $basename_target -> dotfiles"
            else
                warning "⚠️ $basename_target -> $current_target (incorrect)"
            fi
        elif [ -f "$target" ]; then
            error "❌ $basename_target (regular file, not symlinked)"
        elif [ -f "$source" ]; then
            warning "⚠️ $basename_target (missing, source exists)"
        else
            log "➖ $basename_target (missing, no source)"
        fi
    done
}

# Migrate existing file to dotfiles
migrate_file() {
    local file_path="$1"
    
    if [ -z "$file_path" ]; then
        error "Please specify a file path to migrate"
        return 1
    fi
    
    # Expand ~ to home directory
    file_path="${file_path/#\~/$HOME}"
    
    if [ ! -f "$file_path" ]; then
        error "File not found: $file_path"
        return 1
    fi
    
    # Check if it's already in our mapping
    local target_source="${DOTFILES_MAP[$file_path]}"
    if [ -n "$target_source" ]; then
        log "File is already configured for dotfiles management"
        
        if [ -f "$target_source" ]; then
            warning "Target already exists: $target_source"
            read -p "Overwrite? [y/N] " confirm
            [[ ! $confirm =~ ^[Yy]$ ]] && return 1
        fi
        
        # Create target directory if needed
        local target_dir=$(dirname "$target_source")
        [ ! -d "$target_dir" ] && mkdir -p "$target_dir"
        
        # Move file to dotfiles
        mv "$file_path" "$target_source"
        success "Moved: $file_path -> $target_source"
        
        # Create symlink
        ln -s "$target_source" "$file_path"
        success "Created symlink: $file_path"
        
        return 0
    else
        error "File not in dotfiles configuration: $file_path"
        echo "Add it to DOTFILES_MAP in this script first"
        return 1
    fi
}

# Interactive menu
interactive_menu() {
    echo "Dotfiles Symlink Management:"
    echo "═══════════════════════════"
    echo "  [1] Show current status"
    echo "  [2] Create all symlinks"
    echo "  [3] Create symlinks (force replace)"
    echo "  [4] Remove all symlinks"
    echo "  [5] Migrate existing file"
    echo "  [0] Exit"
    echo ""
    
    read -p "Choose option: " choice
    
    case "$choice" in
        1)
            show_status
            ;;
        2)
            create_directories
            backup_dir=$(backup_existing_files)
            create_symlinks false
            echo "Backup created: $backup_dir"
            ;;
        3)
            create_directories
            backup_dir=$(backup_existing_files)
            create_symlinks true
            echo "Backup created: $backup_dir"
            ;;
        4)
            remove_symlinks
            ;;
        5)
            read -p "Enter file path to migrate: " file_path
            migrate_file "$file_path"
            ;;
        0)
            log "Exiting..."
            return 0
            ;;
        *)
            error "Invalid choice"
            return 1
            ;;
    esac
}

# Main function
main() {
    script_header "Dotfiles Symlink Manager" "Manage symlinks for essential configuration files"
    
    if ! check_dotfiles_env; then
        exit 1
    fi
    
    case "${1:-}" in
        --status|-s)
            show_status
            ;;
        --create|-c)
            create_directories
            backup_dir=$(backup_existing_files)
            create_symlinks false
            echo "Backup created: $backup_dir"
            ;;
        --force|-f)
            create_directories
            backup_dir=$(backup_existing_files)
            create_symlinks true
            echo "Backup created: $backup_dir"
            ;;
        --remove|-r)
            remove_symlinks
            ;;
        --migrate|-m)
            migrate_file "$2"
            ;;
        --help|-h)
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  -s, --status    Show current symlink status"
            echo "  -c, --create    Create all symlinks (backup existing)"
            echo "  -f, --force     Create symlinks (force replace existing)"
            echo "  -r, --remove    Remove all dotfiles symlinks"
            echo "  -m, --migrate   Migrate existing file to dotfiles"
            echo "  -h, --help      Show this help"
            echo ""
            echo "Interactive mode: Run without arguments"
            ;;
        "")
            interactive_menu
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    
    script_footer "Dotfiles Symlink Manager"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi