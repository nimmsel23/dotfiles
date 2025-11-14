function note --description "Quick note capture to AlphaOs-Vault"
    set -l note_dir ~/AlphaOs-Vault/DOOR/Hot-List
    set -l date_stamp (date +%Y-%m-%d)
    set -l time_stamp (date +%H:%M)
    set -l note_file "$note_dir/quick-notes-$date_stamp.md"

    # Create directory if it doesn't exist
    mkdir -p $note_dir

    if test (count $argv) -eq 0
        echo "💡 Quick Note Capture"
        echo ""
        echo "Usage:"
        echo "  note 'your idea here'     # Capture a quick note"
        echo "  note show                 # Show today's notes"
        echo "  note edit                 # Edit today's notes"
        echo ""
        return
    end

    switch $argv[1]
        case show
            if test -f $note_file
                echo "📝 Notes for $date_stamp:"
                echo ""
                cat $note_file
            else
                echo "📝 No notes for today yet."
            end

        case edit
            if test -n "$EDITOR"
                $EDITOR $note_file
            else
                nano $note_file
            end

        case '*'
            # Capture note
            set -l note_text $argv

            # Create file if it doesn't exist
            if not test -f $note_file
                echo "# Quick Notes - $date_stamp" > $note_file
                echo "" >> $note_file
            end

            # Append note with timestamp
            echo "- [$time_stamp] $note_text" >> $note_file

            echo "✅ Note captured to Hot-List!"
            echo "💡 $note_text"
    end
end
