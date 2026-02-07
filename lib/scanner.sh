#!/bin/bash
# scanner.sh - Size calculation and enumeration functions

# Get directory size in bytes
get_dir_size_bytes() {
    local path="$1"

    if [[ ! -d "$path" ]]; then
        echo "0"
        return
    fi

    # du -sk gives size in 1024-byte blocks
    local size_kb
    size_kb=$(du -sk "$path" 2>/dev/null | cut -f1)
    echo $((size_kb * 1024))
}

# Get item count in directory (immediate children)
get_item_count() {
    local path="$1"

    if [[ ! -d "$path" ]]; then
        echo "0"
        return
    fi

    # Count non-hidden items
    find "$path" -maxdepth 1 -mindepth 1 ! -name ".*" 2>/dev/null | wc -l | tr -d ' '
}

# Get total disk space
get_disk_total() {
    df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $2 * 1024}'
}

# Get used disk space
get_disk_used() {
    df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $3 * 1024}'
}

# Get available disk space
get_disk_available() {
    df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4 * 1024}'
}

# Scan derived data directory
# Output format: project_name|size_bytes|path|age_days
scan_derived_data() {
    local filter_project="${1:-}"
    local older_than="${2:-0}"

    if [[ ! -d "$DERIVED_DATA_PATH" ]]; then
        return
    fi

    local dir
    for dir in "$DERIVED_DATA_PATH"/*/; do
        [[ -d "$dir" ]] || continue

        local name
        name=$(basename "$dir")

        # Skip hidden directories
        [[ "${name:0:1}" == "." ]] && continue

        # Skip ModuleCache and other special directories
        [[ "$name" == "ModuleCache.noindex" ]] && continue

        local project_name
        project_name=$(parse_project_name "$name")

        # Filter by project name if specified
        if [[ -n "$filter_project" ]] && [[ "$project_name" != *"$filter_project"* ]]; then
            continue
        fi

        local size_bytes
        size_bytes=$(get_dir_size_bytes "$dir")

        local age_days
        age_days=$(get_age_days "$dir")

        # Filter by age if specified
        if [[ "$older_than" -gt 0 ]] && [[ "$age_days" -lt "$older_than" ]]; then
            continue
        fi

        echo "${project_name}|${size_bytes}|${dir%/}|${age_days}"
    done
}

# Scan archives directory
# Output format: project_name|size_bytes|path|age_days|date
scan_archives() {
    local filter_project="${1:-}"
    local older_than="${2:-0}"

    if [[ ! -d "$ARCHIVES_PATH" ]]; then
        return
    fi

    # Archives are organized by date: Archives/YYYY-MM-DD/*.xcarchive
    local date_dir
    for date_dir in "$ARCHIVES_PATH"/*/; do
        [[ -d "$date_dir" ]] || continue

        local archive
        for archive in "$date_dir"/*.xcarchive; do
            [[ -d "$archive" ]] || continue

            local name
            name=$(basename "$archive" .xcarchive)

            # Extract project name (format: "ProjectName DATE, TIME")
            local project_name
            project_name=$(echo "$name" | sed 's/ [0-9].*$//')

            # Filter by project name if specified
            if [[ -n "$filter_project" ]] && [[ "$project_name" != *"$filter_project"* ]]; then
                continue
            fi

            local size_bytes
            size_bytes=$(get_dir_size_bytes "$archive")

            local age_days
            age_days=$(get_age_days "$archive")

            # Filter by age if specified
            if [[ "$older_than" -gt 0 ]] && [[ "$age_days" -lt "$older_than" ]]; then
                continue
            fi

            local archive_date
            archive_date=$(basename "$date_dir")

            echo "${project_name}|${size_bytes}|${archive}|${age_days}|${archive_date}"
        done
    done
}

# Scan device support directories
# Output format: platform|version|size_bytes|path|age_days
scan_device_support() {
    local platform_filter="${1:-}"
    local keep_latest="${2:-0}"

    local results=()

    for base_path in "${DEVICE_SUPPORT_PATHS[@]}"; do
        [[ -d "$base_path" ]] || continue

        local platform
        case "$base_path" in
            *"iOS DeviceSupport"*) platform="iOS" ;;
            *"watchOS DeviceSupport"*) platform="watchOS" ;;
            *"tvOS DeviceSupport"*) platform="tvOS" ;;
            *) platform="Unknown" ;;
        esac

        # Filter by platform if specified
        if [[ -n "$platform_filter" ]] && [[ "$platform" != "$platform_filter" ]]; then
            continue
        fi

        local version_dir
        for version_dir in "$base_path"/*/; do
            [[ -d "$version_dir" ]] || continue

            local version
            version=$(basename "$version_dir")

            # Skip hidden directories
            [[ "${version:0:1}" == "." ]] && continue

            local size_bytes
            size_bytes=$(get_dir_size_bytes "$version_dir")

            local age_days
            age_days=$(get_age_days "$version_dir")

            results+=("${platform}|${version}|${size_bytes}|${version_dir%/}|${age_days}")
        done
    done

    # If no results, return early
    if [[ ${#results[@]} -eq 0 ]]; then
        return
    fi

    # If keep_latest is set, sort by version and exclude newest N
    if [[ "$keep_latest" -gt 0 ]]; then
        # Sort by version descending and skip first N
        printf '%s\n' "${results[@]}" | sort -t'|' -k2 -rV | tail -n +"$((keep_latest + 1))"
    else
        printf '%s\n' "${results[@]}"
    fi
}

# Scan simulators
# Output format: name|udid|state|os|size_bytes|path
scan_simulators() {
    local include_available="${1:-0}"

    if ! command -v xcrun >/dev/null 2>&1; then
        return
    fi

    # Get unavailable simulators
    local unavailable
    unavailable=$(xcrun simctl list devices unavailable -j 2>/dev/null)

    # Parse JSON and output
    if command -v python3 >/dev/null 2>&1; then
        echo "$unavailable" | python3 -c "
import sys
import json
import os

data = json.load(sys.stdin)
devices = data.get('devices', {})

sim_path = os.path.expanduser('~/Library/Developer/CoreSimulator/Devices')

for runtime, device_list in devices.items():
    os_name = runtime.replace('com.apple.CoreSimulator.SimRuntime.', '').replace('-', ' ').replace('.', ' ')
    for device in device_list:
        name = device.get('name', 'Unknown')
        udid = device.get('udid', '')
        state = device.get('state', 'Unknown')
        is_available = device.get('isAvailable', True)

        if not is_available or '$include_available' == '1':
            device_path = os.path.join(sim_path, udid)
            # Size will be calculated later
            print(f\"{name}|{udid}|{state}|{os_name}|0|{device_path}\")
" 2>/dev/null
    fi
}

# Get total size for a category
get_category_size() {
    local category="$1"

    case "$category" in
        derived)
            get_dir_size_bytes "$DERIVED_DATA_PATH"
            ;;
        archives)
            get_dir_size_bytes "$ARCHIVES_PATH"
            ;;
        device-support)
            local total=0
            for path in "${DEVICE_SUPPORT_PATHS[@]}"; do
                if [[ -d "$path" ]]; then
                    total=$((total + $(get_dir_size_bytes "$path")))
                fi
            done
            echo "$total"
            ;;
        simulators)
            get_dir_size_bytes "$SIMULATORS_PATH"
            ;;
        caches)
            local total=0
            for path in "${CACHE_PATHS[@]}"; do
                if [[ -d "$path" ]]; then
                    total=$((total + $(get_dir_size_bytes "$path")))
                fi
            done
            echo "$total"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get item count for a category
get_category_count() {
    local category="$1"

    case "$category" in
        derived)
            local count
            count=$(get_item_count "$DERIVED_DATA_PATH")
            # Subtract 1 for ModuleCache.noindex if it exists
            if [[ -d "$DERIVED_DATA_PATH/ModuleCache.noindex" ]]; then
                count=$((count - 1))
            fi
            echo "$count"
            ;;
        archives)
            # Count .xcarchive bundles
            find "$ARCHIVES_PATH" -name "*.xcarchive" -type d 2>/dev/null | wc -l | tr -d ' '
            ;;
        device-support)
            local total=0
            for path in "${DEVICE_SUPPORT_PATHS[@]}"; do
                if [[ -d "$path" ]]; then
                    total=$((total + $(get_item_count "$path")))
                fi
            done
            echo "$total"
            ;;
        simulators)
            local sim_count
            sim_count=$(xcrun simctl list devices unavailable 2>/dev/null | grep -c "unavailable" 2>/dev/null) || sim_count=0
            echo "$sim_count"
            ;;
        caches)
            echo "-"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Scan all categories and output summary
scan_all() {
    local categories=(derived archives device-support simulators caches)
    local total_size=0

    for category in "${categories[@]}"; do
        local size
        size=$(get_category_size "$category")
        total_size=$((total_size + size))

        local count
        count=$(get_category_count "$category")

        local name
        case "$category" in
            derived) name="Derived Data" ;;
            archives) name="Archives" ;;
            device-support) name="Device Support" ;;
            simulators) name="Simulators" ;;
            caches) name="Caches" ;;
        esac

        echo "${category}|${name}|${size}|${count}"
    done

    echo "total|Total Cleanable|${total_size}|-"
}
