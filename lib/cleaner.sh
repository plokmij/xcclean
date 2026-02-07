#!/bin/bash
# cleaner.sh - Deletion logic with safety checks

# Safe delete with dry-run and trash support
safe_delete() {
    local path="$1"
    local dry_run="${XCCLEAN_DRY_RUN:-0}"
    local use_trash="${XCCLEAN_TRASH:-0}"

    # Validate path is safe
    if ! is_safe_path "$path"; then
        print_error "Refusing to delete unsafe path: $path"
        return 1
    fi

    # Check path exists
    if [[ ! -e "$path" ]]; then
        log_verbose "Path does not exist: $path"
        return 0
    fi

    if [[ "$dry_run" == "1" ]]; then
        log "${DIM}[dry-run]${RESET} Would delete: $path"
        return 0
    fi

    if [[ "$use_trash" == "1" ]]; then
        # Move to Trash using AppleScript
        if osascript -e "tell application \"Finder\" to delete POSIX file \"$path\"" >/dev/null 2>&1; then
            log_verbose "Moved to Trash: $path"
            return 0
        else
            print_error "Failed to move to Trash: $path"
            return 1
        fi
    else
        # Permanent delete
        if rm -rf "$path" 2>/dev/null; then
            log_verbose "Deleted: $path"
            return 0
        else
            print_error "Failed to delete: $path"
            return 1
        fi
    fi
}

# Warn if Xcode is running
check_xcode_running() {
    if is_xcode_running; then
        print_warning "Xcode is currently running. Some files may be in use."
        if [[ "${XCCLEAN_YES:-}" != "1" ]]; then
            if ! confirm "Continue anyway?"; then
                return 1
            fi
        fi
    fi
    return 0
}

# Clean derived data
clean_derived_data() {
    local filter_project="${1:-}"
    local older_than="${2:-0}"
    local deleted_count=0
    local deleted_size=0

    log "Cleaning Derived Data..."

    check_xcode_running || return 1

    while IFS='|' read -r project_name size_bytes path age_days; do
        [[ -z "$path" ]] && continue

        if safe_delete "$path"; then
            ((deleted_count++))
            deleted_size=$((deleted_size + size_bytes))
            log "  ${GREEN}✓${RESET} Deleted: $project_name ($(format_size "$size_bytes"))"
        fi
    done < <(scan_derived_data "$filter_project" "$older_than")

    log ""
    log "Deleted $deleted_count items, freed $(format_size "$deleted_size")"
}

# Clean archives
clean_archives() {
    local filter_project="${1:-}"
    local older_than="${2:-0}"
    local keep_latest="${3:-0}"
    local deleted_count=0
    local deleted_size=0

    log "Cleaning Archives..."

    # If keep_latest is set, we need to group by project
    # For simplicity, we just delete all matching archives when keep_latest=0
    # or use a simpler approach for keep_latest
    if [[ "$keep_latest" -gt 0 ]]; then
        # Get unique projects, then for each project sort archives and skip latest N
        local projects
        projects=$(scan_archives "$filter_project" "$older_than" | cut -d'|' -f1 | sort -u)

        while IFS= read -r project; do
            [[ -z "$project" ]] && continue

            # Get all archives for this project, sorted by date descending, skip first N
            scan_archives "$project" "$older_than" | sort -t'|' -k5 -r | tail -n +"$((keep_latest + 1))" | \
            while IFS='|' read -r proj size_bytes path age_days archive_date; do
                [[ -z "$path" ]] && continue

                if safe_delete "$path"; then
                    ((deleted_count++))
                    deleted_size=$((deleted_size + size_bytes))
                    log "  ${GREEN}✓${RESET} Deleted: $proj ($archive_date, $(format_size "$size_bytes"))"
                fi
            done
        done <<< "$projects"
    else
        # Delete all matching archives
        while IFS='|' read -r project_name size_bytes path age_days archive_date; do
            [[ -z "$path" ]] && continue

            if safe_delete "$path"; then
                ((deleted_count++))
                deleted_size=$((deleted_size + size_bytes))
                log "  ${GREEN}✓${RESET} Deleted: $project_name ($archive_date, $(format_size "$size_bytes"))"
            fi
        done < <(scan_archives "$filter_project" "$older_than")
    fi

    # Clean up empty date directories
    if [[ -d "$ARCHIVES_PATH" ]]; then
        find "$ARCHIVES_PATH" -type d -empty -delete 2>/dev/null
    fi

    log ""
    log "Deleted $deleted_count archives, freed $(format_size "$deleted_size")"
}

# Clean device support
clean_device_support() {
    local platform_filter="${1:-}"
    local keep_latest="${2:-0}"
    local deleted_count=0
    local deleted_size=0

    log "Cleaning Device Support..."

    while IFS='|' read -r platform version size_bytes path age_days; do
        [[ -z "$path" ]] && continue

        if safe_delete "$path"; then
            ((deleted_count++))
            deleted_size=$((deleted_size + size_bytes))
            log "  ${GREEN}✓${RESET} Deleted: $platform $version ($(format_size "$size_bytes"))"
        fi
    done < <(scan_device_support "$platform_filter" "$keep_latest")

    log ""
    log "Deleted $deleted_count versions, freed $(format_size "$deleted_size")"
}

# Clean simulators (unavailable only)
clean_simulators() {
    local deleted_count=0
    local deleted_size=0

    log "Cleaning unavailable Simulators..."

    if ! command -v xcrun >/dev/null 2>&1; then
        print_error "xcrun not found. Xcode Command Line Tools required."
        return 1
    fi

    # Get size before cleanup
    local size_before
    size_before=$(get_dir_size_bytes "$SIMULATORS_PATH")

    if [[ "${XCCLEAN_DRY_RUN:-0}" == "1" ]]; then
        log "${DIM}[dry-run]${RESET} Would run: xcrun simctl delete unavailable"
        # Count unavailable simulators
        deleted_count=$(xcrun simctl list devices unavailable 2>/dev/null | grep -c "(unavailable)" || echo "0")
    else
        # Delete unavailable simulators
        if xcrun simctl delete unavailable 2>/dev/null; then
            local size_after
            size_after=$(get_dir_size_bytes "$SIMULATORS_PATH")
            deleted_size=$((size_before - size_after))
            log "  ${GREEN}✓${RESET} Cleaned unavailable simulators"
        else
            print_warning "Some simulators could not be deleted"
        fi
    fi

    log ""
    log "Freed $(format_size "$deleted_size")"
}

# Clean caches
clean_caches() {
    local deleted_count=0
    local deleted_size=0

    log "Cleaning Caches..."

    for cache_path in "${CACHE_PATHS[@]}"; do
        if [[ -d "$cache_path" ]]; then
            local size
            size=$(get_dir_size_bytes "$cache_path")

            # For caches, we clean contents but keep the directory
            if [[ "${XCCLEAN_DRY_RUN:-0}" == "1" ]]; then
                log "${DIM}[dry-run]${RESET} Would clean: $cache_path ($(format_size "$size"))"
            else
                local cache_name
                cache_name=$(basename "$cache_path")

                if rm -rf "$cache_path"/* 2>/dev/null; then
                    ((deleted_count++))
                    deleted_size=$((deleted_size + size))
                    log "  ${GREEN}✓${RESET} Cleaned: $cache_name ($(format_size "$size"))"
                fi
            fi
        fi
    done

    log ""
    log "Freed $(format_size "$deleted_size")"
}

# Clean selected items (reads paths from stdin, one per line)
clean_selected_items() {
    local deleted_count=0
    local deleted_size=0

    while IFS= read -r path; do
        [[ -z "$path" ]] && continue

        local size
        size=$(get_dir_size_bytes "$path")

        if safe_delete "$path"; then
            ((deleted_count++))
            deleted_size=$((deleted_size + size))
            log "  ${GREEN}✓${RESET} Deleted: $(basename "$path") ($(format_size "$size"))"
        fi
    done

    log ""
    log "Deleted $deleted_count items, freed $(format_size "$deleted_size")"
}

# Clean all categories
clean_all() {
    local older_than="${1:-0}"
    local keep_latest="${2:-0}"

    log "${BOLD}Cleaning all Xcode data...${RESET}"
    log ""

    check_xcode_running || return 1

    # Clean derived data
    clean_derived_data "" "$older_than"
    log ""

    # Clean archives
    clean_archives "" "$older_than" "$keep_latest"
    log ""

    # Clean device support
    clean_device_support "" "$keep_latest"
    log ""

    # Clean simulators
    clean_simulators
    log ""

    # Clean caches
    clean_caches
    log ""

    log "${BOLD}${GREEN}Done!${RESET}"
}
