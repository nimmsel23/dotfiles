function tele --description "Telegram CLI - Send messages from terminal"
    # Wrapper for tele command with fish-specific features

    if test (count $argv) -eq 0
        command tele --help
        return
    end

    # Special fish integrations
    switch $argv[1]
        case --last-cmd --lastcmd
            # Send last command output
            set -l last_cmd (history --max 1)
            command tele "Last command: $last_cmd"

        case --pwd
            # Send current directory
            command tele "Current directory: "(pwd)

        case --git
            # Send git status
            if git rev-parse --git-dir >/dev/null 2>&1
                set -l branch (git branch --show-current)
                set -l status (git status --short | wc -l)
                command tele "Git: $branch ($status changes)"
            else
                echo "Not a git repository"
                return 1
            end

        case '*'
            # Pass through to tele
            command tele $argv
    end
end
