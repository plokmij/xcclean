#!/bin/bash
# xcclean installer
# Usage: curl -fsSL https://raw.githubusercontent.com/your-username/xcclean/main/install.sh | bash

set -euo pipefail

REPO_URL="https://github.com/your-username/xcclean"
INSTALL_DIR="/usr/local"
BIN_DIR="${INSTALL_DIR}/bin"
LIB_DIR="${INSTALL_DIR}/lib/xcclean"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

info() { echo -e "${BLUE}→${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warning() { echo -e "${YELLOW}!${RESET} $*"; }
error() { echo -e "${RED}✗${RESET} $*" >&2; }

# Check requirements
check_requirements() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "xcclean is only supported on macOS"
        exit 1
    fi

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        error "curl or wget is required for installation"
        exit 1
    fi
}

# Download file
download() {
    local url="$1"
    local dest="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    else
        wget -q "$url" -O "$dest"
    fi
}

# Install from local directory (for development)
install_local() {
    local source_dir="$1"

    info "Installing from local directory: $source_dir"

    # Create directories
    sudo mkdir -p "$BIN_DIR" "$LIB_DIR"

    # Copy library files
    sudo cp "$source_dir"/lib/*.sh "$LIB_DIR/"
    success "Installed library files to $LIB_DIR"

    # Copy and install binary
    sudo cp "$source_dir/bin/xcclean" "$BIN_DIR/"
    sudo chmod +x "$BIN_DIR/xcclean"
    success "Installed xcclean to $BIN_DIR"

    # Install completions if available
    if [[ -d "$source_dir/completions" ]]; then
        install_completions "$source_dir/completions"
    fi
}

# Install shell completions
install_completions() {
    local completions_dir="$1"

    # Bash completions
    if [[ -f "$completions_dir/xcclean.bash" ]]; then
        local bash_comp_dir="/usr/local/etc/bash_completion.d"
        if [[ -d "$bash_comp_dir" ]] || sudo mkdir -p "$bash_comp_dir" 2>/dev/null; then
            sudo cp "$completions_dir/xcclean.bash" "$bash_comp_dir/"
            success "Installed bash completions"
        fi
    fi

    # Zsh completions
    if [[ -f "$completions_dir/xcclean.zsh" ]]; then
        local zsh_comp_dir="/usr/local/share/zsh/site-functions"
        if [[ -d "$zsh_comp_dir" ]] || sudo mkdir -p "$zsh_comp_dir" 2>/dev/null; then
            sudo cp "$completions_dir/xcclean.zsh" "$zsh_comp_dir/_xcclean"
            success "Installed zsh completions"
        fi
    fi

    # Fish completions
    if [[ -f "$completions_dir/xcclean.fish" ]]; then
        local fish_comp_dir="/usr/local/share/fish/vendor_completions.d"
        if [[ -d "$fish_comp_dir" ]] || sudo mkdir -p "$fish_comp_dir" 2>/dev/null; then
            sudo cp "$completions_dir/xcclean.fish" "$fish_comp_dir/"
            success "Installed fish completions"
        fi
    fi
}

# Install from GitHub release
install_release() {
    local version="${1:-latest}"
    local tmp_dir

    tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" EXIT

    info "Downloading xcclean..."

    if [[ "$version" == "latest" ]]; then
        # Get latest release
        local release_url="${REPO_URL}/releases/latest/download/xcclean.tar.gz"
    else
        local release_url="${REPO_URL}/releases/download/${version}/xcclean.tar.gz"
    fi

    download "$release_url" "$tmp_dir/xcclean.tar.gz"

    info "Extracting..."
    tar -xzf "$tmp_dir/xcclean.tar.gz" -C "$tmp_dir"

    install_local "$tmp_dir/xcclean"
}

# Main installation
main() {
    echo ""
    echo "  xcclean installer"
    echo "  ─────────────────"
    echo ""

    check_requirements

    # Check if running from source directory
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -f "$script_dir/bin/xcclean" ]] && [[ -d "$script_dir/lib" ]]; then
        install_local "$script_dir"
    else
        install_release "${1:-latest}"
    fi

    echo ""
    success "xcclean installed successfully!"
    echo ""
    echo "  Run 'xcclean --help' to get started"
    echo "  Run 'xcclean' for interactive mode"
    echo ""
}

main "$@"
