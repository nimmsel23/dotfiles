#!/usr/bin/env python3
"""
CLI-Entrypoint für das Fruits-Modul
"""
import sys
import os
from pathlib import Path

# Füge das Parent-Verzeichnis zum Python-Path hinzu
script_dir = Path(__file__).parent
parent_dir = script_dir.parent
sys.path.insert(0, str(parent_dir))

import random
from fruits.config import FRUIT_EMOJIS, CSV_FILE
from fruits.storage import backup_csv_once, load_answers, append_answer
from fruits.questions import QUESTIONS

SKIP_TOKEN = '!skip'

def cmd_fruits() -> None:
    """Progressive CLI für Foundational Fact Map"""
    header = ''.join(random.choices(FRUIT_EMOJIS, k=3))
    print(f"{header} Foundational Fact Map Questionnaire {header}")
    
    backup_csv_once()
    answers = load_answers()
    
    for section, qs in QUESTIONS.items():
        left, right = random.choice(FRUIT_EMOJIS), random.choice(FRUIT_EMOJIS)
        print(f"\n== {left} {section} {right} ==")
        
        for q in qs:
            if q in answers:
                print(f"\033[32m{q}\n└─ {answers[q]}\033[0m")
                continue
                
            emoji = random.choice(FRUIT_EMOJIS)
            ans = input(f"{emoji} {q} {emoji}\n> ").strip()
            
            if not ans or ans.lower() == SKIP_TOKEN:
                print(f"{emoji} Übersprungen. Wiederholen mit `ff`. {emoji}")
                return
                
            append_answer(section, q, ans)
            print(f"{emoji} Antwort gespeichert. Fortfahren mit `ff`. {emoji}")
            return
    
    print(f"✅ Alle Fragen beantwortet! Datei: {CSV_FILE}")

if __name__ == '__main__':
    cmd_fruits()