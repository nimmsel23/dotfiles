# AlphaOS Telegram Notifications

Auto-notify yourself via Telegram for important system events.

## Setup

```bash
bash ~/.dotfiles/bin/utils/setup-notifications
```

This installs:
- ✅ Boot notifications (systemd)
- ✅ Git push notifications (manual wrapper)

## Available Notifications

### 1. Boot Notification

**Automatic** - Sends message when system boots.

```
System booted: alpha-laptop at 14:23
```

**Control:**
```bash
systemctl --user status boot-notify.service   # Check status
systemctl --user start boot-notify.service    # Test manually
systemctl --user disable boot-notify.service  # Disable
systemctl --user enable boot-notify.service   # Re-enable
```

### 2. Git Push Notification

**Manual** - Use `git-push-notify` instead of `git push`.

```bash
git-push-notify              # Push + notify
git-push-notify origin main  # Push to specific remote/branch
gpn                          # Fish abbreviation
```

Message format:
```
✅ Pushed: dotfiles (main)
```

**Auto-use in fish:**
- Use `gpn` instead of `gp`
- Or alias `gp` to `git-push-notify` (if you want all pushes notified)

### 3. Manual Notifications

Direct `tele` command for custom events:

```bash
tele build completed
tele -s backup finished         # Silent
tele error in deployment        # Error notification
```

## Future Ideas

### Other potential notifications:
- Package updates complete (`pacu && tele "System updated"`)
- Long-running scripts (`./deploy.sh && tele "Deploy done"`)
- Cron job results
- Disk space warnings
- SSH login alerts
- Git commit reminders

### Telegram Listener (Optional/Fun)

The old `telegram-listener.sh` from dev_legacy allowed **remote command execution**:
- Send commands from phone → Execute on PC
- Cool factor: High
- Security: Questionable
- Usefulness: Low (since you have ssh/tailscale now)

Available in: `~/dev_legacy/bin/telegram-listener.sh`

**Why it's not installed by default:**
- Security risk if bot token leaks
- SSH/Tailscale are better for remote access
- More complexity than needed

**When it's cool:**
- Just for fun
- Learning bot development
- Quick status checks without SSH

## Configuration

All notifications use the same `tele.env`:
- Location: `~/AlphaOs-Vault/.config/tele.env`
- Backed up: Yes (via vault-sync)
- Gitignored: Yes (credentials not in repo)

## Disable All

```bash
# Boot notifications
systemctl --user disable boot-notify.service

# Git push - just use regular git push
```

Simple as that!
