#!/usr/bin/env python3
"""
Konfigurationsdatei für das Fruits-Modul
"""
import os
from pathlib import Path

# Basis-Datenverzeichnis
DATA_DIR: Path = Path(
    os.environ.get("ALPHAOS_DATA_DIR", str(Path.home() / "AlphaOs-Vault" / ".config"))
)

# Dateinamen für CSV und Backup
CSV_FILE: Path = DATA_DIR / "fruits.csv"
BACKUP_FILE: Path = CSV_FILE.with_suffix(".bak.csv")

# Obst-Emojis für CLI-Feedback
FRUIT_EMOJIS = [
    "🍎", "🍌", "🍇", "🍉", "🍓",
    "🍒", "🍍", "🥝", "🍊", "🍏"
]

# Ordner anlegen, falls nicht vorhanden
DATA_DIR.mkdir(parents=True, exist_ok=True)