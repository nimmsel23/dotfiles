function git-sync-check --description "Quick git sync status check"
    # Shorter, cleaner wrapper around git-sync-enforcer status
    set_color blue
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "       Git Sync Status Check        "
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color normal
    echo ""

    git-sync-enforcer status

    echo ""
    set_color blue
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color normal

    # Quick tips
    echo ""
    set_color yellow
    echo "💡 Quick commands:"
    set_color normal
    echo "  gse status    - This check"
    echo "  gse verify    - Check remotes"
    echo "  gse enforce   - Sync all repos"
    echo "  gsafe         - Safe push with check"
end
