#!/bin/bash

# --- VISUAL IDENTITY (EMBEDDED) ---
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

ICON_OK="✔"
ICON_FAIL="✘"
ICON_INFO="ℹ"
ICON_GEAR="⚙"

ui_banner() {
    clear
    echo -e "${GREEN}${BOLD}"
    echo "  _  __ _____ ____  ____   ___   ____ "
    echo " | |/ // ____/ ___||  _ \ / _ \ / ___|"
    echo " | ' /| |    \___ \| |_) | | | | |    "
    echo " |  < | |___  ___) |  __/| |_| | |___ "
    echo " |_|\_\\____/|____/|_|    \___/ \____|"
    echo -e "${NC}"
    echo -e "   Kaspersky Container Security PoC - Remote Installer"
    echo ""
    echo -e "${BLUE}  ====================================================${NC}"
    echo -e "${DIM}  Author: Artur Scheiner${NC}"
    echo ""
}

ui_section() {
    echo -e "${MAGENTA}${BOLD}:: $1 ::${NC}"
}

# --- INSTALLATION LOGIC ---

ui_banner

# 0. Pre-Installation Safety Audit
ui_section "Pre-Installation Safety Audit"

# A. OS Validation
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "   ${RED}${ICON_FAIL} Error: This tool is designed for Linux systems only.${NC}"
    echo -e "      Detected OS: $OSTYPE"
    exit 1
fi

# B. Critical Dependency Check (Source Fetching)
MISSING_FETCH_DEPS=true
if command -v git &>/dev/null; then
    MISSING_FETCH_DEPS=false
elif command -v unzip &>/dev/null && (command -v curl &>/dev/null || command -v wget &>/dev/null); then
    MISSING_FETCH_DEPS=false
fi

if [ "$MISSING_FETCH_DEPS" = true ]; then
    echo -e "   ${RED}${ICON_FAIL} Error: Missing critical dependencies for fetching source code.${NC}"
    echo -e "      Please install ${BOLD}'git'${NC} (recommended) or ${BOLD}'unzip'${NC} + ${BOLD}'curl'${NC}."
    echo -e "      Example: sudo apt update && sudo apt install -y git"
    exit 1
fi

echo -e "   ${ICON_OK} System environment and fetch-dependencies verified."
echo ""

# 1. Prepare Directory
ui_section "Preparing environment"
INSTALL_DIR="$HOME/.kcspoc"
echo -e "   ${ICON_GEAR} Creating directory ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1
echo -e "   ${ICON_OK} Environment ready."
echo ""

# 2. Fetch Source Code
ui_section "Fetching source code"
REPO_URL="https://github.com/arturscheiner/kcspoc.git"
ZIP_URL="https://github.com/arturscheiner/kcspoc/archive/refs/heads/main.zip"

# Clean up any existing clone attempts in ~/.kcspoc/kcspoc
rm -rf kcspoc bin kcspoc.zip kcspoc-main

if command -v git &>/dev/null; then
    echo -e "   ${ICON_GEAR} Cloning ${REPO_URL} via git..."
    if git clone "$REPO_URL" kcspoc &>/dev/null; then
        echo -e "   ${ICON_OK} Repository cloned successfully."
    else
        echo -e "   ${RED}${ICON_FAIL} Failed to clone repository.${NC}"
        exit 1
    fi
else
    echo -e "   ${YELLOW}${ICON_INFO} Git not found. Attempting ZIP download...${NC}"
    if ! command -v unzip &>/dev/null; then
        echo -e "   ${RED}${ICON_FAIL} Error: 'unzip' is required but not installed.${NC}"
        exit 1
    fi

    echo -e "   ${ICON_GEAR} Downloading source from GitHub..."
    if command -v curl &>/dev/null; then
        curl -L "$ZIP_URL" -o kcspoc.zip &>/dev/null
    elif command -v wget &>/dev/null; then
        wget -q "$ZIP_URL" -O kcspoc.zip &>/dev/null
    else
        echo -e "   ${RED}${ICON_FAIL} Error: Neither 'curl' nor 'wget' found.${NC}"
        exit 1
    fi

    if [ -f "kcspoc.zip" ]; then
        unzip -q kcspoc.zip
        mv kcspoc-main kcspoc
        rm kcspoc.zip
        echo -e "   ${ICON_OK} Source downloaded and extracted."
    else
        echo -e "   ${RED}${ICON_FAIL} Failed to download source ZIP.${NC}"
        exit 1
    fi
fi

# Detect Version
DETECTED_VER=$(grep 'VERSION=' kcspoc/lib/common.sh | cut -d'"' -f2)
echo -e "   ${ICON_OK} Ready to install version: ${BOLD}v${DETECTED_VER}${NC}"
echo ""

# 3. Rename and Organize
ui_section "Organizing deployment"
echo -e "   ${ICON_GEAR} Setting up binary directory..."
if [ -d "kcspoc" ]; then
    # Ensure executable permissions
    chmod +x kcspoc/kcspoc &>/dev/null
    mv kcspoc bin
    echo -e "   ${ICON_OK} Directory ./kcspoc renamed to ./bin"
else
    echo -e "   ${RED}${ICON_FAIL} Directory kcspoc not found after clone.${NC}"
    exit 1
fi
echo ""

# 4. Symbolic Link
ui_section "Finalizing installation"
BIN_PATH="$HOME/.kcspoc/bin/kcspoc"
# Try to find a good place for the symlink
# Priorities: /usr/local/bin (if writable), then $HOME/.local/bin, then $HOME/bin
SYMLINK_DEST=""
if [ -w "/usr/local/bin" ]; then
    SYMLINK_DEST="/usr/local/bin/kcspoc"
elif [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    SYMLINK_DEST="$HOME/.local/bin/kcspoc"
elif [ -d "$HOME/bin" ] && [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
    SYMLINK_DEST="$HOME/bin/kcspoc"
else
    # Fallback to /usr/local/bin but it might fail without sudo
    SYMLINK_DEST="/usr/local/bin/kcspoc"
fi

echo -e "   ${ICON_GEAR} Creating symlink at ${SYMLINK_DEST}..."
if ln -sf "$BIN_PATH" "$SYMLINK_DEST" 2>/dev/null; then
    echo -e "   ${ICON_OK} Symlink created successfully."
else
    echo -e "   ${YELLOW}${ICON_INFO} Permission denied. Attempting with sudo...${NC}"
    if sudo ln -sf "$BIN_PATH" "$SYMLINK_DEST"; then
        echo -e "   ${ICON_OK} Symlink created with sudo."
    else
        echo -e "   ${RED}${ICON_FAIL} Failed to create symlink. Please create it manually:${NC}"
        echo -e "      sudo ln -sf ${BIN_PATH} /usr/local/bin/kcspoc"
    fi
fi
echo ""

echo -e "${GREEN}${BOLD}   ${ICON_OK} KCS PoC Tool installed successfully! ${DIM}(v${DETECTED_VER:-unknown})${NC}"
echo -e "   You can now run '${BOLD}kcspoc${NC}' from anywhere."
echo ""

# Check if SYMLINK_DEST folder is in PATH
SYMLINK_DIR=$(dirname "$SYMLINK_DEST")
if [[ ":$PATH:" != *":$SYMLINK_DIR:"* ]]; then
    echo -e "   ${YELLOW}${ICON_WARN} WARNING: ${SYMLINK_DIR} is not in your PATH.${NC}"
    echo -e "   Add it to your ~/.bashrc or ~/.zshrc:"
    echo -e "      ${DIM}export PATH=\"\$PATH:${SYMLINK_DIR}\"${NC}"
    echo ""
fi

# 5. Dependency Audit
ui_section "Command Dependency Audit"
DEPS=("kubectl" "helm" "jq" "sed" "grep" "unzip")
for dep in "${DEPS[@]}"; do
    if command -v "$dep" &>/dev/null; then
        echo -e "   ${GREEN}${ICON_OK}${NC} ${dep}"
    else
        echo -e "   ${RED}${ICON_FAIL}${NC} ${dep} ${DIM}(Missing)${NC}"
    fi
done
echo ""

echo -e "   Next steps:"
echo -e "   ${DIM}1. Refresh shell: '${BOLD}hash -r${DIM}' (bash) or '${BOLD}rehash${DIM}' (zsh)${NC}"
echo -e "   ${DIM}2. Run '${BOLD}kcspoc config${DIM}' to set up your environment.${NC}"
echo -e "   ${DIM}3. Run '${BOLD}kcspoc pull${DIM}' to fetch the KCS charts.${NC}"
echo ""
