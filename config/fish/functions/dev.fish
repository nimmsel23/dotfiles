function dev --description "Development environment helper"
    set -l action $argv[1]

    switch $action
        case projects p
            echo "📁 Development Projects:"
            echo ""
            if test -d ~/dev
                ls -lh ~/dev
            else
                echo "No ~/dev directory found"
            end

        case legacy
            echo "🗄️  Dev Legacy Archive:"
            echo ""
            if test -d ~/dev_legacy
                ls -lh ~/dev_legacy
            else
                echo "No ~/dev_legacy directory found"
            end

        case tools t
            echo "🛠️  Installed Dev Tools:"
            echo ""
            echo "Python: "(python --version 2>&1 | head -1)
            echo "Node:   "(node --version 2>/dev/null || echo "not installed")
            echo "Git:    "(git --version)
            echo "Fish:   "(fish --version)

        case env
            echo "🌍 Development Environment:"
            echo ""
            echo "PYTHONPATH: $PYTHONPATH"
            echo "PATH:"
            for p in $PATH
                echo "  - $p"
            end

        case '*'
            echo "💻 Dev Environment Helper"
            echo ""
            echo "Usage: dev [command]"
            echo ""
            echo "Commands:"
            echo "  projects, p    List development projects"
            echo "  legacy         Show dev_legacy archive"
            echo "  tools, t       Show installed dev tools"
            echo "  env            Show environment variables"
            echo ""
            echo "Or just: cd ~/dev"
    end
end
