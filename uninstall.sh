#!/bin/bash
# xcclean uninstaller

set -euo pipefail

INSTALL_DIR="/usr/local"
BIN_DIR="${INSTALL_DIR}/bin"
LIB_DIR="${INSTALL_DIR}/lib/xcclean"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

info() { echo -e "→ $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warning() { echo -e "${YELLOW}!${RESET} $*"; }

echo ""
echo "  xcclean uninstaller"
echo "  ───────────────────"
echo ""

# Remove binary
if [[ -f "$BIN_DIR/xcclean" ]]; then
    sudo rm -f "$BIN_DIR/xcclean"
    success "Removed $BIN_DIR/xcclean"
else
    warning "Binary not found at $BIN_DIR/xcclean"
fi

# Remove library
if [[ -d "$LIB_DIR" ]]; then
    sudo rm -rf "$LIB_DIR"
    success "Removed $LIB_DIR"
else
    warning "Library directory not found at $LIB_DIR"
fi

# Remove completions
completion_files=(
    "/usr/local/etc/bash_completion.d/xcclean.bash"
    "/usr/local/share/zsh/site-functions/_xcclean"
    "/usr/local/share/fish/vendor_completions.d/xcclean.fish"
)

for file in "${completion_files[@]}"; do
    if [[ -f "$file" ]]; then
        sudo rm -f "$file"
        success "Removed $file"
    fi
done

echo ""
success "xcclean uninstalled successfully!"
echo ""
