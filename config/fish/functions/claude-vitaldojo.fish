function claude-vitaldojo --description 'Load Vital Dojo context and start Claude in vital-dojo dir'
    # Load context first (shows what to copy-paste)
    echo "Loading Vital Dojo context..."
    echo ""
    claude-load-context vitaldojo

    echo ""
    read -l -P "Press ENTER to start Claude in ~/vital-dojo/ (or Ctrl+C to cancel)... "

    # Start Claude in Vital Dojo directory
    cd ~/vital-dojo
    claude
end
