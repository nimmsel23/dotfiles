#!/usr/bin/env bash
# warstack-to-firemap.sh - Generate Fire Map from War Stack
#
# Usage: ./warstack-to-firemap.sh <WAR_STACK_FILE> [KW] [YEAR]
# Example: ./warstack-to-firemap.sh ~/AlphaOs-Vault/DOOR/War-Stacks/WAR_STACK_Modul_X.md 49 2025

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

show_usage() {
    cat << EOF
Usage: $0 <WAR_STACK_FILE> [KW] [YEAR]

Generate Fire Map from War Stack file.

ARGUMENTS:
    WAR_STACK_FILE    Path to War Stack markdown file
    KW               Week number (default: current week)
    YEAR             Year (default: current year)

EXAMPLES:
    # Generate Fire Map for current week
    $0 ~/AlphaOs-Vault/DOOR/War-Stacks/WAR_STACK_Modul_X.md

    # Generate for specific week
    $0 ~/AlphaOs-Vault/DOOR/War-Stacks/WAR_STACK_Modul_X.md 50 2025

EOF
}

# Parse arguments
WAR_STACK_FILE="${1:-}"
KW="${2:-$(date +%V)}"
YEAR="${3:-$(date +%Y)}"

if [[ -z "$WAR_STACK_FILE" ]]; then
    log_error "No War Stack file specified"
    show_usage
    exit 1
fi

if [[ ! -f "$WAR_STACK_FILE" ]]; then
    log_error "File not found: $WAR_STACK_FILE"
    exit 1
fi

log_info "Generating Fire Map from War Stack: $(basename "$WAR_STACK_FILE")"
log_info "Week: KW$KW $YEAR"

# Extract domain from War Stack file
DOMAIN="UNKNOWN"
if grep -q "🔴 BODY" "$WAR_STACK_FILE"; then
    DOMAIN="BODY"
elif grep -q "🔵 BEING" "$WAR_STACK_FILE"; then
    DOMAIN="BEING"
elif grep -q "🟡 BALANCE" "$WAR_STACK_FILE"; then
    DOMAIN="BALANCE"
elif grep -q "🟢 BUSINESS" "$WAR_STACK_FILE"; then
    DOMAIN="BUSINESS"
fi

log_info "Detected Domain: $DOMAIN"

# Extract Door name from War Stack
DOOR_NAME=$(grep -A1 "## 🚪 THE DOMINO DOOR" "$WAR_STACK_FILE" | tail -1 | sed 's/\[//g' | sed 's/\]//g' | xargs)
if [[ -z "$DOOR_NAME" ]]; then
    DOOR_NAME="Door from War Stack"
fi

log_info "Door: $DOOR_NAME"

# Extract 4 Hits from War Stack
declare -a HITS
declare -a FACTS
declare -a OBSTACLES
declare -a STRIKES

for i in {1..4}; do
    HIT_SECTION=$(sed -n "/### 🔥 HIT #$i:/,/^###/p" "$WAR_STACK_FILE")

    if [[ -z "$HIT_SECTION" ]]; then
        log_error "Hit #$i not found in War Stack"
        exit 1
    fi

    FACT=$(echo "$HIT_SECTION" | grep -A1 "^\*\*Fact:\*\*" | tail -1 | xargs)
    OBSTACLE=$(echo "$HIT_SECTION" | grep -A1 "^\*\*Obstacle:\*\*" | tail -1 | xargs)
    STRIKE=$(echo "$HIT_SECTION" | grep -A1 "^\*\*Strike:\*\*" | tail -1 | xargs)

    HITS[$i]="Hit #$i"
    FACTS[$i]="$FACT"
    OBSTACLES[$i]="$OBSTACLE"
    STRIKES[$i]="$STRIKE"
done

# Calculate week dates
WEEK_START=$(date -d "$YEAR-01-01 +$((KW * 7 - 7)) days" +%Y-%m-%d)
WEEK_END=$(date -d "$YEAR-01-01 +$((KW * 7 - 1)) days" +%Y-%m-%d)

# Output file
FIRE_MAP_DIR="/home/alpha/Dokumente/AlphaOs-Vault/GAME/Fire"
FIRE_MAP_FILE="$FIRE_MAP_DIR/FIRE_MAP_${DOMAIN}_KW${KW}_${YEAR}.md"

# Create Fire Map
cat > "$FIRE_MAP_FILE" << EOF
# 🔥 FIRE MAP - $DOMAIN Domain | KW $KW $YEAR

**Woche:** KW $KW ($WEEK_START - $WEEK_END)
**Status:** Weekly War
**War Stack:** [[$(basename "$WAR_STACK_FILE" .md)]]
**Door:** $DOOR_NAME
**Review:** General's Tent (Sonntag $(date -d "$WEEK_END" +%d.%m.%Y))

---

## 🎯 WEEKLY MISSION

**From War Stack:** [[$(basename "$WAR_STACK_FILE" .md)]]

**This Week's War:**
[Was muss diese Woche gewonnen werden?]

**Door Status:** __% offen

---

## 🔥 WEEKLY WAR (4 Hits from War Stack)

### Hit #1: ${FACTS[1]}

- **Fact:** ${FACTS[1]}
- **Obstacle:** ${OBSTACLES[1]}
- **Strike:** ${STRIKES[1]}

---

### Hit #2: ${FACTS[2]}

- **Fact:** ${FACTS[2]}
- **Obstacle:** ${OBSTACLES[2]}
- **Strike:** ${STRIKES[2]}

---

### Hit #3: ${FACTS[3]}

- **Fact:** ${FACTS[3]}
- **Obstacle:** ${OBSTACLES[3]}
- **Strike:** ${STRIKES[3]}

---

### Hit #4: ${FACTS[4]}

- **Fact:** ${FACTS[4]}
- **Obstacle:** ${OBSTACLES[4]}
- **Strike:** ${STRIKES[4]}

---

## 📅 DAILY BREAKDOWN

### Monday $(date -d "$WEEK_START" +%d.%m):
- [ ] Hit to focus on: ________________
**Notes:**

---

### Tuesday $(date -d "$WEEK_START +1 day" +%d.%m):
- [ ] Hit to focus on: ________________
**Notes:**

---

### Wednesday $(date -d "$WEEK_START +2 days" +%d.%m):
- [ ] Hit to focus on: ________________
**Notes:**

---

### Thursday $(date -d "$WEEK_START +3 days" +%d.%m):
- [ ] Hit to focus on: ________________
**Notes:**

---

### Friday $(date -d "$WEEK_START +4 days" +%d.%m):
- [ ] Hit to focus on: ________________
**Notes:**

---

### Saturday $(date -d "$WEEK_START +5 days" +%d.%m):
- [ ] Hit to focus on: ________________
**Notes:**

---

### Sunday $(date -d "$WEEK_START +6 days" +%d.%m):
- [ ] General's Tent Review
- [ ] Next week's Fire Map planning
**Notes:**

---

## 📊 WEEKLY SCORECARD

**Target:** 4/4 Hits completed

| Hit | Status | Notes |
|-----|--------|-------|
| Hit #1 | [ ] | |
| Hit #2 | [ ] | |
| Hit #3 | [ ] | |
| Hit #4 | [ ] | |

**Weekly War Result:**
- [ ] DOOR OPENED (4/4 Hits)
- [ ] PROGRESS (2-3/4 Hits)
- [ ] STALLED (0-1/4 Hits)

---

## 🏕️ GENERAL'S TENT (End of Week Review)

**Conducted:** Sonntag $(date -d "$WEEK_END" +%d.%m.%Y)

### Did I Win the Weekly War?
- [ ] YES - All 4 Hits completed
- [ ] PARTIAL - __/4 Hits completed
- [ ] NO - Course correction needed

### Lessons Learned:
-
-

### Course Corrections for Next Week:
-
-

### Door Status Update:
- Previous: __% offen
- Current: __% offen
- Is Door OPENED? [ ] YES | [ ] NO

---

## 🔗 LINKS

- **War Stack:** [[$(basename "$WAR_STACK_FILE" .md)]]
- **Next Fire Map:** [[FIRE_MAP_${DOMAIN}_KW$((KW + 1))_${YEAR}]]
- **Focus Map:** [[FOCUS_MAP_$(date -d "$WEEK_START" +%B)_${YEAR}]]
- **General's Tent:** [[GENERALS_TENT_KW${KW}_${YEAR}]]

---

**🔥 "Wars aren't won in one big move; they're won through a series of decisive battles."** - Elliott Hulse
EOF

log_success "Fire Map created: $FIRE_MAP_FILE"
log_info "War Stack → Fire Map generation complete"
log_info "Next: Review Fire Map and add to Daily breakdown"
log_info "Sync to Taskwarrior: firemap sync"

# Ask if user wants to sync immediately
read -p "Sync Fire Map to Taskwarrior now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    /home/alpha/.dotfiles/bin/firemap sync
fi
