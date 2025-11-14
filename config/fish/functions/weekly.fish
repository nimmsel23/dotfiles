function weekly --description "AlphaOS Weekly Review Workflow"
    echo "📅 AlphaOS Weekly Review"
    echo "══════════════════════════════════"
    echo ""

    # Get current week
    set -l week_num (date +%V)
    set -l year (date +%Y)

    echo "Week $week_num, $year"
    echo ""

    # Show last week's tent review (if exists)
    set -l last_tent (ls -t ~/AlphaOs-Vault/GAME/Tent/*.md 2>/dev/null | head -1)
    if test -n "$last_tent"
        echo "📋 Last Tent Review: "(basename $last_tent)
        echo "   (run 'tent' to create new one)"
    else
        echo "📋 No previous Tent reviews found"
        echo "   (run 'tent' to start your first one)"
    end

    echo ""

    # Show recent Frame Maps
    echo "🗺️  Recent Frame Maps:"
    ls -t ~/AlphaOs-Vault/GAME/Frame/*.md 2>/dev/null | head -3 | while read map
        echo "   - "(basename $map)
    end

    echo ""

    # Show uncommitted changes in vault
    if test -d ~/AlphaOs-Vault/.git
        cd ~/AlphaOs-Vault
        set -l changes (git status --short | wc -l)
        if test $changes -gt 0
            echo "⚠️  Uncommitted changes: $changes files"
            echo "   (run 'vs' to sync to GitHub)"
        else
            echo "✅ Vault is synced"
        end
    end

    echo ""
    echo "💡 Weekly workflow:"
    echo "   1. tent        → Create weekly review"
    echo "   2. note        → Capture quick ideas"
    echo "   3. frame       → Update current reality"
    echo "   4. vs          → Sync to GitHub"
end
