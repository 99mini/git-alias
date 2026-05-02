#!/usr/bin/env bash
# Git Alias Installer - Linux
set -euo pipefail

# ── bootstrap: fix curl | bash interactive input ──────────────────────────────
if [[ ! -t 0 && "${GIT_ALIAS_REEXEC:-}" != "1" ]]; then
  _tmp_self="$(mktemp /tmp/git-alias-install.XXXXXX.sh)"
  trap 'rm -f "$_tmp_self"' EXIT
  curl -fsSL "https://raw.githubusercontent.com/99mini/git-alias/main/install/linux.sh" \
    -o "$_tmp_self" || { echo "Error: failed to download installer" >&2; exit 1; }
  export GIT_ALIAS_REEXEC=1
  exec bash "$_tmp_self"
fi
[[ ! -t 0 ]] && exec < /dev/tty

# ── gitconfig location ─────────────────────────────────────────────────────────
_src="${BASH_SOURCE[0]:-}"
if [[ -n "$_src" && -f "$(dirname "$_src")/../alias/git-aliases.gitconfig" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$_src")" && pwd)"
  GITCONFIG_FILE="$SCRIPT_DIR/../alias/git-aliases.gitconfig"
else
  GITCONFIG_FILE="$(mktemp /tmp/git-aliases.XXXXXX.gitconfig)"
  trap 'rm -f "$GITCONFIG_FILE"' EXIT
  curl -fsSL "https://raw.githubusercontent.com/99mini/git-alias/main/alias/git-aliases.gitconfig" \
    -o "$GITCONFIG_FILE" || { echo "Error: Failed to download git-aliases.gitconfig" >&2; exit 1; }
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── helpers ──────────────────────────────────────────────────────────────────

die() { echo -e "${RED}Error: $*${NC}" >&2; exit 1; }

check_requirements() {
  command -v git &>/dev/null || die "git is not installed."
  [[ -f "$GITCONFIG_FILE" ]] || die "git-aliases.gitconfig not found at $GITCONFIG_FILE"
}

in_git_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null
}

get_alias_names() {
  git config --file "$GITCONFIG_FILE" --get-regexp '^alias\.' \
    | awk '{print $1}' | sed 's/^alias\.//' | sort
}

get_alias_value() {
  git config --file "$GITCONFIG_FILE" "alias.$1"
}

set_alias() {
  local scope="$1" name="$2"
  local value
  value=$(get_alias_value "$name")
  if git config "$scope" "alias.$name" "$value" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $name"
  else
    echo -e "  ${RED}✗${NC} $name (failed)"
  fi
}

unset_alias() {
  local scope="$1" name="$2"
  if git config "$scope" --unset "alias.$name" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $name removed"
  else
    echo -e "  ${YELLOW}~${NC} $name (not set)"
  fi
}

check_local_scope() {
  if ! in_git_repo; then
    echo -e "${RED}Error:${NC} Not inside a git repository."
    echo "  Run this from within a git repository to use local scope."
    echo "  Use global scope, or cd into a git project first."
    return 1
  fi
}

# ── bulk operations ───────────────────────────────────────────────────────────

install_all() {
  local scope="$1" label="$2"
  [[ "$scope" == "--local" ]] && { check_local_scope || return; }
  echo -e "\n${BLUE}Installing all aliases ($label)...${NC}\n"
  while IFS= read -r name; do
    set_alias "$scope" "$name"
  done < <(get_alias_names)
  echo -e "\n${GREEN}Done! All aliases installed ($label).${NC}"
}

remove_all() {
  local scope="$1" label="$2"
  [[ "$scope" == "--local" ]] && { check_local_scope || return; }
  echo -e "\n${YELLOW}Removing all aliases ($label)...${NC}\n"
  while IFS= read -r name; do
    unset_alias "$scope" "$name"
  done < <(get_alias_names)
  echo -e "\n${GREEN}Done! All aliases removed ($label).${NC}"
}

# ── selective operations ──────────────────────────────────────────────────────

pick_aliases() {
  local action="$1" scope="$2" label="$3"
  [[ "$scope" == "--local" ]] && { check_local_scope || return; }

  local -a names=()
  while IFS= read -r name; do
    names+=("$name")
  done < <(get_alias_names)

  echo -e "\n${BLUE}Available aliases:${NC}\n"
  local i
  for i in "${!names[@]}"; do
    printf "  %3d) %s\n" "$((i+1))" "${names[$i]}"
  done

  echo ""
  echo -e "Enter numbers separated by spaces (e.g. ${BOLD}1 3 5${NC}),"
  echo -e "  ${BOLD}all${NC} to select all, or ${BOLD}q${NC} to go back:"
  read -rp "> " selection

  [[ "$selection" == "q" || "$selection" == "Q" ]] && return

  if [[ "$selection" == "all" ]]; then
    if [[ "$action" == "install" ]]; then
      install_all "$scope" "$label"
    else
      remove_all "$scope" "$label"
    fi
    return
  fi

  echo ""
  local num
  for num in $selection; do
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#names[@]} )); then
      local name="${names[$((num-1))]}"
      if [[ "$action" == "install" ]]; then
        set_alias "$scope" "$name"
      else
        unset_alias "$scope" "$name"
      fi
    else
      echo -e "  ${RED}Invalid:${NC} $num"
    fi
  done
  echo -e "\n${GREEN}Done!${NC}"
}

# ── dependency check ──────────────────────────────────────────────────────────

detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then echo "apt"
  elif command -v dnf &>/dev/null; then echo "dnf"
  elif command -v yum &>/dev/null; then echo "yum"
  elif command -v pacman &>/dev/null; then echo "pacman"
  elif command -v zypper &>/dev/null; then echo "zypper"
  else echo "unknown"
  fi
}

pkg_install_cmd() {
  local pkg_mgr="$1" pkg="$2"
  case "$pkg_mgr" in
    apt)    echo "sudo apt-get install -y $pkg" ;;
    dnf)    echo "sudo dnf install -y $pkg" ;;
    yum)    echo "sudo yum install -y $pkg" ;;
    pacman) echo "sudo pacman -S $pkg" ;;
    zypper) echo "sudo zypper install $pkg" ;;
    *)      echo "# install $pkg manually" ;;
  esac
}

check_deps() {
  echo -e "\n${BLUE}Checking dependencies...${NC}\n"
  local pkg_mgr ok=true
  pkg_mgr=$(detect_pkg_manager)

  if command -v fzf &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} fzf $(fzf --version 2>/dev/null | head -1)"
  else
    echo -e "  ${RED}✗${NC} fzf  (required for interactive selector aliases)"
    echo -e "    Install: ${BOLD}$(pkg_install_cmd "$pkg_mgr" "fzf")${NC}"
    ok=false
  fi

  if command -v pygmentize &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} pygments ($(pygmentize -V 2>/dev/null | head -1))"
  else
    local py_pkg="python3-pygments"
    [[ "$pkg_mgr" == "pacman" ]] && py_pkg="python-pygments"
    echo -e "  ${YELLOW}!${NC} pygments  (optional — used for diff syntax highlighting)"
    echo -e "    Install: ${BOLD}$(pkg_install_cmd "$pkg_mgr" "$py_pkg")${NC}"
  fi

  if [[ "$ok" == false ]]; then
    echo -e "\n${YELLOW}Install missing dependencies, then re-run this installer.${NC}"
  else
    echo -e "\n${GREEN}All required dependencies are installed.${NC}"
  fi
}

# ── menu ──────────────────────────────────────────────────────────────────────

show_menu() {
  echo -e "\n${CYAN}╔════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║       Git Alias Installer           ║${NC}"
  echo -e "${CYAN}║            Linux                    ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Install${NC}"
  echo "   1) Install ALL aliases  (local workspace)"
  echo "   2) Install ALL aliases  (global)"
  echo "   3) Install specific aliases  (local workspace)"
  echo "   4) Install specific aliases  (global)"
  echo ""
  echo -e "  ${BOLD}Remove${NC}"
  echo "   5) Remove ALL aliases   (local workspace)"
  echo "   6) Remove ALL aliases   (global)"
  echo "   7) Remove specific aliases   (local workspace)"
  echo "   8) Remove specific aliases   (global)"
  echo ""
  echo -e "  ${BOLD}Other${NC}"
  echo "   9) Check dependencies"
  echo "   0) Exit"
  echo ""
}

# ── entry point ───────────────────────────────────────────────────────────────

main() {
  check_requirements

  while true; do
    show_menu
    read -rp "Select option: " choice
    case "$choice" in
      1) install_all "--local"  "local workspace" ;;
      2) install_all "--global" "global"          ;;
      3) pick_aliases "install" "--local"  "local workspace" ;;
      4) pick_aliases "install" "--global" "global"          ;;
      5) remove_all "--local"  "local workspace" ;;
      6) remove_all "--global" "global"          ;;
      7) pick_aliases "remove" "--local"  "local workspace" ;;
      8) pick_aliases "remove" "--global" "global"          ;;
      9) check_deps ;;
      0|q|Q) echo -e "\n${GREEN}Goodbye!${NC}\n"; exit 0 ;;
      *) echo -e "\n${RED}Invalid option: $choice${NC}" ;;
    esac
    echo ""
    read -rp "Press Enter to continue..."
  done
}

main "$@"
