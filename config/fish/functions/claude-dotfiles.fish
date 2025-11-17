function claude-dotfiles --description 'Start Claude in dotfiles directory'
    echo "Starting Claude in ~/.dotfiles/ (uses CLAUDE.md from dotfiles)"
    echo ""

    read -l -P "Press ENTER to start Claude in ~/.dotfiles/ (or Ctrl+C to cancel)... "

    # Start Claude in dotfiles directory
    cd ~/.dotfiles
    claude
end
