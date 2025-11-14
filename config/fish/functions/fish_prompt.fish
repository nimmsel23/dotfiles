function fish_prompt
    # Get last command status
    set -l last_status $status

    # Colors
    set -l normal (set_color normal)
    set -l green (set_color green)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l red (set_color red)
    set -l magenta (set_color magenta)

    # AlphaOS prefix
    echo -n $green'[αOS]'$normal' '

    # Current directory (shortened)
    echo -n $blue(prompt_pwd)$normal

    # Git branch (if in git repo)
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l branch (git branch --show-current 2>/dev/null)
        if test -n "$branch"
            # Check if repo is dirty
            if git diff-index --quiet HEAD -- 2>/dev/null
                # Clean
                echo -n ' '$cyan'('$branch')'$normal
            else
                # Dirty
                echo -n ' '$yellow'('$branch'*)'$normal
            end
        end
    end

    # Prompt symbol (changes color on error)
    if test $last_status -eq 0
        echo -n ' '$green'❯'$normal' '
    else
        echo -n ' '$red'❯'$normal' '
    end
end
