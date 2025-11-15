#!/usr/bin/env python3
"""
ClaudeWarrior: TickTick → Taskwarrior Import
Imports tasks from TickTick that are tagged with +claudewarrior

Requirements:
    pip install --user ticktick-py tasklib
"""

import json
import sys
from datetime import datetime
from pathlib import Path

# Try importing dependencies
try:
    from tasklib import TaskWarrior, Task
except ImportError:
    print("ERROR: tasklib not installed. Run: pip install --user tasklib", file=sys.stderr)
    sys.exit(1)

try:
    import ticktick
    from ticktick.oauth2 import OAuth2
    from ticktick.api import TickTickClient
    TICKTICK_AVAILABLE = True
except ImportError:
    TICKTICK_AVAILABLE = False
    print("WARNING: ticktick-py not installed. TickTick import disabled.", file=sys.stderr)
    print("To enable: pip install --user ticktick-py", file=sys.stderr)

# Config
CONFIG_DIR = Path.home() / ".config" / "claudewarrior"
CONFIG_FILE = CONFIG_DIR / "config.json"
TICKTICK_CONFIG = Path.home() / ".config" / "ticktick" / "config.json"


def load_config():
    """Load ClaudeWarrior config"""
    if not CONFIG_FILE.exists():
        print(f"ERROR: Config not found at {CONFIG_FILE}", file=sys.stderr)
        sys.exit(1)

    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)


def load_ticktick_config():
    """Load TickTick config (credentials)"""
    if not TICKTICK_CONFIG.exists():
        print(f"ERROR: TickTick config not found at {TICKTICK_CONFIG}", file=sys.stderr)
        print("TickTick not configured on this system", file=sys.stderr)
        sys.exit(1)

    with open(TICKTICK_CONFIG, 'r') as f:
        return json.load(f)


def get_ticktick_client(tt_config):
    """Get authenticated TickTick client"""
    if not TICKTICK_AVAILABLE:
        raise RuntimeError("ticktick-py not installed")

    # TickTick config contains token
    # This is a simplified version - actual implementation depends on ticktick-py API
    # TODO: Implement proper TickTick OAuth flow
    print("NOTE: TickTick API integration requires manual token extraction", file=sys.stderr)
    print("For now, this is a placeholder. Full implementation coming soon.", file=sys.stderr)
    return None


def map_ticktick_to_taskwarrior(tt_task, config):
    """Convert TickTick task to Taskwarrior task"""

    # Base task
    tw_task_data = {
        'description': tt_task.get('title', 'Untitled'),
        'tags': ['claudewarrior', 'ticktick-import']
    }

    # Due date
    if tt_task.get('dueDate'):
        try:
            due_date = datetime.fromisoformat(tt_task['dueDate'].replace('Z', '+00:00'))
            tw_task_data['due'] = due_date
        except:
            pass

    # Priority mapping
    # TickTick: 0=none, 1=low, 3=medium, 5=high
    # Taskwarrior: L, M, H
    tt_priority = tt_task.get('priority', 0)
    if tt_priority >= 5:
        tw_task_data['priority'] = 'H'
    elif tt_priority >= 3:
        tw_task_data['priority'] = 'M'
    elif tt_priority >= 1:
        tw_task_data['priority'] = 'L'

    # Project from TickTick list
    if tt_task.get('projectId'):
        # Map TickTick list to Taskwarrior project
        # This would require fetching list name from API
        tw_task_data['project'] = f"TickTick.{tt_task['projectId']}"

    # Tags from TickTick
    if tt_task.get('tags'):
        for tag in tt_task['tags']:
            tw_task_data['tags'].append(tag.replace(' ', '_'))

    # AlphaOS inference (optional)
    # Try to infer pillar/domain from task content
    title_lower = tt_task.get('title', '').lower()

    if any(word in title_lower for word in ['workout', 'training', 'gym', 'fitness']):
        tw_task_data['domain'] = 'body'
        tw_task_data['pillar'] = 'CORE'

    return tw_task_data


def import_from_ticktick(dry_run=False):
    """Main import function"""

    print("[ClaudeWarrior] Starting TickTick → Taskwarrior import...")

    # Load config
    config = load_config()

    if not config.get('ticktick', {}).get('enabled', False):
        print("TickTick integration disabled in config")
        print(f"Enable it in {CONFIG_FILE}")
        return 0

    # Load TickTick config
    try:
        tt_config = load_ticktick_config()
    except SystemExit:
        return 1

    # Initialize Taskwarrior
    tw = TaskWarrior(data_location=str(Path.home() / '.task'))

    # PLACEHOLDER: Full TickTick API implementation coming soon
    print("\n" + "="*60)
    print("TickTick API Integration - PLACEHOLDER")
    print("="*60)
    print("\nThis feature requires:")
    print("1. Install ticktick-py: pip install --user ticktick-py")
    print("2. TickTick API access (OAuth or app password)")
    print("3. Manual tag in TickTick: Add 'claudewarrior' tag to tasks")
    print("\nFor now, you can manually create tasks in Taskwarrior")
    print("and we'll implement full TickTick sync in a future update.")
    print("="*60)

    # Example of what the full implementation would look like:
    """
    client = get_ticktick_client(tt_config)
    if not client:
        return 1

    # Get tasks tagged with 'claudewarrior'
    import_tag = config.get('ticktick', {}).get('import_tag', 'claudewarrior')
    tasks = client.get_tasks_by_tag(import_tag)

    imported_count = 0
    for tt_task in tasks:
        try:
            tw_task_data = map_ticktick_to_taskwarrior(tt_task, config)

            if dry_run:
                print(f"  Would import: {tw_task_data['description']}")
            else:
                tw_task = Task(tw, **tw_task_data)
                tw_task.save()
                print(f"  ✓ Imported: {tw_task_data['description']}")
                imported_count += 1

            # Optionally remove tag from TickTick
            if config.get('ticktick', {}).get('remove_tag_after_import', False):
                # Remove 'claudewarrior' tag from TickTick task
                pass

        except Exception as e:
            print(f"ERROR importing task: {e}", file=sys.stderr)

    print(f"\n[ClaudeWarrior] Imported {imported_count} tasks from TickTick")
    """

    return 0


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv

    try:
        sys.exit(import_from_ticktick(dry_run=dry_run))
    except KeyboardInterrupt:
        print("\nImport cancelled by user")
        sys.exit(130)
