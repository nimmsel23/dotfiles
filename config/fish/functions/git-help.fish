function git-help --description "Quick reference for git-sync-enforcer & safe push commands"
    set_color cyan
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Git Sync & Safe Push - Quick Reference  "
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color normal
    echo ""

    set_color yellow
    echo "🔍 Status Checks:"
    set_color normal
    echo "  repos           - Pretty repo status (recommended)"
    echo "  gses            - Raw git-sync-enforcer status"
    echo "  gsev            - Verify all remotes configured"
    echo ""

    set_color yellow
    echo "🚀 Safe Push:"
    set_color normal
    echo "  gsafe           - Push with pre-flight check"
    echo "  gq 'message'    - Quick add→commit→push"
    echo "  gpn             - Push with Telegram notification"
    echo ""

    set_color yellow
    echo "🔧 Sync Operations:"
    set_color normal
    echo "  gsee            - Sync all repos (fetch, pull, push)"
    echo "  vs              - Vault-sync (AlphaOs-Vault only)"
    echo "  vst             - Vault-sync status"
    echo ""

    set_color yellow
    echo "⚙️  Setup Commands:"
    set_color normal
    echo "  gseh            - Install git hooks (Telegram notifications)"
    echo "  gsevs           - Setup vault auto-sync timer"
    echo ""

    set_color yellow
    echo "🤖 ClaudeWarrior:"
    set_color normal
    echo "  cw              - ClaudeWarrior CLI"
    echo "  cws             - ClaudeWarrior status"
    echo "  cwsync          - Sync tasks to calendar"
    echo ""

    set_color cyan
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color normal
    echo ""

    set_color green
    echo "💡 Recommended Workflow:"
    set_color normal
    echo "  1. repos         (Check status)"
    echo "  2. ga            (Add changes)"
    echo "  3. gc 'message'  (Commit)"
    echo "  4. gsafe         (Safe push with check)"
    echo ""

    set_color blue
    echo "Auto-Check (optional):"
    set_color normal
    echo "  Edit: ~/.config/fish/conf.d/git-sync-auto.fish"
    echo "  Uncomment functions to enable auto-checks"
end
