#!/usr/bin/env fish
# AlphaOS Shell Integration
# Makes Fish Shell the daily interface for DOMINION Building

# ═══════════════════════════════════════════════════════════════
# ALPHAOS CORE CONFIGURATION
# ═══════════════════════════════════════════════════════════════

# AlphaOS Paths
set -gx ALPHAOS_VAULT "$HOME/Dokumente/AlphaOs-Vault"
set -gx ALPHAOS_BUSINESS "$HOME/Dokumente/BUSINESS"
set -gx ALPHAOS_DATA "$HOME/.local/share/alphaos"

# 4 Domains (used throughout AlphaOS)
set -g ALPHAOS_DOMAINS BODY BEING BALANCE BUSINESS

# Current Domain (auto-detected from PWD)
set -g ALPHAOS_CURRENT_DOMAIN ""

# ═══════════════════════════════════════════════════════════════
# DOMAIN DETECTION
# ═══════════════════════════════════════════════════════════════

function alphaos_detect_domain
    set -l pwd_lower (string lower $PWD)

    # BUSINESS Domain
    if string match -q "*business*" $pwd_lower
        or string match -q "*fadaro*" $pwd_lower
        or string match -q "*vital*dojo*" $pwd_lower
        or string match -q "*vitaltrainer*" $pwd_lower
        set -g ALPHAOS_CURRENT_DOMAIN "BUSINESS"
        return
    end

    # BEING Domain
    if string match -q "*being*" $pwd_lower
        or string match -q "*voice*" $pwd_lower
        or string match -q "*meditation*" $pwd_lower
        set -g ALPHAOS_CURRENT_DOMAIN "BEING"
        return
    end

    # BALANCE Domain
    if string match -q "*balance*" $pwd_lower
        or string match -q "*partner*" $pwd_lower
        or string match -q "*social*" $pwd_lower
        set -g ALPHAOS_CURRENT_DOMAIN "BALANCE"
        return
    end

    # BODY Domain
    if string match -q "*body*" $pwd_lower
        or string match -q "*training*" $pwd_lower
        or string match -q "*nutrition*" $pwd_lower
        set -g ALPHAOS_CURRENT_DOMAIN "BODY"
        return
    end

    # AlphaOS Vault = META (all domains)
    if string match -q "*alphaos*vault*" $pwd_lower
        set -g ALPHAOS_CURRENT_DOMAIN "META"
        return
    end

    # Default: no domain
    set -g ALPHAOS_CURRENT_DOMAIN ""
end

# ═══════════════════════════════════════════════════════════════
# DOMAIN ICONS & COLORS
# ═══════════════════════════════════════════════════════════════

function alphaos_domain_icon
    switch $ALPHAOS_CURRENT_DOMAIN
        case "BUSINESS"
            echo "💼"
        case "BODY"
            echo "💪"
        case "BEING"
            echo "🧘"
        case "BALANCE"
            echo "⚖️"
        case "META"
            echo "🧠"
        case "*"
            echo ""
    end
end

function alphaos_domain_color
    switch $ALPHAOS_CURRENT_DOMAIN
        case "BUSINESS"
            echo "yellow"
        case "BODY"
            echo "red"
        case "BEING"
            echo "cyan"
        case "BALANCE"
            echo "green"
        case "META"
            echo "magenta"
        case "*"
            echo "normal"
    end
end

# ═══════════════════════════════════════════════════════════════
# ALPHAOS ALIASE - CORE COMMANDS
# ═══════════════════════════════════════════════════════════════

# War Stack
alias ws='echo "War Stack interface coming soon..." && ls -la $ALPHAOS_DATA/war_stacks.json 2>/dev/null || echo "No War Stacks yet"'

# VOICE Sessions
alias voice='cd $ALPHAOS_VAULT/VOICE && ls -lt 2025_Q* | head -10'

# GAME Maps (Strategic Navigation)
alias frame='cd $ALPHAOS_VAULT/GAME/Frame && ls -lt *.md | head -10'
alias freedom='cd $ALPHAOS_VAULT/GAME/Freedom && ls -lt *.md | head -10'
alias focus='cd $ALPHAOS_VAULT/GAME/Focus && ls -lt *.md | head -10'
alias fire='cd $ALPHAOS_VAULT/GAME/Fire && ls -lt *.md | head -10'

# Agents
alias oracle='echo "Use: claude code" && echo "Then say: use alphaos-oracle agent"'
alias cw='claudewarrior'

# Vault Navigation
alias vault='cd $ALPHAOS_VAULT'
alias biz='cd $ALPHAOS_BUSINESS'

# Dashboard
alias cc='command-center'
alias dash='command-center'

# ═══════════════════════════════════════════════════════════════
# ALPHAOS STATUS DISPLAY
# ═══════════════════════════════════════════════════════════════

function alphaos_status
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║            🔥 ALPHAOS - DOMINION STATUS 🔥                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Current Domain
    if test -n "$ALPHAOS_CURRENT_DOMAIN"
        set -l icon (alphaos_domain_icon)
        echo "📍 Current Domain: $icon $ALPHAOS_CURRENT_DOMAIN"
    else
        echo "📍 Current Domain: None (not in AlphaOS directory)"
    end
    echo ""

    # War Stacks
    if test -f "$ALPHAOS_DATA/war_stacks.json"
        set -l ws_count (jq '.stacks | length' "$ALPHAOS_DATA/war_stacks.json" 2>/dev/null || echo "0")
        echo "⚔️  Active War Stacks: $ws_count"
    else
        echo "⚔️  Active War Stacks: 0"
    end
    echo ""

    # Agents
    set -l agent_count (find ~/Dokumente/AlphaOs-Vault/.agents/configs ~/.dotfiles/.agents/configs ~/Dokumente/BUSINESS/FADARO/.agents/configs -name "*.json" 2>/dev/null | wc -l)
    echo "🤖 Available Agents: $agent_count"
    echo ""

    # Quick Commands
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Quick Commands:"
    echo "  ws       - War Stacks"
    echo "  voice    - VOICE Sessions"
    echo "  frame    - Frame Maps (current reality)"
    echo "  cc       - Command Center Dashboard"
    echo "  oracle   - AlphaOS Oracle agent"
    echo ""
end

# ═══════════════════════════════════════════════════════════════
# AUTO-DETECTION ON DIRECTORY CHANGE
# ═══════════════════════════════════════════════════════════════

function alphaos_auto_detect --on-variable PWD
    alphaos_detect_domain
end

# Initial detection
alphaos_detect_domain

# ═══════════════════════════════════════════════════════════════
# WELCOME MESSAGE (only in interactive shells)
# ═══════════════════════════════════════════════════════════════

if status is-interactive
    # Only show on first shell, not every new terminal
    if not set -q ALPHAOS_LOADED
        set -g ALPHAOS_LOADED 1

        echo ""
        echo "🔥 AlphaOS Shell Loaded"
        echo "   Type 'alphaos' for DOMINION status"
        echo ""
    end
end
