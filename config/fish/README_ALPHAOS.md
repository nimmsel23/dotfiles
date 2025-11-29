# AlphaOS Fish Shell Integration

Fish Shell als tägliches Interface für DOMINION Building.

## ✅ Was ist implementiert

### 1. Auto-Domain Detection
Die Shell erkennt automatisch aus `$PWD` welche Domain aktiv ist:

```fish
# Automatisch erkannt:
~/Dokumente/BUSINESS/          → 💼 BUSINESS
~/Dokumente/BUSINESS/FADARO/   → 💼 BUSINESS  
~/Dokumente/AlphaOs-Vault/     → 🧠 META
```

**Unterstützte Domains:**
- 💼 **BUSINESS** - Authority, Monetization, Teaching
- 💪 **BODY** - Training, Fuel, Recovery
- 🧘 **BEING** - Meditation, Philosophy, Integration
- ⚖️ **BALANCE** - Partner, Posterity, Social
- 🧠 **META** - AlphaOS Vault (alle Domains)

**Domain wird angezeigt:**
- Im **Right Prompt** (rechte Seite deines Starship Prompts)
- In `alphaos status`

### 2. AlphaOS Haupt-Kommando

```bash
alphaos              # Zeigt DOMINION Status
alphaos status       # Gleich wie ohne args
alphaos domains      # Liste 4 Domains
alphaos score        # DOMINION Score heute (0-4pts)
alphaos log DOMAIN   # Log 1pt für Domain
alphaos vault        # cd zu AlphaOS Vault
alphaos biz          # cd zu BUSINESS
alphaos help         # Hilfe
```

**Status zeigt:**
- ✅ Current Domain (aus PWD)
- ✅ DOMINION Score today (0-4pts)
- ✅ Active War Stacks count
- ✅ Available Agents count (4+)
- ✅ Quick Commands Übersicht

### 3. AlphaOS Aliase

#### GAME Maps (Strategic Navigation)
```bash
frame       # cd zu Frame Maps (Current Reality)
freedom     # cd zu Freedom Maps (Annual Vision)
focus       # cd zu Focus Maps (Monthly Mission)
fire        # cd zu Fire Maps (Weekly War)
```

#### VOICE & War Stacks
```bash
voice       # cd zu VOICE Sessions + list recent
ws          # War Stack interface (WIP)
```

#### Agents
```bash
oracle      # Zeigt wie man alphaos-oracle startet
cw          # claudewarrior Kurzform
```

#### Navigation
```bash
vault       # cd zu AlphaOS Vault
biz         # cd zu BUSINESS
```

#### Dashboard & Tools
```bash
cc          # Command Center Dashboard
dash        # Command Center Dashboard (alias)
4pts        # DOMINION Score today
```

### 4. Right Prompt (Domain Indicator)

Zeigt aktuelle Domain rechts im Prompt:

```
~/BUSINESS/FADARO on main                         💼BUSINESS
~/AlphaOs-Vault on main                           🧠META
~/some/other/dir on main                          [leer]
```

**Farben:**
- 💼 BUSINESS = Yellow
- 💪 BODY = Red
- 🧘 BEING = Cyan
- ⚖️ BALANCE = Green
- 🧠 META = Magenta

### 5. Integration mit existierenden Tools

#### claude-context-generator
Bereits in `~/.config/fish/config.fish:48-94` integriert:
- Auto-load beim Shell-Start (basierend auf $PWD)
- Funktion `claude_context` ruft Script auf
- Zeigt: Agents, Projects, Taskwarrior Status

#### session-logger
Kompatibel mit Session Chronik plugin (Dashboard)

#### Taskwarrior
`alphaos status` zeigt ClaudeWarrior tasks (wenn vorhanden)

## 📁 Datei-Struktur

```
~/.config/fish/
├── conf.d/
│   └── alphaos.fish              # AlphaOS Core Config (auto-loaded)
├── functions/
│   ├── alphaos.fish              # Hauptkommando
│   ├── command-center.fish       # Dashboard launcher
│   └── fish_right_prompt.fish    # Domain indicator (right prompt)
└── README_ALPHAOS.md             # Diese Datei
```

## 🎯 Verwendung

### Beim Shell-Start

```
🔥 AlphaOS Shell Loaded
   Type 'alphaos' for DOMINION status
```

### Im Alltag

```bash
# Wechsel zu BUSINESS Domain
cd ~/Dokumente/BUSINESS/FADARO
# → Right Prompt zeigt: 💼BUSINESS

# Check DOMINION Status
alphaos
# → Shows: Domain, Score, War Stacks, Agents, Commands

# Navigate zu Maps
frame      # Frame Maps
freedom    # Freedom Maps

# Launch Dashboard
cc         # Command Center

# Check today's score
4pts       # DOMINION Score: 0/4 pts
```

### DOMINION Tracking (Future)

```bash
# Log points (requires jq implementation)
alphaos log BUSINESS    # +1pt BUSINESS
alphaos log BODY        # +1pt BODY
alphaos score           # Shows breakdown by domain
```

## 🔮 Next Steps (TODO)

### High Priority
- [ ] Implement DOMINION score logging (jq-based)
- [ ] War Stack creation flow (`ws create`)
- [ ] War Stack list/view (`ws list`, `ws view`)
- [ ] Integration mit Dashboard (System Status plugin)

### Medium Priority
- [ ] Git sync status in `alphaos status`
- [ ] Active Doors anzeigen (aus CLAUDE.md)
- [ ] Session-logger integration (recent sessions)
- [ ] Fish function auto-discovery (existing .dotfiles functions)

### Low Priority
- [ ] Starship module für AlphaOS (Alternative zum Right Prompt)
- [ ] DOMINION Score History (last 7 days)
- [ ] War Stack completion notifications
- [ ] Integration mit TickTick (via claudewarrior)

## 🛠️ Entwicklung

### Domain Detection erweitern

Edit `~/.config/fish/conf.d/alphaos.fish`, Funktion `alphaos_detect_domain`:

```fish
function alphaos_detect_domain
    set -l pwd_lower (string lower $PWD)

    # Add new pattern
    if string match -q "*your-pattern*" $pwd_lower
        set -g ALPHAOS_CURRENT_DOMAIN "YOUR_DOMAIN"
        return
    end
    # ...
end
```

### Neue Aliase hinzufügen

Edit `~/.config/fish/conf.d/alphaos.fish`, Section "ALPHAOS ALIASE":

```fish
alias yourcommand='your implementation here'
```

### Testing

```bash
# Reload Fish config
source ~/.config/fish/conf.d/alphaos.fish

# Test domain detection
cd ~/Dokumente/BUSINESS
alphaos domains   # Should show BUSINESS

# Test command
alphaos status
```

## 📚 Philosophy

**Fish Shell = THE CORE Interface**
- Terminal ist IMMER offen (10+ Stunden täglich)
- Muscle Memory entwickelt sich über Wochen
- AlphaOS wird zum "Operating System" nicht nur "ein Dashboard"

**DOMINION = Mastery über 4 Domains**
- BODY - Training, Fuel, Recovery
- BEING - Meditation, Philosophy, Integration
- BALANCE - Partner, Posterity, Social
- BUSINESS - Authority, Monetization, Teaching

**4pts/day System**
- Täglich in ALLE 4 Domains investieren
- Mindestens 1pt pro Domain = 4pts total
- Tracked in Shell, sichtbar im Prompt

---

**Version:** 1.0.0
**Created:** 2025-11-29
**Author:** alpha
**Status:** ✅ Core functionality complete
