#!/usr/bin/env bash
# packages-sync.sh — converge pacman + flatpak to match declaration files.
#
# Usage:
#   ./packages-sync.sh                     # install missing packages only
#   ./packages-sync.sh --dry-run           # preview installs, change nothing
#   ./packages-sync.sh --prune --dry-run   # preview installs + removals
#   ./packages-sync.sh --prune             # full converge (DESTRUCTIVE)
#
# Declaration files (relative to this script):
#   ../packages/pacman.txt    one package per line, # comments allowed
#   ../packages/flatpak.txt   one flatpak app ID per line, # comments allowed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACMAN_FILE="$SCRIPT_DIR/../packages/pacman.txt"
FLATPAK_FILE="$SCRIPT_DIR/../packages/flatpak.txt"

PRUNE=0
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --prune)   PRUNE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

for f in "$PACMAN_FILE" "$FLATPAK_FILE"; do
    [ -f "$f" ] || { echo "error: missing declaration file: $f" >&2; exit 1; }
done

# ── Read declarations (strip comments, blank lines, trailing whitespace) ──
read_pacman()  { grep -vE '^\s*(#|$)' "$PACMAN_FILE"  | sed 's/[[:space:]]*$//' | sort -u; }
read_flatpak() { grep -vE '^\s*(#|$)' "$FLATPAK_FILE" | sed 's/[[:space:]]*$//' | sort -u; }

# ── Read installed state (explicit native pacman pkgs, user flatpak apps) ──
installed_pacman()  { pacman -Qqen | sort -u; }
installed_flatpak() { flatpak list --user --app --columns=application | sort -u; }

# ── Diffs: -23 = declared-but-missing, -13 = installed-but-undeclared ──
to_install_pacman()  { comm -23 <(read_pacman)  <(installed_pacman); }
to_remove_pacman()   { comm -13 <(read_pacman)  <(installed_pacman); }
to_install_flatpak() { comm -23 <(read_flatpak) <(installed_flatpak); }
to_remove_flatpak()  { comm -13 <(read_flatpak) <(installed_flatpak); }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# ── pacman: install missing ──
install_pacman="$(to_install_pacman)"
if [ -n "$install_pacman" ]; then
    echo "==> pacman: installing $(echo "$install_pacman" | wc -l) package(s):"
    echo "$install_pacman" | sed 's/^/    /'
    # Intentional unquoted expansion: each line is a separate package name.
    run sudo pacman -S --needed --noconfirm $install_pacman
else
    echo "==> pacman: nothing to install"
fi

# ── flatpak: install missing ──
install_flatpak="$(to_install_flatpak)"
if [ -n "$install_flatpak" ]; then
    echo "==> flatpak: installing $(echo "$install_flatpak" | wc -l) app(s):"
    echo "$install_flatpak" | sed 's/^/    /'
    if [ "$DRY_RUN" -eq 0 ]; then
        flatpak remote-add --if-not-exists --user flathub \
            https://flathub.org/repo/flathub.flatpakrepo
    fi
    while read -r app; do
        run flatpak install --user --noninteractive flathub "$app"
    done <<< "$install_flatpak"
else
    echo "==> flatpak: nothing to install"
fi

# ── Optional prune (off by default; destructive) ──
if [ "$PRUNE" -eq 1 ]; then
    remove_pacman="$(to_remove_pacman)"
    if [ -n "$remove_pacman" ]; then
        echo "==> pacman: REMOVING $(echo "$remove_pacman" | wc -l) package(s):"
        echo "$remove_pacman" | sed 's/^/    /'
        run sudo pacman -Rns --noconfirm $remove_pacman
    else
        echo "==> pacman: nothing to remove"
    fi

    remove_flatpak="$(to_remove_flatpak)"
    if [ -n "$remove_flatpak" ]; then
        echo "==> flatpak: REMOVING $(echo "$remove_flatpak" | wc -l) app(s):"
        echo "$remove_flatpak" | sed 's/^/    /'
        while read -r app; do
            run flatpak uninstall --user --noninteractive "$app"
        done <<< "$remove_flatpak"
    else
        echo "==> flatpak: nothing to remove"
    fi
fi
