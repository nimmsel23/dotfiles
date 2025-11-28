function git-safe-push --description "Safe git push with gum UI"
    # Header
    gum style \
        --border rounded \
        --border-foreground 117 \
        --padding "0 2" \
        --margin "1" \
        "🔒 GIT SAFE PUSH - Pre-flight Check"

    # Get current repo
    set -l repo_name (basename (git rev-parse --show-toplevel 2>/dev/null))

    if test -z "$repo_name"
        gum style --foreground 196 "❌ Not in a git repository"
        return 1
    end

    gum style --foreground 117 "📦 Repository: $repo_name"
    echo ""

    # Run sync check with spinner
    gum spin --spinner dot --title "Checking all repos..." -- sleep 0.5

    set -l status_output (git-sync-enforcer status 2>&1)

    # Show status
    echo "$status_output" | while read -l line
        if string match -q "*Clean*" $line
            gum style --foreground 46 "  ✓ $line"
        else if string match -q "*CRITICAL*" $line
            gum style --foreground 196 "  ✗ $line"
        else if string match -q "*⚠*" $line
            gum style --foreground 226 "  ⚠ $line"
        else if not string match -q "*Recommendation*" $line
            echo "  $line"
        end
    end

    echo ""

    # Confirm push
    if not gum confirm "Continue with push to $repo_name?"
        gum style --foreground 226 "⏸️  Push cancelled"
        return 1
    end

    # Push with spinner
    gum spin --spinner dot --title "Pushing to origin..." -- git push

    if test $status -eq 0
        gum style \
            --border double \
            --border-foreground 46 \
            --padding "0 2" \
            --margin "1" \
            "✅ Push successful!"

        # Check for telegram hook
        if test -L .git/hooks/post-push
            gum style --foreground 117 "📱 Telegram notification sent"
        end
    else
        gum style \
            --border double \
            --border-foreground 196 \
            --padding "0 2" \
            "❌ Push failed"
        return 1
    end
end
