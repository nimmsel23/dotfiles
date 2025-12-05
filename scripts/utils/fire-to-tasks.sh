#!/usr/bin/env bash
# fire-to-tasks.sh - Convert Fire Map Hits to Taskwarrior tasks
#
# Usage: ./fire-to-tasks.sh <FIRE_MAP_FILE>
# Example: ./fire-to-tasks.sh ~/Dokumente/AlphaOs-Vault/GAME/Fire/FIRE_MAP_BODY_KW49_2025.md
#
# This script parses Fire Map markdown files and creates Taskwarrior tasks
# with appropriate UDAs (pillar, domain, alphatype, +fire tag)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 <FIRE_MAP_FILE> [OPTIONS]

Convert Fire Map Hits to Taskwarrior tasks with AlphaOS UDAs.

ARGUMENTS:
    FIRE_MAP_FILE    Path to Fire Map markdown file (e.g., FIRE_MAP_BODY_KW49_2025.md)

OPTIONS:
    --dry-run        Show what would be created without actually creating tasks
    --project NAME   Override project name (default: extracted from domain)
    --due DATE       Override due date (default: extracted from KW number)
    --help           Show this help message

EXAMPLES:
    # Create tasks from BODY Fire Map for KW49
    $0 ~/Dokumente/AlphaOs-Vault/GAME/Fire/FIRE_MAP_BODY_KW49_2025.md

    # Dry run to see what would be created
    $0 --dry-run ~/Dokumente/AlphaOs-Vault/GAME/Fire/FIRE_MAP_BODY_KW49_2025.md

    # Process all Fire Maps for current week
    $0 ~/Dokumente/AlphaOs-Vault/GAME/Fire/FIRE_MAP_*_KW49_2025.md

EOF
}

# Parse arguments
DRY_RUN=false
PROJECT_OVERRIDE=""
DUE_OVERRIDE=""
FIRE_MAP_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --project)
            PROJECT_OVERRIDE="$2"
            shift 2
            ;;
        --due)
            DUE_OVERRIDE="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            FIRE_MAP_FILE="$1"
            shift
            ;;
    esac
done

# Validate input
if [[ -z "$FIRE_MAP_FILE" ]]; then
    log_error "No Fire Map file specified"
    show_usage
    exit 1
fi

if [[ ! -f "$FIRE_MAP_FILE" ]]; then
    log_error "File not found: $FIRE_MAP_FILE"
    exit 1
fi

log_info "Processing Fire Map: $FIRE_MAP_FILE"

# Extract metadata from filename
FILENAME=$(basename "$FIRE_MAP_FILE")
DOMAIN=$(echo "$FILENAME" | sed -E 's/FIRE_MAP_([A-Z]+)_KW([0-9]+)_([0-9]+)\.md/\1/')
KW=$(echo "$FILENAME" | sed -E 's/FIRE_MAP_([A-Z]+)_KW([0-9]+)_([0-9]+)\.md/\2/')
YEAR=$(echo "$FILENAME" | sed -E 's/FIRE_MAP_([A-Z]+)_KW([0-9]+)_([0-9]+)\.md/\3/')

log_info "Detected: Domain=$DOMAIN, KW=$KW, Year=$YEAR"

# Set project name
if [[ -n "$PROJECT_OVERRIDE" ]]; then
    PROJECT="$PROJECT_OVERRIDE"
else
    PROJECT="$DOMAIN"
fi

# Calculate due date (end of week = Sunday)
if [[ -n "$DUE_OVERRIDE" ]]; then
    DUE_DATE="$DUE_OVERRIDE"
else
    # Calculate Sunday of the given week
    # KW49 2025 = week 49 of 2025, Sunday = end of week
    # Using date command to calculate
    DUE_DATE=$(date -d "$YEAR-01-01 +$((KW * 7)) days" +%Y-%m-%d)
    log_info "Calculated due date: $DUE_DATE (Sunday of KW$KW)"
fi

# Parse Fire Map file and extract hits
log_info "Parsing Fire Map hits..."

HIT_COUNTER=0

# Read file line by line
while IFS= read -r line; do
    # Check if line is a Hit header (e.g., "### 1. **Hit #1: Lower Dantian 7-Tage Challenge**")
    if [[ "$line" =~ ^###[[:space:]]+[0-9]+\.[[:space:]]+\*\*Hit[[:space:]]#[0-9]+:[[:space:]](.+)\*\* ]]; then
        HIT_TITLE="${BASH_REMATCH[1]}"
        HIT_COUNTER=$((HIT_COUNTER + 1))

        # Read next lines to extract Strike details
        STRIKE=""
        FACT=""
        OBSTACLE=""

        while IFS= read -r detail_line; do
            # Stop at next Hit or section
            if [[ "$detail_line" =~ ^###[[:space:]] ]] || [[ "$detail_line" =~ ^##[[:space:]] ]]; then
                break
            fi

            # Extract Strike
            if [[ "$detail_line" =~ ^\-[[:space:]]+\*\*Strike:\*\*[[:space:]](.+) ]]; then
                STRIKE="${BASH_REMATCH[1]}"
            fi

            # Extract Fact
            if [[ "$detail_line" =~ ^\-[[:space:]]+\*\*Fact:\*\*[[:space:]](.+) ]]; then
                FACT="${BASH_REMATCH[1]}"
            fi

            # Extract Obstacle
            if [[ "$detail_line" =~ ^\-[[:space:]]+\*\*Obstacle:\*\*[[:space:]](.+) ]]; then
                OBSTACLE="${BASH_REMATCH[1]}"
            fi
        done < <(tail -n +$((LINENO + 1)) "$FIRE_MAP_FILE")

        # Create task description (use Strike if available, otherwise use Hit Title)
        if [[ -n "$STRIKE" ]]; then
            TASK_DESC="$HIT_TITLE - $STRIKE"
        else
            TASK_DESC="$HIT_TITLE"
        fi

        # Build task command
        TASK_CMD="task add \"$TASK_DESC\" project:$PROJECT.Fire +fire +hit due:$DUE_DATE pillar:GAME domain:$DOMAIN alphatype:hit"

        # Add tags based on domain
        case "$DOMAIN" in
            BODY)
                TASK_CMD="$TASK_CMD +fitness"
                ;;
            BEING)
                TASK_CMD="$TASK_CMD +meditation"
                ;;
            BALANCE)
                TASK_CMD="$TASK_CMD +social"
                ;;
            BUSINESS)
                TASK_CMD="$TASK_CMD +work"
                ;;
        esac

        # Execute or dry-run
        if [[ "$DRY_RUN" == true ]]; then
            log_warn "[DRY RUN] Would create: $TASK_CMD"
        else
            log_info "Creating task: Hit #$HIT_COUNTER - $HIT_TITLE"
            eval "$TASK_CMD" > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                log_success "Task created: $HIT_TITLE"
            else
                log_error "Failed to create task: $HIT_TITLE"
            fi
        fi
    fi
done < "$FIRE_MAP_FILE"

if [[ $HIT_COUNTER -eq 0 ]]; then
    log_warn "No hits found in Fire Map file"
    exit 1
fi

log_success "Processed $HIT_COUNTER hits from $DOMAIN Fire Map (KW$KW)"

if [[ "$DRY_RUN" == true ]]; then
    log_warn "DRY RUN completed - no tasks were actually created"
else
    log_success "All tasks created successfully!"
    log_info "View tasks: task project:$PROJECT.Fire list"
    log_info "View fire hits: task +fire +hit list"
fi
