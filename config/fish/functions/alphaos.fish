function alphaos --description "AlphaOS DOMINION Status & Commands"
    # If no arguments, show status
    if test (count $argv) -eq 0
        alphaos_status
        return
    end

    # Subcommands
    switch $argv[1]
        case status
            alphaos_status

        case domains
            echo "AlphaOS 4 Domains:"
            echo "  💼 BUSINESS - Authority, Monetization, Teaching"
            echo "  💪 BODY     - Training, Fuel, Recovery"
            echo "  🧘 BEING    - Meditation, Philosophy, Integration"
            echo "  ⚖️  BALANCE  - Partner, Posterity, Social"
            echo ""
            echo "Current: "(alphaos_domain_icon)" $ALPHAOS_CURRENT_DOMAIN"

        case vault
            cd $ALPHAOS_VAULT

        case biz
            cd $ALPHAOS_BUSINESS

        case help -h --help
            echo "AlphaOS Shell Interface - Quick Access to AlphaOS Tools"
            echo ""
            echo "Usage: alphaos [command]"
            echo ""
            echo "Commands:"
            echo "  status       - Show status (War Stacks, Agents, Domain)"
            echo "  domains      - List 4 Domains (BODY/BEING/BALANCE/BUSINESS)"
            echo "  vault        - cd to AlphaOS Vault"
            echo "  biz          - cd to BUSINESS"
            echo "  help         - Show this help"
            echo ""
            echo "Quick Access Aliases:"
            echo "  ws       - War Stacks"
            echo "  voice    - VOICE Sessions"
            echo "  frame    - Frame Maps"
            echo "  freedom  - Freedom Maps"
            echo "  focus    - Focus Maps"
            echo "  fire     - Fire Maps"
            echo "  oracle   - AlphaOS Oracle agent"
            echo "  cc/dash  - Command Center Dashboard"
            echo ""
            echo "Philosophy:"
            echo "  AlphaOS = Life Operating System (Elliott Hulse)"
            echo "  DOMINION = Mastery over 4 Domains"
            echo "  Strategic > Tactical | Navigation > Tracking"
            echo ""

        case '*'
            echo "Unknown command: $argv[1]"
            echo "Try: alphaos help"
            return 1
    end
end
