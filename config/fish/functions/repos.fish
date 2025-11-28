function repos --description "Quick access to repo health check with gum"
    # Header
    gum style \
        --border double \
        --border-foreground 212 \
        --padding "0 2" \
        --margin "1" \
        --align center \
        "GIT SYNC STATUS"

    # Get repo status
    set -l status_output (git-sync-enforcer status 2>&1)

    # Parse and display with gum
    echo "$status_output" | while read -l line
        if string match -q "*Clean*" $line
            gum style --foreground 46 "  ✓ $line"
        else if string match -q "*CRITICAL*" $line
            gum style --foreground 196 --bold "  ✗ $line"
        else if string match -q "*⚠*" $line
            gum style --foreground 226 "  ⚠ $line"
        else if not string match -q "*Recommendation*" $line
            echo "  $line"
        end
    end

    echo ""

    # Quick actions menu
    gum style \
        --foreground 117 \
        --margin "1 0" \
        "💡 Quick Actions:"

    set -l choice (gum choose \
        "📊 Detailed Status" \
        "🔍 Verify Remotes" \
        "🔄 Sync All Repos" \
        "⚙️  Setup Hooks" \
        "❌ Exit" \
        --header "Select action (or Ctrl+C to exit)")

    switch "$choice"
        case "📊 Detailed Status"
            git-sync-enforcer status
        case "🔍 Verify Remotes"
            git-sync-enforcer verify
        case "🔄 Sync All Repos"
            if gum confirm "Sync all repositories now?"
                gum spin --spinner dot --title "Syncing repos..." -- git-sync-enforcer enforce
            end
        case "⚙️  Setup Hooks"
            if gum confirm "Install git hooks with Telegram notifications?"
                git-sync-enforcer setup-hooks
            end
        case "❌ Exit"
            return 0
    end
end
