#!/usr/bin/env bash
# Bootstrap: install packages, then stow dotfiles into $HOME.
set -euo pipefail

cd "$(dirname "$0")"

# ── 1. Ensure Stow is available ──
if ! command -v stow >/dev/null; then
    echo "==> installing GNU Stow"
    sudo pacman -S --needed --noconfirm stow
fi

# ── 2. Install packages ──
echo "==> syncing packages"
./scripts/packages-sync.sh

# ── 3. Stow dotfile packages into $HOME ──
PACKAGES=(
    shell
    hyprland
)

echo "==> stowing dotfiles into $HOME"
stow -v -t "$HOME" "${PACKAGES[@]}"

echo "==> done. Log out and back in to pick up WM changes."