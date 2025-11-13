# 🤖 AGENT REGISTRY - System-Wide

**Last Updated:** 2025-11-13
**Location:** `~/.agents/`
**Total Agents:** 1 (+ 10 planned)

---

## 📋 ACTIVE AGENTS

### Meta Agents

#### `agent-orchestrator` ⭐
**Status:** Active
**Purpose:** Meta-agent that creates, manages, coordinates, and documents all other agents
**Config:** `~/.agents/configs/agent-orchestrator.json`

**Capabilities:**
- Create new agents (system prompts, configs, tools)
- Manage existing agents (update, deactivate, delete)
- Coordinate agent workflows (smart routing)
- Document agents (this registry)
- Test agent quality

**Tool Access:** Read, Write, Edit, Grep, Bash, Task
**Triggers:**
- "Create an agent for X"
- "Which agent should handle X?"
- "Show all agents"
- "Update agent X"
- "Test agent X"

**Examples:**
```
User: "Create an agent for FADARO voice quality"
→ Generates fadaro-voice-guardian config + system prompt

User: "Which agent for Frame Maps?"
→ Routes to alphaos-oracle (when built)

User: "Show agents"
→ Lists this registry with status
```

---

## 🔧 PLANNED AGENTS

### FADARO Agents (3)
**Location:** `~/FADARO/.agents/`

#### `fadaro-voice-guardian`
**Purpose:** Voice quality control (Raw but Warm, 4 Archetypen balance)
**Tools:** Read, Grep, Edit
**Priority:** HIGH

#### `atp-to-tao-researcher`
**Purpose:** Ost-West integration research & fact-checking
**Tools:** Read, Grep, WebSearch, WebFetch
**Priority:** HIGH

#### `fitness-influenza-analyzer`
**Purpose:** Fitness industry analysis & hot takes
**Tools:** Read, Grep, WebSearch, WebFetch
**Priority:** MEDIUM

---

### AlphaOS Agents (4)
**Location:** `~/AlphaOs-Vault/.agents/`

#### `alphaos-oracle`
**Purpose:** Elliott Hulse's original philosophy (6 Pillars + 42 Blueprints)
**Tools:** Read, Write, Grep
**Priority:** CRITICAL (foundation for all AlphaOS agents)

**Data Sources:**
- Primary: 6 Pillar Files (`~/AlphaOs-Vault/ALPHA OS/*.md`)
- Deep: 42 Blueprints (`~/AlphaOs-Vault/AlphaOS-blueprints/*.md`)
- Context: User's MOCs (`~/AlphaOs-Vault/📖 MOC - THE *.md`)

#### `general-strategist`
**Purpose:** GAME Maps creation (Frame/Freedom/Focus/Fire)
**Tools:** Read, Write, Bash (for frame/freedom/tent commands)
**Depends On:** alphaos-oracle
**Priority:** HIGH

#### `voice-session-guide`
**Purpose:** VOICE framework sessions (STOP→SUBMIT→STRUGGLE→STRIKE)
**Tools:** Read, Write
**Depends On:** alphaos-oracle
**Priority:** HIGH

#### `core-tracker-analyst`
**Purpose:** 28-or-Die tracking & pattern analysis
**Tools:** Read, Write, Bash
**Priority:** MEDIUM

---

### System Agents (3)
**Location:** `~/.agents/`

#### `dotfiles-guardian`
**Purpose:** System config & tool maintenance
**Tools:** Read, Bash, Grep
**Priority:** MEDIUM

#### `git-sync-enforcer`
**Purpose:** Auto-sync verification & backup
**Tools:** Bash, Read
**Priority:** HIGH

#### `context-archivist`
**Purpose:** Session context & project state management
**Tools:** Read, Write, Edit
**Priority:** HIGH

---

## 📊 AGENT STATISTICS

**By Category:**
- Meta: 1 active
- FADARO: 0 active, 3 planned
- AlphaOS: 0 active, 4 planned
- System: 0 active, 3 planned

**By Priority:**
- CRITICAL: 1 (alphaos-oracle)
- HIGH: 6
- MEDIUM: 3

---

## 🔄 AGENT DEPENDENCIES

```
agent-orchestrator (creates all)
    ├─→ alphaos-oracle (FOUNDATION - must build first)
    │       ├─→ general-strategist
    │       └─→ voice-session-guide
    ├─→ fadaro-voice-guardian
    ├─→ atp-to-tao-researcher
    ├─→ fitness-influenza-analyzer
    ├─→ core-tracker-analyst
    ├─→ dotfiles-guardian
    ├─→ git-sync-enforcer
    └─→ context-archivist
```

---

## 🗂️ DIRECTORY STRUCTURE

```
~/.agents/                          # System-wide orchestrator
├── AGENTS.md                       # This registry (master list)
├── configs/
│   └── agent-orchestrator.json
├── templates/
│   ├── agent-config-template.json
│   └── system-prompt-template.md
└── tests/

~/AlphaOs-Vault/.agents/            # AlphaOS-specific agents
├── configs/
├── prompts/
└── tests/

~/FADARO/.agents/                   # FADARO-specific agents
├── configs/
├── prompts/
└── tests/
```

---

## 📝 CHANGE LOG

**2025-11-13:**
- ✅ Created `~/.agents/` directory structure (system-wide)
- ✅ Initialized AGENTS.md registry
- ✅ agent-orchestrator: Meta-agent specification
- ⏳ Next: Create alphaos-oracle (foundation agent)

---

## 🎯 NEXT STEPS

1. **Build alphaos-oracle** (CRITICAL - foundation for AlphaOS agents)
2. **Build fadaro-voice-guardian** (HIGH - FADARO voice is USP)
3. **Build general-strategist** (HIGH - Frame/Freedom/Focus/Fire Maps)
4. **Build git-sync-enforcer** (HIGH - protect work)
5. **Build context-archivist** (HIGH - prevent context loss)

---

**Maintained by:** agent-orchestrator
**Registry Location:** `~/.agents/AGENTS.md`
