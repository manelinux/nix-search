#!/usr/bin/env bash

# =============================================================================
# nix-search.sh — Cerca paquets instal·lats a NixOS
# =============================================================================
# Ús:
#   nix-search [opcions]
#
# Opcions:
#   -a, --ambit   <ambit1,ambit2,...>   Àmbits de cerca separats per comes (per defecte: tots)
#                 Valors: usuari, global, flake, home-manager, tots
#   -k, --keyword <paraula>             Paraula clau per filtrar (opcional)
#   -c, --count                         Mostra el recompte de paquets per àmbit
#   -d, --duplicats                     Llista només els paquets duplicats entre àmbits
#   -v, --version                       Mostra la versió de l'eina
#   -h, --help                          Mostra aquesta ajuda
#
# Exemples:
#   nix-search                                     # Tots els paquets de tots els àmbits
#   nix-search -a usuari                           # Paquets de l'usuari
#   nix-search -a global,usuari -k xfce           # Global i usuari filtrats per "xfce"
#   nix-search -a global,flake -k python          # Global i flake filtrats per "python"
#   nix-search -k gtk                             # Tots els àmbits filtrats per "gtk"
#   nix-search --count                            # Recompte de paquets per àmbit
#   nix-search --duplicats                        # Llista paquets duplicats entre àmbits
#   nix-search --duplicats -k xfce               # Duplicats que contenen "xfce"
# =============================================================================

VERSION="1.5.0"

set -uo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Valors per defecte ---
AMBITS=()
KEYWORD=""
COUNT=false
DUPLICATS=false

# --- Ajuda ---
show_help() {
  grep '^#' "$0" | grep -v '#!/' | sed 's/^# \?//'
  exit 0
}

# --- Versió ---
show_version() {
  echo -e "${BOLD}nix-search${RESET} v${VERSION}"
  exit 0
}

# --- Parseig d'arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--ambit)
      if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
        echo -e "${RED}Error: --ambit requereix un valor (ex: -a global,usuari)${RESET}"
        exit 1
      fi
      IFS=',' read -ra AMBITS <<< "$2"
      shift 2
      ;;
    -k|--keyword)
      if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
        echo -e "${RED}Error: --keyword requereix un valor (ex: -k xfce)${RESET}"
        exit 1
      fi
      KEYWORD="$2"
      shift 2
      ;;
    -c|--count)
      COUNT=true
      shift
      ;;
    -d|--duplicats)
      DUPLICATS=true
      shift
      ;;
    -v|--version)
      show_version
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo -e "${RED}Argument desconegut: $1${RESET}"
      echo "Fes servir -h per veure l'ajuda."
      exit 1
      ;;
  esac
done

# --- Si no s'ha especificat cap àmbit, usar "tots" ---
if [[ ${#AMBITS[@]} -eq 0 ]]; then
  AMBITS=("tots")
fi

# --- Àmbits vàlids ---
AMBITS_VALIDS=("usuari" "global" "flake" "home-manager" "tots")

validate_ambit() {
  local ambit="$1"
  for valid in "${AMBITS_VALIDS[@]}"; do
    [[ "$ambit" == "$valid" ]] && return 0
  done
  echo -e "${RED}Àmbit invàlid: '$ambit'${RESET}"
  echo -e "Opcions vàlides: ${CYAN}usuari, global, flake, home-manager, tots${RESET}"
  exit 1
}

for ambit in "${AMBITS[@]}"; do
  validate_ambit "$ambit"
done

# --- Expandir "tots" si apareix entre d'altres ---
expand_ambits() {
  local expanded=()
  for ambit in "${AMBITS[@]}"; do
    if [[ "$ambit" == "tots" ]]; then
      expanded=("usuari" "global" "flake" "home-manager")
    else
      expanded+=("$ambit")
    fi
  done
  # Deduplicar mantenint ordre
  local deduped=()
  for ambit in "${expanded[@]}"; do
    local found=false
    for existing in "${deduped[@]:-}"; do
      [[ "$ambit" == "$existing" ]] && found=true && break
    done
    $found || deduped+=("$ambit")
  done
  AMBITS=("${deduped[@]}")
}
expand_ambits

# --- Funció de filtratge per keyword ---
filter() {
  if [[ -n "$KEYWORD" ]]; then
    grep -i "$KEYWORD" || true
  else
    cat
  fi
}

# --- Funció per imprimir capçalera ---
header() {
  local label="$1"
  local keyword_info=""
  [[ -n "$KEYWORD" ]] && keyword_info=" (filtrat per: '${KEYWORD}')"
  echo ""
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${GREEN}  $label${keyword_info}${RESET}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
}

# --- Funció per mostrar recompte ---
show_count() {
  local count="$1"
  echo -e "  ${MAGENTA}↳ Total: ${BOLD}$count${RESET}${MAGENTA} paquet(s)${RESET}"
}

# --- Directori temporal per als duplicats ---
TMPDIR_DUPES=$(mktemp -d)
trap 'rm -rf "$TMPDIR_DUPES"' EXIT

save_for_dupes() {
  local ambit_label="$1"
  local result_sense_filtre="$2"
  if [[ -n "$result_sense_filtre" ]]; then
    echo "$result_sense_filtre" | sed 's/^[a-z0-9]*-//' | sed 's/-[0-9].*//' \
      >> "$TMPDIR_DUPES/${ambit_label}.txt"
  fi
}

# --- Funció: paquets d'usuari ---
search_usuari() {
  local only_dupes="${1:-false}"
  local tots
  tots=$(nix-env -q --installed 2>/dev/null)
  save_for_dupes "usuari" "$tots"
  [[ "$only_dupes" == true ]] && return
  header "📦 PAQUETS D'USUARI (nix-env)"
  local result
  result=$(echo "$tots" | filter)
  if [[ -z "$result" ]]; then
    echo -e "${YELLOW}  (cap paquet trobat)${RESET}"
    $COUNT && show_count 0
  else
    echo "$result" | sed 's/^/  /'
    $COUNT && show_count "$(echo "$result" | wc -l)"
  fi
}

# --- Funció: paquets globals del sistema ---
search_global() {
  local only_dupes="${1:-false}"
  local tots
  tots=$(nix-store -q --requisites /run/current-system 2>/dev/null \
    | xargs -I{} basename {} \
    | sort -u)
  save_for_dupes "global" "$tots"
  [[ "$only_dupes" == true ]] && return
  header "🌐 PAQUETS GLOBALS DEL SISTEMA (/run/current-system)"
  local result
  result=$(echo "$tots" | filter)
  if [[ -z "$result" ]]; then
    echo -e "${YELLOW}  (cap paquet trobat)${RESET}"
    $COUNT && show_count 0
  else
    echo "$result" | sed 's/^/  /'
    $COUNT && show_count "$(echo "$result" | wc -l)"
  fi
}

# --- Funció: paquets dels perfils flake de tots els usuaris ---
search_flake() {
  local only_dupes="${1:-false}"
  local found_any=false

  local homes=()
  for user_home in /home/*/; do
    [[ -d "$user_home" ]] && homes+=("$user_home")
  done
  homes+=("/root")

  for user_home in "${homes[@]}"; do
    local user
    user=$(basename "$user_home")
    local flake_profile="$user_home/.local/state/nix/profiles/profile"
    if [[ ! -e "$flake_profile" ]]; then continue; fi

    found_any=true
    local tots
    tots=$(nix-store -q --requisites "$flake_profile" 2>/dev/null \
      | xargs -I{} basename {} \
      | sort -u)
    save_for_dupes "flake_$user" "$tots"
    [[ "$only_dupes" == true ]] && continue

    header "❄️  FLAKE de $user ($flake_profile)"
    local result
    result=$(echo "$tots" | filter)
    if [[ -z "$result" ]]; then
      echo -e "${YELLOW}  (cap paquet trobat)${RESET}"
      $COUNT && show_count 0
    else
      echo "$result" | sed 's/^/  /'
      $COUNT && show_count "$(echo "$result" | wc -l)"
    fi
  done

  if [[ "$found_any" == false && "$only_dupes" == false ]]; then
    header "❄️  FLAKE (tots els usuaris)"
    echo -e "${YELLOW}  (cap perfil de flake trobat)${RESET}"
  fi
}

# --- Funció: paquets de Home Manager de tots els usuaris ---
search_home_manager() {
  local only_dupes="${1:-false}"
  local found_any=false

  local homes=()
  for user_home in /home/*/; do
    [[ -d "$user_home" ]] && homes+=("$user_home")
  done
  homes+=("/root")

  for user_home in "${homes[@]}"; do
    local user
    user=$(basename "$user_home")

    local hm_profile=""
    if [[ -e "$user_home/.local/state/home-manager/gcroots/current-home" ]]; then
      hm_profile="$user_home/.local/state/home-manager/gcroots/current-home"
    elif [[ -e "$user_home/.nix-profile" ]]; then
      hm_profile="$user_home/.nix-profile"
    fi
    if [[ -z "$hm_profile" ]]; then continue; fi

    found_any=true
    local tots
    tots=$(nix-store -q --requisites "$hm_profile" 2>/dev/null \
      | xargs -I{} basename {} \
      | sort -u)
    save_for_dupes "home_manager_$user" "$tots"
    [[ "$only_dupes" == true ]] && continue

    header "🏠 HOME MANAGER de $user ($hm_profile)"
    local result
    result=$(echo "$tots" | filter)
    if [[ -z "$result" ]]; then
      echo -e "${YELLOW}  (cap paquet trobat)${RESET}"
      $COUNT && show_count 0
    else
      echo "$result" | sed 's/^/  /'
      $COUNT && show_count "$(echo "$result" | wc -l)"
    fi
  done

  if [[ "$found_any" == false && "$only_dupes" == false ]]; then
    header "🏠 HOME MANAGER (tots els usuaris)"
    echo -e "${YELLOW}  (Home Manager no detectat en cap usuari)${RESET}"
  fi
}

# --- Funció: mostrar duplicats ---
show_duplicats() {
  local keyword_info=""
  [[ -n "$KEYWORD" ]] && keyword_info=" (filtrat per: '${KEYWORD}')"
  echo ""
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${YELLOW}  🔁 PAQUETS DUPLICATS ENTRE ÀMBITS${keyword_info}${RESET}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"

  local fitxers=("$TMPDIR_DUPES"/*.txt)
  if [[ ${#fitxers[@]} -lt 2 || ! -e "${fitxers[0]}" ]]; then
    echo -e "${YELLOW}  (cal almenys dos àmbits amb paquets per detectar duplicats)${RESET}"
    return
  fi

  local dupes
  dupes=$(sort "$TMPDIR_DUPES"/*.txt | uniq -d | filter)

  if [[ -z "$dupes" ]]; then
    echo -e "${YELLOW}  (cap duplicat trobat)${RESET}"
  else
    while IFS= read -r paquet; do
      local ambits=()
      for fitxer in "$TMPDIR_DUPES"/*.txt; do
        if grep -q "^${paquet}$" "$fitxer" 2>/dev/null; then
          ambits+=("$(basename "$fitxer" .txt)")
        fi
      done
      echo -e "  ${BOLD}$paquet${RESET} ${MAGENTA}→ ${ambits[*]}${RESET}"
    done <<< "$dupes"
    $COUNT && show_count "$(echo "$dupes" | wc -l)"
  fi
}

# --- Resum inicial ---
echo -e "${BOLD}🔍 nix-search${RESET} ${MAGENTA}v${VERSION}${RESET}"
echo -e "   Àmbit:    ${CYAN}$(IFS=','; echo "${AMBITS[*]}")${RESET}"
echo -e "   Keyword:  ${CYAN}${KEYWORD:-"(cap, mostra tots)"}${RESET}"
echo -e "   Recompte: ${CYAN}$($COUNT && echo "sí" || echo "no")${RESET}"
echo -e "   Duplicats:${CYAN}$($DUPLICATS && echo "sí" || echo "no")${RESET}"

# --- Execució ---
run_ambit() {
  local ambit="$1"
  local only_dupes="${2:-false}"
  case "$ambit" in
    usuari)       search_usuari "$only_dupes" ;;
    global)       search_global "$only_dupes" ;;
    flake)        search_flake "$only_dupes" ;;
    home-manager) search_home_manager "$only_dupes" ;;
  esac
}

if $DUPLICATS; then
  for ambit in "${AMBITS[@]}"; do
    run_ambit "$ambit" true
  done
  show_duplicats
else
  for ambit in "${AMBITS[@]}"; do
    run_ambit "$ambit"
  done
fi

echo ""
