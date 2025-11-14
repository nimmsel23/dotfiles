function git-quick --description "Quick git commit and push workflow"
    if test (count $argv) -eq 0
        echo "❌ Commit message required"
        echo "Usage: git-quick 'commit message'"
        return 1
    end

    set -l commit_msg $argv[1]

    echo "📦 Git Quick Workflow"
    echo ""

    # Status
    echo "📊 Status:"
    git status --short

    # Add all
    echo ""
    echo "➕ Adding all changes..."
    git add -A

    # Commit
    echo ""
    echo "💾 Committing: $commit_msg"
    git commit -m "$commit_msg"

    # Push
    echo ""
    echo "🚀 Pushing to remote..."
    if git push
        echo ""
        echo "✅ Done! Changes pushed successfully."
    else
        echo ""
        echo "⚠️  Push failed. Check your remote."
        return 1
    end
end
