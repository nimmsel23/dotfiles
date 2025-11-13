# 🤖 Agent Orchestration System

**Created:** 2025-11-13
**Location:** `~/.agents/`

---

## 🎯 What Is This?

This is your **Agent Orchestration System** - a meta-layer that manages all specialized agents in your environment.

Think of it like a **conductor** for an orchestra:
- You don't manually manage each musician (agent)
- You tell the conductor (orchestrator) what you need
- The conductor creates, coordinates, and manages all agents

---

## 📂 Structure

```
~/.agents/                          # System-wide orchestrator
├── AGENTS.md                       # Master registry (single source of truth)
├── README.md                       # This file
├── configs/
│   └── agent-orchestrator.json    # Orchestrator config
├── prompts/
│   └── agent-orchestrator.md      # Orchestrator system prompt
├── templates/
│   ├── agent-config-template.json # Template for new agents
│   └── system-prompt-template.md  # Template for prompts
└── tests/                          # Agent tests

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

## 🚀 How to Use

### Create a New Agent

```
"Create an agent for X"
```

Example:
```
"Create an agent for FADARO voice quality control"
```

The orchestrator will:
1. Analyze requirements
2. Write system prompt
3. Generate config
4. Document in AGENTS.md
5. Provide test prompts

---

### Ask Which Agent to Use

```
"Which agent should handle X?"
```

Example:
```
"Which agent for Frame Maps?"
```

The orchestrator will:
- Analyze your request
- Recommend best agent
- Check if it exists
- Offer to build it if needed

---

### List All Agents

```
"Show all agents"
or
"List agents"
```

The orchestrator will:
- Show all agents by category
- Display status (Active/Planned)
- Show statistics
- Suggest next builds

---

### Update an Agent

```
"Update agent X"
```

Example:
```
"Update fadaro-voice-guardian"
```

---

### Test an Agent

```
"Test agent X"
```

Example:
```
"Test alphaos-oracle"
```

---

## 📋 Current Status

**Active Agents:** 1
- `agent-orchestrator` (meta)

**Planned Agents:** 10
- 4 AlphaOS agents (alphaos-oracle, general-strategist, voice-session-guide, core-tracker-analyst)
- 3 FADARO agents (fadaro-voice-guardian, atp-to-tao-researcher, fitness-influenza-analyzer)
- 3 System agents (dotfiles-guardian, git-sync-enforcer, context-archivist)

**Next Priority:** Build `alphaos-oracle` (CRITICAL - foundation for AlphaOS agents)

---

## 🎯 Recommended Build Order

1. **alphaos-oracle** (CRITICAL)
   - Foundation for all AlphaOS agents
   - Loads 6 Pillar Files + 42 Blueprints
   - Enables Frame/Freedom/Focus/Fire Maps

2. **fadaro-voice-guardian** (HIGH)
   - Protects FADARO voice (USP)
   - Ensures "Raw but Warm" consistency

3. **git-sync-enforcer** (HIGH)
   - Protects your work
   - Auto-sync verification

4. **context-archivist** (HIGH)
   - Prevents context loss
   - Session management

5. Others as needed

---

## 🔧 Technical Details

**Orchestrator Config:** `~/.agents/configs/agent-orchestrator.json`
**Orchestrator Prompt:** `~/.agents/prompts/agent-orchestrator.md`
**Registry:** `~/.agents/AGENTS.md`

**Agent Categories:**
- **Meta:** System-wide management (orchestrator itself)
- **AlphaOS:** Elliott Hulse philosophy, Maps, VOICE, Core tracking
- **FADARO:** Content quality, research, voice consistency
- **System:** Dotfiles, git sync, context management

---

## 💡 Philosophy

**Why a Meta-Agent?**
- Scalability: Manage 20+ agents without getting lost
- Quality Control: Every agent is tested and documented
- Smart Routing: Don't think "which agent?" - just ask
- Single Source of Truth: AGENTS.md knows everything
- Self-Improving: Orchestrator learns which agents work best

**The Goal:**
You focus on **what** you want to do.
The orchestrator handles **how** to do it (which agent, which tools, which workflow).

---

## 📝 Next Steps

1. **Try it:** "Show all agents"
2. **Build foundation:** "Create alphaos-oracle"
3. **Build voice guard:** "Create fadaro-voice-guardian"
4. **Start using:** "Which agent for Frame Maps?"

---

**Maintained by:** agent-orchestrator
**Documentation:** See `~/.agents/AGENTS.md` for full registry
