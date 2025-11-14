function backup --description "Quick backup of important files"
    set -l item $argv[1]

    if test -z "$item"
        echo "💾 Backup Utility"
        echo ""
        echo "Usage:"
        echo "  backup <file/directory>   # Create timestamped backup"
        echo "  backup vault              # Sync AlphaOs-Vault to GitHub"
        echo "  backup dots               # Sync dotfiles to GitHub"
        echo ""
        return 1
    end

    switch $item
        case vault
            echo "💾 Backing up AlphaOs-Vault..."
            vault-sync

        case dots dotfiles
            echo "💾 Backing up dotfiles..."
            cd ~/.dotfiles
            git-quick "Backup: (date +%Y-%m-%d\ %H:%M)"

        case '*'
            # File/directory backup
            if not test -e $item
                echo "❌ File/directory not found: $item"
                return 1
            end

            set -l timestamp (date +%Y%m%d_%H%M%S)
            set -l backup_name "$item.backup_$timestamp"

            cp -r $item $backup_name
            echo "✅ Backup created: $backup_name"
    end
end
