#!/usr/bin/env bash

# ClaudeWarrior: Taskwarrior → Obsidian Export
# Exports Taskwarrior tasks to Obsidian vault as markdown files

set -euo pipefail

# Config
readonly OBSIDIAN_VAULT="${HOME}/AlphaOs-Vault"
readonly MAPS_DIR="${OBSIDIAN_VAULT}/MAPS"
readonly CONFIG_FILE="${HOME}/.config/claudewarrior/config.json"

# Ensure MAPS directory exists
mkdir -p "${MAPS_DIR}"

log() {
    echo "[ClaudeWarrior Export] $1"
}

# Export Fire Map tasks
export_fire_tasks() {
    log "Exporting Fire Map tasks..."

    local output_file="${MAPS_DIR}/fire-tasks.md"

    cat > "${output_file}" << 'EOF'
# Fire Map Tasks

Last updated: $(date -Iseconds)

## Active Fire Tasks

EOF

    # Export using Taskwarrior JSON
    task +fire status:pending export | jq -r '.[] | "- [ ] **\(.description)** | Due: \(.due // "no date") | Pillar: \(.pillar // "none") | Domain: \(.domain // "none")"' >> "${output_file}"

    log "Exported to ${output_file}"
}

# Export Hit List
export_hit_list() {
    log "Exporting Hit List..."

    local output_file="${MAPS_DIR}/hit-tasks.md"

    cat > "${output_file}" << 'EOF'
# Hit List

Last updated: $(date -Iseconds)

## Active Hits

EOF

    task +hit status:pending export | jq -r '.[] | "### Hit \(.hit_number // "?"): \(.description)\n- Door: \(.door_name // "none")\n- Status: \(.status)\n"' >> "${output_file}"

    log "Exported to ${output_file}"
}

# Export War Stack
export_war_stack() {
    log "Exporting War Stack..."

    local output_file="${MAPS_DIR}/war-stack.md"

    cat > "${output_file}" << 'EOF'
# War Stack (Hot List)

Last updated: $(date -Iseconds)

## High Priority Tasks

EOF

    task +warstack status:pending export | jq -r 'sort_by(.urgency) | reverse | .[] | "- [ ] **\(.description)** (Urgency: \(.urgency))\n  - Due: \(.due // "no date")\n  - Project: \(.project // "none")\n"' >> "${output_file}"

    log "Exported to ${output_file}"
}

# Export ClaudeWarrior tasks
export_claudewarrior_tasks() {
    log "Exporting ClaudeWarrior tasks..."

    local output_file="${MAPS_DIR}/claudewarrior-tasks.md"

    cat > "${output_file}" << 'EOF'
# ClaudeWarrior Tasks

Last updated: $(date -Iseconds)

## All ClaudeWarrior-Managed Tasks

EOF

    task +claudewarrior status:pending export | jq -r '.[] | "### \(.description)\n- **Project:** \(.project // "none")\n- **Domain:** \(.domain // "none") | **Pillar:** \(.pillar // "none")\n- **Due:** \(.due // "no date")\n- **Tags:** \(.tags | join(", "))\n- **Status:** \(.status)\n- **ID:** \(.id)\n\n"' >> "${output_file}"

    log "Exported to ${output_file}"
}

# Main export function
main() {
    log "Starting Taskwarrior → Obsidian export..."

    # Check if Obsidian vault exists
    if [[ ! -d "${OBSIDIAN_VAULT}" ]]; then
        log "ERROR: Obsidian vault not found at ${OBSIDIAN_VAULT}"
        exit 1
    fi

    # Check if Obsidian integration is enabled
    if command -v jq >/dev/null 2>&1 && [[ -f "${CONFIG_FILE}" ]]; then
        local enabled=$(jq -r '.obsidian.enabled // false' "${CONFIG_FILE}" 2>/dev/null)
        if [[ "${enabled}" != "true" ]]; then
            log "Obsidian integration disabled in config"
            log "Enable it in ${CONFIG_FILE}"
            exit 0
        fi
    fi

    # Export all task categories
    export_fire_tasks
    export_hit_list
    export_war_stack
    export_claudewarrior_tasks

    log "Export complete! ✓"
    log "View in Obsidian: ${MAPS_DIR}/"
}

main "$@"
