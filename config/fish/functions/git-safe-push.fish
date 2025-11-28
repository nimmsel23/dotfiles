function git-safe-push --description "Safe git push with sync check"
    echo "🔒 Git Safe Push - Pre-flight Check"
    echo ""

    # Run git-sync-enforcer status
    echo "📊 Checking all repos..."
    git-sync-enforcer status

    echo ""
    echo "─────────────────────────────────────"
    echo ""

    # Ask user to proceed
    read -P "Continue with push? [Y/n] " -l confirm

    if test "$confirm" = "n" -o "$confirm" = "N"
        echo "⏸️  Push cancelled"
        return 1
    end

    # Get current repo name
    set -l repo_name (basename (git rev-parse --show-toplevel 2>/dev/null))

    if test -z "$repo_name"
        echo "❌ Not in a git repository"
        return 1
    end

    echo "🚀 Pushing $repo_name..."
    if git push
        echo ""
        echo "✅ Push successful!"

        # Check if telegram notification hook exists
        if test -L .git/hooks/post-push
            echo "📱 Telegram notification sent"
        end
    else
        echo ""
        echo "⚠️  Push failed"
        return 1
    end
end
