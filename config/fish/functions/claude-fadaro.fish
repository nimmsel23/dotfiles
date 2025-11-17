function claude-fadaro --description 'Load FADARO context and start Claude in FADARO dir'
    # Load context first (shows what to copy-paste)
    echo "Loading FADARO context..."
    echo ""
    claude-load-context fadaro

    echo ""
    read -l -P "Press ENTER to start Claude in ~/FADARO/ (or Ctrl+C to cancel)... "

    # Start Claude in FADARO directory
    cd ~/FADARO
    claude
end
