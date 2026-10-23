# GraphicsDotFiles
The Graphical stack for Arch Linux

# How to use it

chmod +x scripts/packages-sync.sh

## 1. Preview what would be installed — nothing changes
./scripts/packages-sync.sh --dry-run

## 2. Actually install missing packages
./scripts/packages-sync.sh

## 3. Preview a full converge, including removals
./scripts/packages-sync.sh --prune --dry-run

## 4. Full converge (only after reviewing step 3!)
./scripts/packages-sync.sh --prune
