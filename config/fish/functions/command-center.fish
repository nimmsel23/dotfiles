function command-center --description "Launch AlphaOS Strategic Command Center (3-Panel Dashboard)"
    # Save current directory
    set -l prev_dir (pwd)

    # Navigate to command center
    cd ~/.alphaos/command-center

    # Launch new 3-panel dashboard
    npm start

    # Return to previous directory when exiting
    cd $prev_dir
end
