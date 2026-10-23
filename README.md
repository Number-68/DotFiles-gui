# GraphicsDotFiles

The Graphical stack for Arch Linux

## How to use it

```bash
chmod +x scripts/packages-sync.sh
```

### 1. Preview what would be installed — nothing changes

```bash
./scripts/packages-sync.sh --dry-run
```

### 2. Actually install missing packages

```bash
./scripts/packages-sync.sh
```

### 3. Preview a full converge, including removals

```bash
./scripts/packages-sync.sh --prune --dry-run
```

### 4. Full converge (only after reviewing step 3!)

```bash
./scripts/packages-sync.sh --prune
```

## File structure

```text
dotfiles/
├── .gitignore
├── README.md
├── install.sh
├── packages/
│   ├── pacman.txt
│   └── flatpak.txt
├── scripts/
│   └── packages-sync.sh
├── shell/
│   ├── .zshrc
│   └── .zshenv
└── hyprland/
    └── .config/
        ├── hypr/
        │   └── hyprland.conf
        └── waybar/
            ├── config.jsonc
            └── style.css
```
