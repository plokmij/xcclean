#!/bin/bash
# colors.sh - ANSI color support with NO_COLOR fallback

# Setup colors based on terminal capabilities and NO_COLOR env
setup_colors() {
    # Respect NO_COLOR standard (https://no-color.org/)
    if [[ -n "${NO_COLOR:-}" ]] || [[ "${XCCLEAN_NO_COLOR:-}" == "1" ]]; then
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        MAGENTA=""
        BOLD=""
        DIM=""
        RESET=""
        return
    fi

    # Check if stdout is a terminal
    if [[ ! -t 1 ]]; then
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        MAGENTA=""
        BOLD=""
        DIM=""
        RESET=""
        return
    fi

    # Check terminal color support
    if command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        MAGENTA=$(tput setaf 5)
        CYAN=$(tput setaf 6)
        BOLD=$(tput bold)
        DIM=$(tput dim 2>/dev/null || echo "")
        RESET=$(tput sgr0)
    else
        # Fallback to ANSI escape codes
        RED=$'\033[0;31m'
        GREEN=$'\033[0;32m'
        YELLOW=$'\033[0;33m'
        BLUE=$'\033[0;34m'
        MAGENTA=$'\033[0;35m'
        CYAN=$'\033[0;36m'
        BOLD=$'\033[1m'
        DIM=$'\033[2m'
        RESET=$'\033[0m'
    fi
}

# Colored output helpers
print_error() {
    echo "${RED}Error:${RESET} $*" >&2
}

print_warning() {
    echo "${YELLOW}Warning:${RESET} $*" >&2
}

print_success() {
    echo "${GREEN}✓${RESET} $*"
}

print_info() {
    echo "${BLUE}→${RESET} $*"
}

# Initialize colors
setup_colors
