# Fish Shell Config - AlphaOS Edition

**Created:** 2025-11-14
**Philosophy:** Powerful yet minimal, focused on AlphaOS workflow

## Structure

```
fish/
├── config.fish              # Main config (Wayland, PATH, random tips)
├── conf.d/
│   ├── aliases.fish         # 60+ abbreviations & shortcuts
│   └── german-shortcuts.fish # Deutsche abbreviations
├── functions/
│   ├── fish_prompt.fish     # Custom prompt with git branch
│   ├── alphaos.fish         # AlphaOS command center
│   ├── git-quick.fish       # Quick commit+push workflow
│   ├── z.fish               # Smart cd with auto-ls
│   ├── note.fish            # Quick note capture
│   ├── backup.fish          # Backup utility
│   ├── dev.fish             # Development environment helper
│   ├── sysinfo.fish         # System information
│   └── weekly.fish          # Weekly review helper
└── README.md
```

## Features

### 🔥 AlphaOS Integration

**Main Command:**
```fish
alphaos              # Show command center
alphaos status       # Show system status
alphaos frame        # Run Frame Map
alphaos freedom      # Run Freedom Map
alphaos tent         # Run General's Tent
alphaos fruits       # Run FRUITS CLI
alphaos vault        # Go to vault directory
alphaos sync         # Sync to GitHub
```

**Quick Shortcuts:**
```fish
frame                # Frame Map
freedom              # Freedom Map
tent                 # General's Tent
fruits               # FRUITS CLI
aos                  # alphaos alias
```

### 📝 Note Capture

```fish
note 'your idea here'    # Capture quick note to Hot-List
note show                # Show today's notes
note edit                # Edit today's notes
```

Notes are saved to: `~/AlphaOs-Vault/DOOR/Hot-List/quick-notes-YYYY-MM-DD.md`

### 🚀 Git Workflow

**Quick Commit+Push:**
```fish
gq 'commit message'      # Add all, commit, push in one command
```

**Abbreviations:**
```fish
gs       # git status
gss      # git status --short
ga       # git add .
gc       # git commit -m
gca      # git commit --amend
gp       # git push
gpl      # git pull
gl       # git log --oneline --graph
gd       # git diff
gds      # git diff --staged
gb       # git branch
gco      # git checkout
```

### 💾 Vault Sync

```fish
vs       # vault-sync (auto-sync)
vst      # vault-sync status
vsc      # vault-sync check
vsl      # vault-sync log
vsd      # vault-sync diff
```

### 🗺️ Smart Navigation

```fish
z vault              # cd + ls to AlphaOs-Vault
z dots               # cd + ls to dotfiles
z dev                # cd + ls to ~/dev
z                    # cd ~ + ls

..                   # cd ..
...                  # cd ../..
....                 # cd ../../..
```

### 💻 Development

```fish
dev                  # Show dev helper menu
dev projects         # List development projects
dev legacy           # Show dev_legacy archive
dev tools            # Show installed dev tools
dev env              # Show environment variables
```

### 💾 Backup

```fish
backup vault         # Sync AlphaOs-Vault to GitHub
backup dots          # Sync dotfiles to GitHub
backup <file>        # Create timestamped backup of file
```

### 📊 System Info

```fish
sysinfo              # Show system information
weekly               # AlphaOS weekly review helper
```

### 📦 Package Management (Arch/EndeavourOS)

```fish
pacs <package>       # sudo pacman -S
pacr <package>       # sudo pacman -R
pacu                 # sudo pacman -Syu
pacq <term>          # pacman -Ss (search)
yays <package>       # yay -S (AUR)
yayu                 # yay -Syu (AUR update)
```

### 🛠️ File Operations

```fish
ll                   # ls -lah (detailed)
la                   # ls -A (show hidden)
lt                   # ls -lht (sort by time)
c                    # clear
h                    # history
x                    # exit

cp                   # cp -i (confirm overwrite)
mv                   # mv -i (confirm overwrite)
rm                   # rm -i (confirm delete)
mkdir                # mkdir -p (create parents)
```

## Custom Prompt

The prompt shows:
- `[αOS]` prefix
- Current directory (shortened)
- Git branch (if in repo)
  - Cyan `(branch)` if clean
  - Yellow `(branch*)` if dirty
- Green `❯` if last command succeeded
- Red `❯` if last command failed

Example:
```
[αOS] ~/AlphaOs-Vault (main) ❯
```

## Random Tips on Startup

Each fish session shows a random tip:
- 💡 Try: alphaos status
- 💡 Try: note 'your idea'
- 💡 Try: gq 'commit msg'
- 💡 Try: z vault
- 💡 Try: dev tools

## Old Config Archive

Preserved in: `~/AlphaOs-Vault/ARCHIVE/fish-old/`

Contains:
- 121 files
- 5770+ lines of code
- Taskwarrior integration (90+ aliases)
- Python script wrappers
- Telegram bot functions
- Obsidian integration

**Why archived:** System switched to TickTick. Old tools in dev_legacy not maintained.

## Dependencies

**Required:**
- fish shell 3.0+

**Optional:**
- starship (for fancy prompt - config will fallback to custom prompt)
- git (for git integration)
- AlphaOS tools (frame, freedom, tent, fruits)

## Extending

Add new files to:
- `conf.d/` for auto-loaded configs
- `functions/` for custom functions

Example function:
```fish
# ~/.config/fish/functions/myfunc.fish
function myfunc --description "My custom function"
    echo "Hello from myfunc!"
end
```

## Statistics

- **Total abbreviations:** 60+
- **Custom functions:** 10
- **Lines of code:** ~500
- **vs. Old config:** 5770 lines → 500 lines (91% reduction!)

---

**Part of the AlphaOS dotfiles system**
**GitHub:**
- dotfiles: https://github.com/nimmsel23/dotfiles
- AlphaOs-Vault: https://github.com/nimmsel23/AlphaOs-Vault
