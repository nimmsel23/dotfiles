function git-help --description "Git sync & safe push quick reference with gum"
    # Header
    gum style \
        --border double \
        --border-foreground 212 \
        --padding "0 2" \
        --margin "1" \
        --align center \
        --bold \
        "GIT SYNC & SAFE PUSH - QUICK REFERENCE"

    # Create markdown content
    set -l markdown "
## 🔍 Status Checks

- **repos** - Interactive menu (recommended!)
- **gses** - Raw git-sync-enforcer status
- **gsev** - Verify all remotes configured

## 🚀 Safe Push

- **gsafe** - Push with pre-flight check (gum UI)
- **gq 'msg'** - Quick add→commit→push
- **gpn** - Push with Telegram notification

## 🔧 Sync Operations

- **gsee** - Sync all repos (fetch, pull, push)
- **vs** - Vault-sync (AlphaOs-Vault only)
- **vst** - Vault-sync status

## ⚙️ Setup Commands

- **gseh** - Install git hooks (Telegram notifications)
- **gsevs** - Setup vault auto-sync timer

## 🤖 ClaudeWarrior

- **cw** - ClaudeWarrior CLI
- **cws** - ClaudeWarrior status
- **cwsync** - Sync tasks to calendar

## 💡 Recommended Workflow

1. **repos** - Check status (interactive!)
2. **ga** - Add changes
3. **gc 'message'** - Commit
4. **gsafe** - Safe push with check
"

    # Display with gum format
    echo "$markdown" | gum format

    # Auto-check info box
    echo ""
    gum style \
        --border rounded \
        --border-foreground 117 \
        --padding "1 2" \
        "🔧 Auto-Check (optional):
  Edit: ~/.config/fish/conf.d/git-sync-auto.fish
  Uncomment functions to enable auto-checks"
end
