#!/bin/bash
# core.sh - Core utilities and path definitions

XCCLEAN_VERSION="1.0.0"

# Cleanable paths
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
ARCHIVES_PATH="$HOME/Library/Developer/Xcode/Archives"
IOS_DEVICE_SUPPORT_PATH="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
WATCHOS_DEVICE_SUPPORT_PATH="$HOME/Library/Developer/Xcode/watchOS DeviceSupport"
TVOS_DEVICE_SUPPORT_PATH="$HOME/Library/Developer/Xcode/tvOS DeviceSupport"
SIMULATORS_PATH="$HOME/Library/Developer/CoreSimulator/Devices"
SIMULATOR_CACHES_PATH="$HOME/Library/Developer/CoreSimulator/Caches"
BUILD_CACHES_PATH="$HOME/Library/Caches/com.apple.dt.xcodebuild"
XCODE_CACHE_PATH="$HOME/Library/Caches/com.apple.dt.Xcode"
DOCUMENTATION_CACHE_PATH="$HOME/Library/Developer/Xcode/DocumentationCache"

# All device support paths
DEVICE_SUPPORT_PATHS=(
    "$IOS_DEVICE_SUPPORT_PATH"
    "$WATCHOS_DEVICE_SUPPORT_PATH"
    "$TVOS_DEVICE_SUPPORT_PATH"
)

# All cache paths
CACHE_PATHS=(
    "$SIMULATOR_CACHES_PATH"
    "$BUILD_CACHES_PATH"
    "$XCODE_CACHE_PATH"
    "$DOCUMENTATION_CACHE_PATH"
)

# Safe paths for deletion (whitelist)
SAFE_PATH_PREFIXES=(
    "$HOME/Library/Developer/Xcode/"
    "$HOME/Library/Developer/CoreSimulator/"
    "$HOME/Library/Caches/com.apple.dt."
)

# Format bytes to human-readable size
format_size() {
    local bytes=$1

    if [[ -z "$bytes" ]] || [[ "$bytes" -eq 0 ]]; then
        echo "0 B"
        return
    fi

    if [[ "$bytes" -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ "$bytes" -lt 1048576 ]]; then
        echo "$(echo "scale=1; $bytes / 1024" | bc) KB"
    elif [[ "$bytes" -lt 1073741824 ]]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc) MB"
    else
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    fi
}

# Format bytes to human-readable size (compact version for tables)
format_size_compact() {
    local bytes=$1

    if [[ -z "$bytes" ]] || [[ "$bytes" -eq 0 ]]; then
        echo "0 B"
        return
    fi

    if [[ "$bytes" -lt 1024 ]]; then
        printf "%d B" "$bytes"
    elif [[ "$bytes" -lt 1048576 ]]; then
        printf "%.1f KB" "$(echo "$bytes / 1024" | bc -l)"
    elif [[ "$bytes" -lt 1073741824 ]]; then
        printf "%.1f MB" "$(echo "$bytes / 1048576" | bc -l)"
    else
        printf "%.1f GB" "$(echo "$bytes / 1073741824" | bc -l)"
    fi
}

# Check if path exists
path_exists() {
    [[ -e "$1" ]]
}

# Check if path is safe for deletion
is_safe_path() {
    local path="$1"

    # Must be an absolute path
    if [[ "${path:0:1}" != "/" ]]; then
        return 1
    fi

    # Resolve to absolute path (handle symlinks)
    local resolved_path
    resolved_path=$(cd "$(dirname "$path")" 2>/dev/null && pwd -P)/$(basename "$path")

    # Check against whitelist
    for prefix in "${SAFE_PATH_PREFIXES[@]}"; do
        if [[ "$resolved_path" == "$prefix"* ]]; then
            return 0
        fi
    done

    return 1
}

# Check if Xcode is running
is_xcode_running() {
    pgrep -x "Xcode" >/dev/null 2>&1
}

# Get modification time of file/directory (seconds since epoch)
get_mtime() {
    stat -f "%m" "$1" 2>/dev/null || echo "0"
}

# Get age of file/directory in days
get_age_days() {
    local path="$1"
    local mtime
    local now
    local age_seconds

    mtime=$(get_mtime "$path")
    now=$(date +%s)
    age_seconds=$((now - mtime))

    echo $((age_seconds / 86400))
}

# Parse project name from DerivedData directory name
parse_project_name() {
    local dir_name="$1"
    # DerivedData format: ProjectName-hash
    echo "$dir_name" | sed 's/-[a-z]*$//'
}

# Confirm action with user
confirm() {
    local message="$1"
    local default="${2:-n}"
    local response

    if [[ "${XCCLEAN_YES:-}" == "1" ]]; then
        return 0
    fi

    if [[ "$default" == "y" ]]; then
        printf "%s [Y/n] " "$message"
    else
        printf "%s [y/N] " "$message"
    fi

    read -r response

    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        "")
            [[ "$default" == "y" ]]
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# Log message (respects quiet mode)
log() {
    if [[ "${XCCLEAN_QUIET:-}" != "1" ]]; then
        echo "$@"
    fi
}

# Log verbose message
log_verbose() {
    if [[ "${XCCLEAN_VERBOSE:-}" == "1" ]]; then
        echo "$@"
    fi
}

# Output JSON if in JSON mode, otherwise normal output
output() {
    if [[ "${XCCLEAN_JSON:-}" == "1" ]]; then
        # JSON output handled by specific functions
        :
    else
        echo "$@"
    fi
}
