#!/usr/bin/env bash

# =============================================================================
# nix-search.sh — Search installed packages on a NixOS system
# =============================================================================
# Usage:
#   nix-search [options]
#
# Options:
#   -a, --scope   <scope1,scope2,...>   Scopes to search (default: all)
#                 Values: user, global, flake, home-manager, all
#   -k, --keyword <word>                Filter results by keyword (optional)
#   -c, --count                         Show package count per scope
#   -d, --duplicates                    Show only packages found in more than one scope
#   -v, --version                       Show version
#   -h, --help                          Show this help message
#
# Examples:
#   nix-search                                     # All packages across all scopes
#   nix-search -a user                             # User-installed packages
#   nix-search -a global,user -k xfce             # Global and user scopes filtered by "xfce"
#   nix-search -a global,flake -k python          # Global and flake scopes filtered by "python"
#   nix-search -k gtk                             # All scopes filtered by "gtk"
#   nix-search --count                            # Package count per scope
#   nix-search --duplicates                       # Packages found in more than one scope
#   nix-search --duplicates -k xfce              # Duplicates filtered by "xfce"
# =============================================================================

VERSION="2.0.0"

set -uo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Defaults ---
SCOPES=()
KEYWORD=""
COUNT=false
DUPLICATES=false

# --- Help ---
show_help() {
  grep '^#' "$0" | grep -v '#!/' | sed 's/^# \?//'
  exit 0
}

# --- Version ---
show_version() {
  echo -e "${BOLD}nix-search${RESET} v${VERSION}"
  exit 0
}

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--scope)
      if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
        echo -e "${RED}Error: --scope requires a value (e.g. -a global,user)${RESET}"
        exit 1
      fi
      IFS=',' read -ra SCOPES <<< "$2"
      shift 2
      ;;
    -k|--keyword)
      if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
        echo -e "${RED}Error: --keyword requires a value (e.g. -k xfce)${RESET}"
        exit 1
      fi
      KEYWORD="$2"
      shift 2
      ;;
    -c|--count)
      COUNT=true
      shift
      ;;
    -d|--duplicates)
      DUPLICATES=true
      shift
      ;;
    -v|--version)
      show_version
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${RESET}"
      echo "Use -h for help."
      exit 1
      ;;
  esac
done

# --- Default to "all" if no scope specified ---
if [[ ${#SCOPES[@]} -eq 0 ]]; then
  SCOPES=("all")
fi

# --- Valid scopes ---
VALID_SCOPES=("user" "global" "flake" "home-manager" "all")

validate_scope() {
  local scope="$1"
  for valid in "${VALID_SCOPES[@]}"; do
    [[ "$scope" == "$valid" ]] && return 0
  done
  echo -e "${RED}Invalid scope: '$scope'${RESET}"
  echo -e "Valid options: ${CYAN}user, global, flake, home-manager, all${RESET}"
  exit 1
}

for scope in "${SCOPES[@]}"; do
  validate_scope "$scope"
done

# --- Expand "all" into individual scopes ---
expand_scopes() {
  local expanded=()
  for scope in "${SCOPES[@]}"; do
    if [[ "$scope" == "all" ]]; then
      expanded=("user" "global" "flake" "home-manager")
    else
      expanded+=("$scope")
    fi
  done
  # Deduplicate while preserving order
  local deduped=()
  for scope in "${expanded[@]}"; do
    local found=false
    for existing in "${deduped[@]:-}"; do
      [[ "$scope" == "$existing" ]] && found=true && break
    done
    $found || deduped+=("$scope")
  done
  SCOPES=("${deduped[@]}")
}
expand_scopes

# --- Keyword filter ---
filter() {
  if [[ -n "$KEYWORD" ]]; then
    grep -i "$KEYWORD" || true
  else
    cat
  fi
}

# --- Section header ---
header() {
  local label="$1"
  local keyword_info=""
  [[ -n "$KEYWORD" ]] && keyword_info=" (filtered by: '${KEYWORD}')"
  echo ""
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${GREEN}  $label${keyword_info}${RESET}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
}

# --- Package count ---
show_count() {
  local count="$1"
  echo -e "  ${MAGENTA}↳ Total: ${BOLD}$count${RESET}${MAGENTA} package(s)${RESET}"
}

# --- Temporary directory to collect packages for duplicate detection ---
TMPDIR_DUPES=$(mktemp -d)
trap 'rm -rf "$TMPDIR_DUPES"' EXIT

save_for_dupes() {
  local scope_label="$1"
  local unfiltered="$2"
  if [[ -n "$unfiltered" ]]; then
    echo "$unfiltered" | sed 's/^[a-z0-9]*-//' | sed 's/-[0-9].*//' \
      >> "$TMPDIR_DUPES/${scope_label}.txt"
  fi
}

# --- Scope: user (nix-env) ---
search_user() {
  local only_dupes="${1:-false}"
  local all_pkgs
  all_pkgs=$(nix-env -q --installed 2>/dev/null)
  save_for_dupes "user" "$all_pkgs"
  [[ "$only_dupes" == true ]] && return
  header "📦 USER PACKAGES (nix-env)"
  local result
  result=$(echo "$all_pkgs" | filter)
  if [[ -z "$result" ]]; then
    echo -e "${YELLOW}  (no packages found)${RESET}"
    $COUNT && show_count 0
  else
    echo "$result" | sed 's/^/  /'
    $COUNT && show_count "$(echo "$result" | wc -l)"
  fi
}

# --- Scope: global (system-wide) ---
search_global() {
  local only_dupes="${1:-false}"
  local all_pkgs
  all_pkgs=$(nix-store -q --requisites /run/current-system 2>/dev/null \
    | xargs -I{} basename {} \
    | sort -u)
  save_for_dupes "global" "$all_pkgs"
  [[ "$only_dupes" == true ]] && return
  header "🌐 GLOBAL SYSTEM PACKAGES (/run/current-system)"
  local result
  result=$(echo "$all_pkgs" | filter)
  if [[ -z "$result" ]]; then
    echo -e "${YELLOW}  (no packages found)${RESET}"
    $COUNT && show_count 0
  else
    echo "$result" | sed 's/^/  /'
    $COUNT && show_count "$(echo "$result" | wc -l)"
  fi
}

# --- Scope: flake profiles (all users) ---
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
    local all_pkgs
    all_pkgs=$(nix-store -q --requisites "$flake_profile" 2>/dev/null \
      | xargs -I{} basename {} \
      | sort -u)
    save_for_dupes "flake_$user" "$all_pkgs"
    [[ "$only_dupes" == true ]] && continue

    header "❄️  FLAKE PROFILE — $user ($flake_profile)"
    local result
    result=$(echo "$all_pkgs" | filter)
    if [[ -z "$result" ]]; then
      echo -e "${YELLOW}  (no packages found)${RESET}"
      $COUNT && show_count 0
    else
      echo "$result" | sed 's/^/  /'
      $COUNT && show_count "$(echo "$result" | wc -l)"
    fi
  done

  if [[ "$found_any" == false && "$only_dupes" == false ]]; then
    header "❄️  FLAKE PROFILES (all users)"
    echo -e "${YELLOW}  (no flake profiles found)${RESET}"
  fi
}

# --- Scope: Home Manager (all users) ---
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
    local all_pkgs
    all_pkgs=$(nix-store -q --requisites "$hm_profile" 2>/dev/null \
      | xargs -I{} basename {} \
      | sort -u)
    save_for_dupes "home_manager_$user" "$all_pkgs"
    [[ "$only_dupes" == true ]] && continue

    header "🏠 HOME MANAGER — $user ($hm_profile)"
    local result
    result=$(echo "$all_pkgs" | filter)
    if [[ -z "$result" ]]; then
      echo -e "${YELLOW}  (no packages found)${RESET}"
      $COUNT && show_count 0
    else
      echo "$result" | sed 's/^/  /'
      $COUNT && show_count "$(echo "$result" | wc -l)"
    fi
  done

  if [[ "$found_any" == false && "$only_dupes" == false ]]; then
    header "🏠 HOME MANAGER (all users)"
    echo -e "${YELLOW}  (Home Manager not detected for any user)${RESET}"
  fi
}

# --- Show duplicates ---
show_duplicates() {
  local keyword_info=""
  [[ -n "$KEYWORD" ]] && keyword_info=" (filtered by: '${KEYWORD}')"
  echo ""
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${YELLOW}  🔁 DUPLICATE PACKAGES ACROSS SCOPES${keyword_info}${RESET}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"

  local files=("$TMPDIR_DUPES"/*.txt)
  if [[ ${#files[@]} -lt 2 || ! -e "${files[0]}" ]]; then
    echo -e "${YELLOW}  (need at least two scopes with packages to detect duplicates)${RESET}"
    return
  fi

  local dupes
  dupes=$(sort "$TMPDIR_DUPES"/*.txt | uniq -d | filter)

  if [[ -z "$dupes" ]]; then
    echo -e "${YELLOW}  (no duplicates found)${RESET}"
  else
    while IFS= read -r pkg; do
      local scopes=()
      for file in "$TMPDIR_DUPES"/*.txt; do
        if grep -q "^${pkg}$" "$file" 2>/dev/null; then
          scopes+=("$(basename "$file" .txt)")
        fi
      done
      echo -e "  ${BOLD}$pkg${RESET} ${MAGENTA}→ ${scopes[*]}${RESET}"
    done <<< "$dupes"
    $COUNT && show_count "$(echo "$dupes" | wc -l)"
  fi
}

# --- Summary header ---
echo -e "${BOLD}🔍 nix-search${RESET} ${MAGENTA}v${VERSION}${RESET}"
echo -e "   Scope:      ${CYAN}$(IFS=','; echo "${SCOPES[*]}")${RESET}"
echo -e "   Keyword:    ${CYAN}${KEYWORD:-"(none, showing all)"}${RESET}"
echo -e "   Count:      ${CYAN}$($COUNT && echo "yes" || echo "no")${RESET}"
echo -e "   Duplicates: ${CYAN}$($DUPLICATES && echo "yes" || echo "no")${RESET}"

# --- Run ---
run_scope() {
  local scope="$1"
  local only_dupes="${2:-false}"
  case "$scope" in
    user)         search_user "$only_dupes" ;;
    global)       search_global "$only_dupes" ;;
    flake)        search_flake "$only_dupes" ;;
    home-manager) search_home_manager "$only_dupes" ;;
  esac
}

if $DUPLICATES; then
  for scope in "${SCOPES[@]}"; do
    run_scope "$scope" true
  done
  show_duplicates
else
  for scope in "${SCOPES[@]}"; do
    run_scope "$scope"
  done
fi

echo ""
