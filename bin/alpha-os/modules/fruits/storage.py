#!/usr/bin/env python3
"""
CSV-Persistence für Fruits-Modul
"""
from pathlib import Path
import csv
import shutil
from .config import CSV_FILE, BACKUP_FILE

def _ensure_parent(path: Path) -> None:
    """Stellt sicher, dass das Verzeichnis existiert"""
    path.parent.mkdir(parents=True, exist_ok=True)

def backup_csv_once() -> None:
    """Einmaliges Backup der fruits.csv"""
    if CSV_FILE.exists() and not BACKUP_FILE.exists():
        _ensure_parent(BACKUP_FILE)
        shutil.copy2(CSV_FILE, BACKUP_FILE)

def load_answers() -> dict[str, str]:
    """Lädt alle vorhandenen Antworten aus der CSV"""
    if not CSV_FILE.exists():
        return {}
    
    with CSV_FILE.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return {row['question']: row['answer'] for row in reader if row.get('answer')}

def append_answer(section: str, question: str, answer: str) -> None:
    """Hängt eine Antwort an die CSV an"""
    _ensure_parent(CSV_FILE)
    write_header = not CSV_FILE.exists() or CSV_FILE.stat().st_size == 0
    
    with CSV_FILE.open('a', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['section','question','answer'], lineterminator='\n')
        if write_header:
            writer.writeheader()
        writer.writerow({'section': section, 'question': question, 'answer': answer})