function alphaos --description "AlphaOS quick launcher"
    set -l action $argv[1]

    switch $action
        case frame
            echo "🗺️  Opening Frame Map..."
            frame
        case freedom
            echo "🎯 Opening Freedom Map..."
            freedom
        case tent
            echo "⛺ Opening General's Tent..."
            tent
        case fruits
            echo "🍇 Opening FRUITS CLI..."
            fruits
        case vault
            cd ~/AlphaOs-Vault && ls -lh
        case status
            echo "📊 AlphaOS Status"
            echo ""
            echo "🗂️  Last Frame Map:"
            ls -t ~/AlphaOs-Vault/GAME/Frame/*.md 2>/dev/null | head -1 | xargs basename
            echo "🎯 Last Freedom Map:"
            ls -t ~/AlphaOs-Vault/GAME/Freedom/*.md 2>/dev/null | head -1 | xargs basename
            echo "⛺ Last Tent Review:"
            ls -t ~/AlphaOs-Vault/GAME/Tent/*.md 2>/dev/null | head -1 | xargs basename
            echo ""
            vault-sync status
        case sync
            vault-sync
        case check
            vault-sync check
        case '*'
            echo "🔥 AlphaOS Command Center"
            echo ""
            echo "Usage: alphaos [command]"
            echo ""
            echo "Commands:"
            echo "  frame       Run Frame Map (Wo stehe ich?)"
            echo "  freedom     Run Freedom Map (Wo will ich hin?)"
            echo "  tent        Run General's Tent (Weekly Review)"
            echo "  fruits      Run FRUITS CLI (Foundational Facts)"
            echo "  vault       Go to AlphaOs-Vault directory"
            echo "  status      Show AlphaOS system status"
            echo "  sync        Sync vault to GitHub"
            echo "  check       Verify symlinks"
            echo ""
            echo "💡 Quick shortcuts: frame, freedom, tent, fruits, vs"
    end
end
