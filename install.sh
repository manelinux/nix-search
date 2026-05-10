#!/usr/bin/env bash

# =============================================================================
# install.sh — Install nix-search as a global binary
# =============================================================================

set -uo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

BINARY_NAME="nix-search"
INSTALL_DIR="/usr/local/bin"
NIXOS_CONFIG="/etc/nixos/configuration.nix"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/nix-search.sh"

echo -e "${BOLD}🔧 Installing ${CYAN}$BINARY_NAME${RESET}${BOLD}...${RESET}"

# --- Check source file exists ---
if [[ ! -f "$SOURCE" ]]; then
  echo -e "${RED}Error: '$SOURCE' not found${RESET}"
  echo "Make sure nix-search.sh is in the same directory as install.sh"
  exit 1
fi

# --- Create install directory if it doesn't exist ---
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo -e "${CYAN}Creating directory $INSTALL_DIR...${RESET}"
  sudo mkdir -p "$INSTALL_DIR"
fi

# --- Copy binary and set permissions ---
sudo cp "$SOURCE" "$INSTALL_DIR/$BINARY_NAME"
sudo chmod 755 "$INSTALL_DIR/$BINARY_NAME"
echo -e "${GREEN}✔ Binary installed at $INSTALL_DIR/$BINARY_NAME${RESET}"

# --- Add /usr/local/bin to global PATH via configuration.nix ---
if grep -q '/usr/local/bin' "$NIXOS_CONFIG" 2>/dev/null; then
  echo -e "${CYAN}ℹ /usr/local/bin already present in $NIXOS_CONFIG, skipping.${RESET}"
else
  echo -e "${CYAN}Adding /usr/local/bin to global PATH in $NIXOS_CONFIG...${RESET}"
  sudo sed -i 's|^}$|  # Added by install.sh - makes /usr/local/bin available to all users\n  environment.variables.PATH = [ "/usr/local/bin" ];\n}|' "$NIXOS_CONFIG"
  echo -e "${GREEN}✔ PATH updated in $NIXOS_CONFIG${RESET}"

  echo -e "${CYAN}Applying changes with nixos-rebuild switch...${RESET}"
  sudo nixos-rebuild switch
  echo -e "${GREEN}✔ System rebuilt successfully!${RESET}"
fi

echo ""
echo -e "${BOLD}nix-search is now available for all users:${RESET}"
echo -e "  ${CYAN}nix-search${RESET}"
echo -e "  ${CYAN}nix-search -a global -k xfce${RESET}"
echo -e "  ${CYAN}nix-search -k python --count${RESET}"
echo -e "  ${CYAN}nix-search --duplicates${RESET}"
echo ""
echo -e "To uninstall:"
echo -e "  ${CYAN}sudo rm $INSTALL_DIR/$BINARY_NAME${RESET}"
