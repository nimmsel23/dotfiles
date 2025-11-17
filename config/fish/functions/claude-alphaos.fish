function claude-alphaos --description 'Load AlphaOS context and start Claude in AlphaOs-Vault'
    # Load context first (shows what to copy-paste)
    echo "Loading AlphaOS context..."
    echo ""
    claude-load-context alphaos

    echo ""
    read -l -P "Press ENTER to start Claude in ~/AlphaOs-Vault/ (or Ctrl+C to cancel)... "

    # Start Claude in AlphaOS Vault
    cd ~/AlphaOs-Vault
    claude
end
