#!/bin/bash
# Alpha OS Tools Setup Script
# Installs AlphaOS productivity tools from dev_legacy to .dotfiles

set -e

SCRIPT_DIR="$HOME/.dotfiles/bin/alpha-os"
BIN_DIR="$HOME/bin"
DEV_LEGACY="$HOME/dev_legacy"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    AlphaOS Tools Setup Script         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# 1. Check if dev_legacy exists
if [ ! -d "$DEV_LEGACY" ]; then
    echo -e "${RED}✗ dev_legacy directory not found at $DEV_LEGACY${NC}"
    exit 1
fi

echo -e "${YELLOW}→ Checking directories...${NC}"

# 2. Create directories
mkdir -p "$BIN_DIR"
mkdir -p "$SCRIPT_DIR/modules"
echo -e "${GREEN}✓ Directories created${NC}"

# 3. Copy tools from dev_legacy
echo -e "${YELLOW}→ Copying tools...${NC}"

cp "$DEV_LEGACY/alpha-os/alpha-game/frame_map.py" "$SCRIPT_DIR/frame"
cp "$DEV_LEGACY/alpha-os/alpha-game/freedom_map.py" "$SCRIPT_DIR/freedom"
cp "$DEV_LEGACY/alpha-os/alpha-code/fruitsCLI.py" "$SCRIPT_DIR/fruits"
cp "$DEV_LEGACY/alpha-os/alpha-game/generals_tent.py" "$SCRIPT_DIR/tent"
cp "$DEV_LEGACY/alpha-os/456five_pillars_shell.py" "$SCRIPT_DIR/alpha"

echo -e "${GREEN}✓ Tools copied${NC}"

# 4. Copy modules
echo -e "${YELLOW}→ Copying Python modules...${NC}"
cp -r "$DEV_LEGACY/alpha-os/alpha-code/fruits" "$SCRIPT_DIR/modules/"
echo -e "${GREEN}✓ Modules copied${NC}"

# 5. Add shebangs to Python scripts if missing
echo -e "${YELLOW}→ Adding shebang lines...${NC}"
for file in "$SCRIPT_DIR/frame" "$SCRIPT_DIR/freedom" "$SCRIPT_DIR/tent"; do
    if ! head -n1 "$file" | grep -q "^#!"; then
        sed -i '1i#!/usr/bin/env python3' "$file"
    fi
done
echo -e "${GREEN}✓ Shebangs added${NC}"

# 6. Make executable
echo -e "${YELLOW}→ Making scripts executable...${NC}"
chmod +x "$SCRIPT_DIR"/{frame,freedom,fruits,tent,alpha}
echo -e "${GREEN}✓ Scripts executable${NC}"

# 7. Create symlinks to ~/bin/
echo -e "${YELLOW}→ Creating symlinks...${NC}"
ln -sf "$SCRIPT_DIR/frame" "$BIN_DIR/frame"
ln -sf "$SCRIPT_DIR/freedom" "$BIN_DIR/freedom"
ln -sf "$SCRIPT_DIR/fruits" "$BIN_DIR/fruits"
ln -sf "$SCRIPT_DIR/tent" "$BIN_DIR/tent"
ln -sf "$SCRIPT_DIR/alpha" "$BIN_DIR/alpha"
echo -e "${GREEN}✓ Symlinks created${NC}"

# 8. Create config directories
echo -e "${YELLOW}→ Creating config directories...${NC}"
mkdir -p "$HOME/.alpha_os"
mkdir -p "$HOME/.alphaos"
mkdir -p "$HOME/game_frames"
mkdir -p "$HOME/game_freedoms"
mkdir -p "$HOME/game/generals_tent"
echo -e "${GREEN}✓ Config directories ready${NC}"

# 9. Check Python dependencies
echo -e "${YELLOW}→ Checking Python dependencies...${NC}"
if ! python3 -c "import typer" 2>/dev/null; then
    echo -e "${YELLOW}  Missing: typer (pip install typer)${NC}"
fi
if ! python3 -c "import rich" 2>/dev/null; then
    echo -e "${YELLOW}  Missing: rich (pip install rich)${NC}"
fi
if ! python3 -c "import colorama" 2>/dev/null; then
    echo -e "${YELLOW}  Missing: colorama (pip install colorama)${NC}"
fi
if ! python3 -c "import yaml" 2>/dev/null; then
    echo -e "${YELLOW}  Missing: pyyaml (pip install pyyaml)${NC}"
fi

# 10. Done
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    ✓ AlphaOS Tools Installation       ║${NC}"
echo -e "${GREEN}║         Complete!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Available commands:${NC}"
echo "  ${GREEN}alpha${NC}    - Five Pillars Interface (Main Menu)"
echo "  ${GREEN}frame${NC}    - Frame Map (Wo stehe ich?)"
echo "  ${GREEN}freedom${NC}  - Freedom Map (Wo will ich hin?)"
echo "  ${GREEN}fruits${NC}   - FRUITS CLI (Foundational Facts)"
echo "  ${GREEN}tent${NC}     - General's Tent (Weekly Review)"
echo ""
echo -e "${YELLOW}Note:${NC} Make sure ~/bin is in your PATH"
echo ""
