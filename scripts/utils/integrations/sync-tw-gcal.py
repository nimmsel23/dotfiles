#!/usr/bin/env python3
"""
ClaudeWarrior: Taskwarrior → Google Calendar Sync
Syncs tasks with +fire tag or due dates to Google Calendar

Requirements:
    pip install --user google-api-python-client google-auth-oauthlib tasklib
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Try importing dependencies
try:
    from tasklib import TaskWarrior
except ImportError:
    print("ERROR: tasklib not installed. Run: pip install --user tasklib", file=sys.stderr)
    sys.exit(1)

try:
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
    GOOGLE_API_AVAILABLE = True
except ImportError:
    GOOGLE_API_AVAILABLE = False
    print("WARNING: Google API libraries not installed. GCal sync disabled.", file=sys.stderr)
    print("To enable: pip install --user google-api-python-client google-auth-oauthlib", file=sys.stderr)

# Config
CONFIG_DIR = Path.home() / ".config" / "claudewarrior"
CONFIG_FILE = CONFIG_DIR / "config.json"
GCAL_TOKEN_FILE = CONFIG_DIR / "gcal_token.json"
GCAL_CREDS_FILE = CONFIG_DIR / "gcal_credentials.json"

# Google Calendar API scopes
SCOPES = ['https://www.googleapis.com/auth/calendar']


def load_config():
    """Load ClaudeWarrior config"""
    if not CONFIG_FILE.exists():
        print(f"ERROR: Config not found at {CONFIG_FILE}", file=sys.stderr)
        print("Run 'claudewarrior status' first to create config", file=sys.stderr)
        sys.exit(1)

    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)


def get_gcal_service():
    """Get authenticated Google Calendar service"""
    if not GOOGLE_API_AVAILABLE:
        raise RuntimeError("Google Calendar API libraries not installed")

    creds = None

    # Load existing token
    if GCAL_TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(GCAL_TOKEN_FILE), SCOPES)

    # If no valid credentials, authenticate
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not GCAL_CREDS_FILE.exists():
                print(f"ERROR: Google Calendar credentials not found", file=sys.stderr)
                print(f"Please download OAuth credentials from Google Cloud Console", file=sys.stderr)
                print(f"Save them to: {GCAL_CREDS_FILE}", file=sys.stderr)
                print(f"Guide: https://developers.google.com/calendar/api/quickstart/python", file=sys.stderr)
                sys.exit(1)

            flow = InstalledAppFlow.from_client_secrets_file(str(GCAL_CREDS_FILE), SCOPES)
            creds = flow.run_local_server(port=0)

        # Save credentials
        with open(GCAL_TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())

    return build('calendar', 'v3', credentials=creds)


def map_task_to_calendar(task, config):
    """Determine which calendar a task should go to"""
    gcal_config = config.get('google_calendar', {})

    # Priority 1: +fire tag → Fire Map calendar
    if 'fire' in task.get('tags', []):
        return gcal_config.get('fire_map_cal_id')

    # Priority 2: domain:body → Trainingsplan calendar
    domain = task.get('domain', '')
    if domain == 'body':
        return gcal_config.get('trainingsplan_cal_id')

    # Priority 3: domain-specific calendars (if configured)
    if domain in ['being', 'balance', 'business']:
        cal_key = f'{domain}_cal_id'
        cal_id = gcal_config.get(cal_key)
        if cal_id:
            return cal_id

    # Default calendar
    return gcal_config.get('default_cal_id', 'primary')


def task_to_event(task, config):
    """Convert Taskwarrior task to Google Calendar event"""

    description_lines = [f"Task ID: {task['id']}"]

    # Add AlphaOS metadata
    if task.get('pillar'):
        description_lines.append(f"Pillar: {task['pillar']}")
    if task.get('domain'):
        description_lines.append(f"Domain: {task['domain']}")
    if task.get('alphatype'):
        description_lines.append(f"Type: {task['alphatype']}")
    if task.get('project'):
        description_lines.append(f"Project: {task['project']}")

    # Tags
    tags = task.get('tags', [])
    if tags:
        description_lines.append(f"Tags: {', '.join([f'+{t}' for t in tags])}")

    # Due date
    due = task.get('due')
    if due:
        start_time = due.isoformat()
        # Default duration: 1 hour
        end_time = (due + timedelta(hours=1)).isoformat()
    else:
        # No due date, create all-day event for today
        today = datetime.now().date()
        start_time = today.isoformat()
        end_time = (today + timedelta(days=1)).isoformat()

    event = {
        'summary': task['description'],
        'description': '\n'.join(description_lines),
        'start': {
            'dateTime': start_time,
            'timeZone': 'Europe/Berlin',  # TODO: Make configurable
        },
        'end': {
            'dateTime': end_time,
            'timeZone': 'Europe/Berlin',
        },
        'colorId': get_color_for_domain(task.get('domain')),
    }

    return event


def get_color_for_domain(domain):
    """Map AlphaOS domain to Google Calendar color"""
    color_map = {
        'body': '4',    # Red
        'being': '9',   # Blue
        'balance': '5', # Yellow
        'business': '2', # Green
    }
    return color_map.get(domain, '7')  # Default: gray


def sync_tasks_to_gcal(dry_run=False):
    """Main sync function"""

    print("[ClaudeWarrior] Starting Taskwarrior → Google Calendar sync...")

    # Load config
    config = load_config()

    if not config.get('google_calendar', {}).get('enabled', False):
        print("Google Calendar integration disabled in config")
        print(f"Enable it in {CONFIG_FILE}")
        return 0

    # Initialize Taskwarrior
    tw = TaskWarrior(data_location=str(Path.home() / '.task'))

    # Get tasks to sync: +fire OR has due date
    # Filter out completed tasks
    sync_candidates = []

    # Method 1: Tasks with +fire tag
    fire_tasks = tw.tasks.filter(tags__contains='fire', status='pending')
    sync_candidates.extend(fire_tasks)

    # Method 2: Tasks with due date
    due_tasks = tw.tasks.filter(status='pending')
    due_tasks = [t for t in due_tasks if t.get('due')]
    sync_candidates.extend(due_tasks)

    # Deduplicate
    seen = set()
    unique_tasks = []
    for task in sync_candidates:
        task_id = task['uuid']
        if task_id not in seen:
            seen.add(task_id)
            unique_tasks.append(task)

    print(f"Found {len(unique_tasks)} tasks to sync")

    if dry_run:
        print("\n[DRY RUN] Would sync:")
        for task in unique_tasks:
            cal_id = map_task_to_calendar(task, config)
            print(f"  - {task['description']} → {cal_id}")
        return 0

    # Get Google Calendar service
    try:
        service = get_gcal_service()
    except RuntimeError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    # Sync each task
    synced_count = 0
    for task in unique_tasks:
        try:
            cal_id = map_task_to_calendar(task, config)
            if not cal_id:
                print(f"WARNING: No calendar for task {task['id']}, skipping", file=sys.stderr)
                continue

            event = task_to_event(task, config)

            # Check if event already exists (search by description containing task ID)
            events_result = service.events().list(
                calendarId=cal_id,
                q=f"Task ID: {task['id']}",
                maxResults=1
            ).execute()

            existing_events = events_result.get('items', [])

            if existing_events:
                # Update existing event
                event_id = existing_events[0]['id']
                service.events().update(
                    calendarId=cal_id,
                    eventId=event_id,
                    body=event
                ).execute()
                print(f"  ✓ Updated: {task['description']}")
            else:
                # Create new event
                service.events().insert(
                    calendarId=cal_id,
                    body=event
                ).execute()
                print(f"  ✓ Created: {task['description']}")

            synced_count += 1

        except Exception as e:
            print(f"ERROR syncing task {task['id']}: {e}", file=sys.stderr)

    print(f"\n[ClaudeWarrior] Synced {synced_count}/{len(unique_tasks)} tasks")
    return 0


if __name__ == '__main__':
    # Support --dry-run flag
    dry_run = '--dry-run' in sys.argv

    try:
        sys.exit(sync_tasks_to_gcal(dry_run=dry_run))
    except KeyboardInterrupt:
        print("\nSync cancelled by user")
        sys.exit(130)
