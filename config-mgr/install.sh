#!/usr/bin/env bash

# Hoop Config Manager Installer
# Usage: curl -fsSL https://your-url/install.sh | bash

set -e

# Configuration
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
SCRIPT_NAME="hoop-config"
SCRIPT_URL="${SCRIPT_URL:-https://raw.githubusercontent.com/hoophq/utilities/main/config-mgr/hoop-config-manager.sh}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Installing Hoop Config Manager...${NC}"
echo ""

# Check if running with sufficient permissions
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Note: $INSTALL_DIR is not writable. You may need to run with sudo.${NC}"
    echo -e "${YELLOW}Attempting installation with sudo...${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# Download the script
echo -e "Downloading script..."
if command -v curl &> /dev/null; then
    TEMP_FILE=$(mktemp)
    curl -fsSL "$SCRIPT_URL" -o "$TEMP_FILE"
elif command -v wget &> /dev/null; then
    TEMP_FILE=$(mktemp)
    wget -q "$SCRIPT_URL" -O "$TEMP_FILE"
else
    echo -e "${RED}Error: curl or wget is required${NC}"
    exit 1
fi

# Install the script
echo -e "Installing to ${INSTALL_DIR}/${SCRIPT_NAME}..."
$SUDO mv "$TEMP_FILE" "${INSTALL_DIR}/${SCRIPT_NAME}"
$SUDO chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"

echo -e "${GREEN}✓${NC} Hoop Config Manager installed successfully!"
echo ""

# Detect shell and offer to add alias
SHELL_CONFIG=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    echo -e "${BLUE}Optional: Add a shorter alias?${NC}"
    echo -e "Add this to your $SHELL_CONFIG:"
    echo ""
    echo -e "  ${YELLOW}alias hc='hoop-config'${NC}"
    echo ""
fi

echo -e "Usage:"
echo -e "  ${GREEN}hoop-config${NC}              Show current config and list all"
echo -e "  ${GREEN}hoop-config add <name>${NC}   Create a new config"
echo -e "  ${GREEN}hoop-config load <name>${NC}  Switch to a saved config"
echo -e "  ${GREEN}hoop-config save <name>${NC}  Save current config"
echo -e "  ${GREEN}hoop-config help${NC}         Show all commands"
echo ""
echo -e "${GREEN}Installation complete!${NC}"
