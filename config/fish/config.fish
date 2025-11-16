# ~/.config/fish/config.fish - AlphaOS Clean Config
# ====================================================

# Disable greeting for faster startup
set fish_greeting

# Essential Wayland variables
set -gx XDG_RUNTIME_DIR "/run/user/"(id -u)
set -gx XDG_CURRENT_DESKTOP sway
set -gx XDG_SESSION_TYPE wayland

# GTK/QT Wayland support
set -gx QT_QPA_PLATFORM wayland
set -gx MOZ_ENABLE_WAYLAND 1

# Update systemd environment when in Sway
if test -n "$SWAYSOCK"
    systemctl --user import-environment \
        WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP \
        SWAYSOCK I3SOCK
end

# PATH setup
set -gx PATH $HOME/bin $PATH
set -gx PATH $HOME/.local/bin $PATH
set -gx PATH $HOME/.dotfiles/bin $PATH

# Enable 24-bit color in foot terminal
if test "$TERM" = "foot"
    set -gx COLORTERM truecolor
end

# Load starship prompt (if installed)
if command -v starship >/dev/null
    starship init fish | source
else
    # Fallback: Simple AlphaOS prompt
    function fish_prompt
        set_color green
        echo -n "[αOS] "
        set_color blue
        echo -n (prompt_pwd)
        set_color normal
        echo -n " > "
    end
end

# Claude Code context loader
function claude_context
    # Generate and display Claude Code context
    if test -x "$HOME/.dotfiles/bin/claude-context-generator"
        $HOME/.dotfiles/bin/claude-context-generator compact
    else
        echo "⚠️  claude-context-generator not found"
    end
end

# Quick context reload (without full display)
function claude_ctx
    echo "📋 Quick Context:"
    echo "  Agents: 5 active (claudewarrior, alphaos-oracle, fadaro-*)"
    echo "  Tasks: "(task +claudewarrior status:pending count 2>/dev/null || echo "0")" claudewarrior"
    echo ""
    echo '  Say: "Resume session with full context"'
end

# Interactive session welcome
if status is-interactive
    # Random tips
    set -l tips \
        "💡 Try: alphaos status" \
        "💡 Try: note 'your idea'" \
        "💡 Try: gq 'commit msg'" \
        "💡 Try: z vault" \
        "💡 Try: dev tools"

    set -l random_tip $tips[(random 1 (count $tips))]

    echo "🔥 AlphaOS Fish Shell Ready"
    echo $random_tip
    echo "   Type 'alphaos' for help"
    echo ""

    # Auto-load Claude Code context (smart detection based on PWD)
    # Detect which context to load based on current directory
    if string match -q "*/FADARO*" $PWD
        Fadaro
    else if string match -q "*/vital-dojo*" $PWD
        VitalDojo
    else if string match -q "*/AlphaOs-Vault*" $PWD
        AlphaOS
    else if test -d "$HOME/FADARO" -o -d "$HOME/vital-dojo" -o -f "$HOME/.config/claudewarrior/config.json"
        # Fallback: show full context if any project exists
        claude_context
    end
end
