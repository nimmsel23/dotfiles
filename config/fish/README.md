# Fish Shell Config - AlphaOS Clean Edition

**Created:** 2025-11-14
**Philosophy:** Minimal, fast, focused on AlphaOS tools

## Structure

```
fish/
├── config.fish           # Main config (Wayland, PATH, prompt)
├── conf.d/
│   ├── aliases.fish      # AlphaOS tools, git, vault-sync
│   └── german-shortcuts.fish  # Deutsche abbreviations
└── README.md
```

## What's included

### AlphaOS Tools
- `frame`, `freedom`, `tent`, `fruits`
- `vs` → vault-sync shortcuts

### Git Workflow
- `gs` → git status
- `ga` → git add .
- `gc` → git commit -m
- `gp` → git push
- `gl` → git log --oneline --graph

### Navigation
- `vault` → cd ~/AlphaOs-Vault
- `dev` → cd ~/dev
- `dots` → cd ~/.dotfiles

## Old Config

Archived in: `~/AlphaOs-Vault/ARCHIVE/fish-old/`

Includes:
- Taskwarrior integration (90+ aliases)
- Python script wrappers
- Telegram bot functions
- Obsidian integration

**Why archived:** Switched to TickTick, Python tools in dev_legacy not maintained.

## Extending

Add new files to `conf.d/` - they auto-load on shell start.

Example:
```fish
# ~/.config/fish/conf.d/my-stuff.fish
abbr -a myalias 'echo "cool"'
```

## Dependencies

- **Required:** fish shell (installed)
- **Optional:** starship prompt (for fancy prompt)
- **Optional:** fzf, zoxide (for enhanced navigation)

---

*Part of the AlphaOS dotfiles system*
