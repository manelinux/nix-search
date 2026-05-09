#!/usr/bin/env bash

# =============================================================================
# install.sh — Instal·la nix-search com a binari global
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

echo -e "${BOLD}🔧 Instal·lant ${CYAN}$BINARY_NAME${RESET}${BOLD}...${RESET}"

# --- Comprova que existeix el fitxer font ---
if [[ ! -f "$SOURCE" ]]; then
  echo -e "${RED}Error: no s'ha trobat '$SOURCE'${RESET}"
  echo "Assegura't que nix-search.sh és al mateix directori que install.sh"
  exit 1
fi

# --- Crea el directori si no existeix ---
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo -e "${CYAN}Creant directori $INSTALL_DIR...${RESET}"
  sudo mkdir -p "$INSTALL_DIR"
fi

# --- Copia el binari i dona permisos ---
sudo cp "$SOURCE" "$INSTALL_DIR/$BINARY_NAME"
sudo chmod 755 "$INSTALL_DIR/$BINARY_NAME"
echo -e "${GREEN}✔ Binari copiat a $INSTALL_DIR/$BINARY_NAME${RESET}"

# --- Afegir /usr/local/bin al PATH global via configuration.nix ---
if grep -q '/usr/local/bin' "$NIXOS_CONFIG" 2>/dev/null; then
  echo -e "${CYAN}ℹ /usr/local/bin ja present a $NIXOS_CONFIG, no es modifica.${RESET}"
else
  echo -e "${CYAN}Afegint /usr/local/bin al PATH global a $NIXOS_CONFIG...${RESET}"
  sudo sed -i 's|^}$|  # Afegit per install.sh - permet executar binaris de /usr/local/bin a tots els usuaris\n  environment.variables.PATH = [ "/usr/local/bin" ];\n}|' "$NIXOS_CONFIG"
  echo -e "${GREEN}✔ PATH afegit a $NIXOS_CONFIG${RESET}"

  echo -e "${CYAN}Aplicant canvis amb nixos-rebuild switch...${RESET}"
  sudo nixos-rebuild switch
  echo -e "${GREEN}✔ Sistema reconstruït!${RESET}"
fi

echo ""
echo -e "${BOLD}Ja pots fer servir-lo des de qualsevol usuari:${RESET}"
echo -e "  ${CYAN}nix-search${RESET}"
echo -e "  ${CYAN}nix-search -a global -k xfce${RESET}"
echo -e "  ${CYAN}nix-search -k python --count${RESET}"
echo -e "  ${CYAN}nix-search --duplicats${RESET}"
echo ""
echo -e "Per desinstal·lar:"
echo -e "  ${CYAN}sudo rm $INSTALL_DIR/$BINARY_NAME${RESET}"
