function z --description "Smart cd with auto-ls" --wraps cd
    # If no arguments, go home
    if test (count $argv) -eq 0
        cd ~
        ls -lh
        return
    end

    # Special shortcuts
    switch $argv[1]
        case vault
            cd ~/AlphaOs-Vault
        case dots dotfiles
            cd ~/.dotfiles
        case dev
            cd ~/dev
        case '*'
            cd $argv[1]
    end

    # Auto-ls if cd was successful
    if test $status -eq 0
        ls -lh
    end
end
