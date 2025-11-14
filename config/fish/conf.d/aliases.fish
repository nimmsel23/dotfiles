# AlphaOS Aliases & Abbreviations
# ================================

# --- AlphaOS Tools ---
abbr -a frame 'frame'
abbr -a freedom 'freedom'
abbr -a tent 'tent'
abbr -a fruits 'fruits'
abbr -a aos 'alphaos'

# --- Vault Sync ---
abbr -a vs 'vault-sync'
abbr -a vst 'vault-sync status'
abbr -a vsc 'vault-sync check'
abbr -a vsl 'vault-sync log'
abbr -a vsd 'vault-sync diff'

# --- Git Shortcuts ---
abbr -a gs 'git status'
abbr -a gss 'git status --short'
abbr -a ga 'git add .'
abbr -a gc 'git commit -m'
abbr -a gca 'git commit --amend'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gl 'git log --oneline --graph'
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a gb 'git branch'
abbr -a gco 'git checkout'
abbr -a gq 'git-quick'

# --- Navigation ---
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'
abbr -a vault 'cd ~/AlphaOs-Vault'
abbr -a dots 'cd ~/.dotfiles'
abbr -a conf 'cd ~/.config'

# --- System ---
abbr -a ll 'ls -lah'
abbr -a la 'ls -A'
abbr -a lt 'ls -lht'  # Sort by time
abbr -a c 'clear'
abbr -a h 'history'
abbr -a x 'exit'

# --- File Operations ---
abbr -a cp 'cp -i'  # Confirm before overwrite
abbr -a mv 'mv -i'  # Confirm before overwrite
abbr -a rm 'rm -i'  # Confirm before delete
abbr -a mkdir 'mkdir -p'  # Create parent dirs

# --- Utilities ---
abbr -a grep 'grep --color=auto'
abbr -a df 'df -h'  # Human readable
abbr -a du 'du -h'  # Human readable
abbr -a free 'free -h'  # Human readable

# --- Package Management (Arch/EndeavourOS) ---
abbr -a pacs 'sudo pacman -S'  # Install
abbr -a pacr 'sudo pacman -R'  # Remove
abbr -a pacu 'sudo pacman -Syu'  # Update
abbr -a pacq 'pacman -Ss'  # Search
abbr -a yays 'yay -S'  # AUR install
abbr -a yayu 'yay -Syu'  # AUR update

# --- AlphaOS 4 Domains (für wenn du Taskwarrior wieder nutzt) ---
# abbr -a BODY 'task context BODY'
# abbr -a BEING 'task context BEING'
# abbr -a BALANCE 'task context BALANCE'
# abbr -a BUSINESS 'task context BUSINESS'
