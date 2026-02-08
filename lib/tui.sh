#!/bin/bash
# tui.sh - Terminal UI components (Bash 3.2 compatible)

# Box drawing characters (set by setup_chars)
BOX_TL=""
BOX_TR=""
BOX_BL=""
BOX_BR=""
BOX_H=""
BOX_V=""
CHECK_ON=""
CHECK_OFF=""
ARROW=""
BULLET=""
PROGRESS_FULL=""
PROGRESS_EMPTY=""

# Clear to end of line sequence
CLEAR_EOL=$'\033[K'

# Setup characters based on terminal capabilities
setup_chars() {
    # Check if terminal supports UTF-8
    if [[ "${LANG:-}" == *"UTF-8"* ]] || [[ "${LC_ALL:-}" == *"UTF-8"* ]]; then
        BOX_TL="┌"
        BOX_TR="┐"
        BOX_BL="└"
        BOX_BR="┘"
        BOX_H="─"
        BOX_V="│"
        CHECK_ON="☑"
        CHECK_OFF="☐"
        ARROW="→"
        BULLET="•"
        PROGRESS_FULL="█"
        PROGRESS_EMPTY="░"
    else
        # ASCII fallback
        BOX_TL="+"
        BOX_TR="+"
        BOX_BL="+"
        BOX_BR="+"
        BOX_H="-"
        BOX_V="|"
        CHECK_ON="[x]"
        CHECK_OFF="[ ]"
        ARROW="->"
        BULLET="*"
        PROGRESS_FULL="#"
        PROGRESS_EMPTY="."
    fi
}

# Get terminal size
get_term_size() {
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
}

# Clear screen
clear_screen() {
    printf '\033[2J\033[H'
}

# Move cursor to position
move_cursor() {
    local row=$1
    local col=$2
    printf '\033[%d;%dH' "$row" "$col"
}

# Hide cursor
hide_cursor() {
    printf '\033[?25l'
}

# Show cursor
show_cursor() {
    printf '\033[?25h'
}

# Draw horizontal line
draw_hline() {
    local width=$1
    local char="${2:-$BOX_H}"
    local i
    for ((i=0; i<width; i++)); do
        printf '%s' "$char"
    done
}

# Draw a box around text
draw_box() {
    local text="$1"
    local width="${2:-$((${#text} + 4))}"

    echo "${BOX_TL}$(draw_hline $((width - 2)))${BOX_TR}"
    printf "${BOX_V}%*s${BOX_V}\n" "$((width - 2))" "$text"
    echo "${BOX_BL}$(draw_hline $((width - 2)))${BOX_BR}"
}

# Draw progress bar
draw_progress_bar() {
    local current=$1
    local total=$2
    local width="${3:-40}"
    local percentage
    local i

    if [[ "$total" -eq 0 ]]; then
        percentage=0
    else
        percentage=$((current * 100 / total))
    fi

    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf ' '
    for ((i=0; i<filled; i++)); do printf '%s' "$PROGRESS_FULL"; done
    for ((i=0; i<empty; i++)); do printf '%s' "$PROGRESS_EMPTY"; done
    printf ' %3d%%' "$percentage"
}

# Draw storage bar with colors
draw_storage_bar() {
    local used=$1
    local total=$2
    local width="${3:-50}"
    local i

    local percentage
    if [[ "$total" -eq 0 ]]; then
        percentage=0
    else
        percentage=$((used * 100 / total))
    fi

    local filled=$((width * used / total))
    local empty=$((width - filled))

    # Color based on usage
    local color
    if [[ "$percentage" -ge 90 ]]; then
        color="$RED"
    elif [[ "$percentage" -ge 70 ]]; then
        color="$YELLOW"
    else
        color="$GREEN"
    fi

    printf ' %s' "$color"
    for ((i=0; i<filled; i++)); do printf '%s' "$PROGRESS_FULL"; done
    printf '%s' "$RESET"
    for ((i=0; i<empty; i++)); do printf '%s' "$PROGRESS_EMPTY"; done
    printf '%s' "${CLEAR_EOL}"
}

# Read a single keypress
read_key() {
    local key char2 char3
    IFS= read -rsn1 key 2>/dev/null

    # Handle escape sequences (arrow keys)
    if [[ "$key" == $'\x1b' ]]; then
        # Read the next character with a short timeout (bytes are already in buffer)
        IFS= read -rsn1 -t 0.01 char2 2>/dev/null
        # If no additional char read, it's plain escape
        if [[ -z "$char2" ]]; then
            echo "escape"
            return
        fi
        # If it's '[', read one more for arrow keys
        if [[ "$char2" == "[" ]]; then
            IFS= read -rsn1 -t 0.01 char3 2>/dev/null
            case "$char3" in
                A) echo "up"; return ;;
                B) echo "down"; return ;;
                C) echo "right"; return ;;
                D) echo "left"; return ;;
            esac
        fi
        # Unknown escape sequence
        echo "escape"
        return
    fi

    case "$key" in
        $'\x0a'|$'\x0d') echo "enter" ;;
        ' ') echo "space" ;;
        q|Q) echo "quit" ;;
        a|A) echo "all" ;;
        c|C) echo "clean" ;;
        r|R) echo "refresh" ;;
        d|D) echo "delete" ;;
        j|J) echo "down" ;;
        k|K) echo "up" ;;
        h|H) echo "left" ;;
        l|L) echo "right" ;;
        [1-9]) echo "$key" ;;
        *) echo "$key" ;;
    esac
}

# Spinner animation
spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local chars='|/-\'
    local i=0

    hide_cursor

    while kill -0 "$pid" 2>/dev/null; do
        local c="${chars:i%4:1}"
        printf '\r%s %s' "$c" "$message"
        i=$((i + 1))
        sleep 0.1
    done

    printf '\r%*s\r' "$((${#message} + 2))" ''
    show_cursor
}

# Cache disk stats (only call on startup and refresh)
tui_cache_disk_stats() {
    TUI_CACHED_DISK_TOTAL=$(get_disk_total)
    TUI_CACHED_DISK_USED=$(get_disk_used)
    TUI_CACHED_DISK_AVAILABLE=$(get_disk_available)
}

# Draw the main TUI header
draw_header() {
    local width="${1:-60}"

    printf '%s\n' "${CLEAR_EOL}"
    printf '%s%s%s%s%s%s\n' "${BOLD}" "${BOX_TL}" "$(draw_hline $((width - 2)))" "${BOX_TR}" "${RESET}" "${CLEAR_EOL}"
    printf "${BOLD}${BOX_V}%*s${BOX_V}${RESET}%s\n" "$((width - 2))" "xcclean v${XCCLEAN_VERSION}" "${CLEAR_EOL}"
    printf '%s%s%s%s%s%s\n' "${BOLD}" "${BOX_BL}" "$(draw_hline $((width - 2)))" "${BOX_BR}" "${RESET}" "${CLEAR_EOL}"
    printf '%s\n' "${CLEAR_EOL}"
}

# Draw storage overview (uses cached disk stats)
draw_storage_overview() {
    local total=$TUI_CACHED_DISK_TOTAL
    local used=$TUI_CACHED_DISK_USED

    local percentage=$((used * 100 / total))

    printf " ${BOLD}Mac Storage:${RESET} $(format_size "$used") / $(format_size "$total") (%d%%)%s\n" "$percentage" "${CLEAR_EOL}"
    draw_storage_bar "$used" "$total" 50
    printf '\n%s\n%s\n' "${CLEAR_EOL}" "${CLEAR_EOL}"
}

# Draw footer with controls
draw_footer() {
    printf '%s\n' "${CLEAR_EOL}"
    if [[ -n "$TUI_EXPANDED_CAT" ]]; then
        # Item view controls
        printf " ${DIM}[↑↓/jk]${RESET} Navigate  ${DIM}[space]${RESET} Toggle  ${DIM}[a]${RESET} All  ${DIM}[d]${RESET} Delete  ${DIM}[←/esc]${RESET} Back  ${DIM}[q]${RESET} Quit%s\n" "${CLEAR_EOL}"
    else
        # Category view controls
        printf " ${DIM}[↑↓/jk]${RESET} Navigate  ${DIM}[space]${RESET} Toggle  ${DIM}[→/enter]${RESET} Expand  ${DIM}[a]${RESET} All  ${DIM}[c]${RESET} Clean  ${DIM}[q]${RESET} Quit%s\n" "${CLEAR_EOL}"
    fi
}

# Confirmation dialog
confirm_dialog() {
    local message="$1"
    local size="$2"

    echo ""
    echo "${YELLOW}${BOLD}Confirm Deletion${RESET}"
    echo "$message"
    echo ""
    printf "This will free ${GREEN}%s${RESET}. Continue? [y/N] " "$size"

    local response
    read -r response

    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Category data storage (Bash 3.2 compatible - using arrays instead of associative arrays)
TUI_CAT_KEYS=()
TUI_CAT_NAMES=()
TUI_CAT_SIZES=()
TUI_CAT_COUNTS=()
TUI_CAT_SELECTED=()

# Expanded state and item navigation
TUI_EXPANDED_CAT=""      # Currently expanded category key (empty = none)
TUI_CAT_CURSOR=0         # Cursor position in category list
TUI_ITEM_CURSOR=0        # Cursor position within items
TUI_SCROLL_OFFSET=0      # Scroll offset for long lists
TUI_MAX_VISIBLE_ITEMS=8  # Max items to show before scrolling

# Cached disk stats (refreshed only on startup and 'r' key)
TUI_CACHED_DISK_TOTAL=0
TUI_CACHED_DISK_USED=0
TUI_CACHED_DISK_AVAILABLE=0

# Item storage arrays (display_name|size_bytes|path format)
TUI_ITEMS_DERIVED=()
TUI_ITEMS_DERIVED_SELECTED=()
TUI_ITEMS_ARCHIVES=()
TUI_ITEMS_ARCHIVES_SELECTED=()
TUI_ITEMS_DEVICE_SUPPORT=()
TUI_ITEMS_DEVICE_SUPPORT_SELECTED=()

# Clear category data
tui_clear_categories() {
    TUI_CAT_KEYS=()
    TUI_CAT_NAMES=()
    TUI_CAT_SIZES=()
    TUI_CAT_COUNTS=()
    TUI_CAT_SELECTED=()
    # Clear item arrays
    TUI_ITEMS_DERIVED=()
    TUI_ITEMS_DERIVED_SELECTED=()
    TUI_ITEMS_ARCHIVES=()
    TUI_ITEMS_ARCHIVES_SELECTED=()
    TUI_ITEMS_DEVICE_SUPPORT=()
    TUI_ITEMS_DEVICE_SUPPORT_SELECTED=()
    # Reset navigation
    TUI_EXPANDED_CAT=""
    TUI_CAT_CURSOR=0
    TUI_ITEM_CURSOR=0
    TUI_SCROLL_OFFSET=0
}

# Add category data
tui_add_category() {
    local key="$1"
    local name="$2"
    local size="$3"
    local count="$4"

    TUI_CAT_KEYS+=("$key")
    TUI_CAT_NAMES+=("$name")
    TUI_CAT_SIZES+=("$size")
    TUI_CAT_COUNTS+=("$count")
    TUI_CAT_SELECTED+=(0)
}

# Get category index by key
tui_get_category_index() {
    local key="$1"
    local i
    for ((i=0; i<${#TUI_CAT_KEYS[@]}; i++)); do
        if [[ "${TUI_CAT_KEYS[$i]}" == "$key" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo "-1"
    return 1
}

# Toggle category selection
tui_toggle_category() {
    local idx="$1"
    if [[ "${TUI_CAT_SELECTED[$idx]}" == "1" ]]; then
        TUI_CAT_SELECTED[$idx]=0
    else
        TUI_CAT_SELECTED[$idx]=1
    fi
}

# Check if category is expandable (has individual items to show)
tui_is_expandable() {
    local key="$1"
    case "$key" in
        derived|archives|device-support) return 0 ;;
        *) return 1 ;;
    esac
}

# Load items for derived data category
tui_load_derived_items() {
    TUI_ITEMS_DERIVED=()
    TUI_ITEMS_DERIVED_SELECTED=()

    while IFS='|' read -r project_name size_bytes path age_days; do
        [[ -z "$path" ]] && continue
        TUI_ITEMS_DERIVED+=("${project_name}|${size_bytes}|${path}")
        TUI_ITEMS_DERIVED_SELECTED+=(0)
    done < <(scan_derived_data)
}

# Load items for archives category
tui_load_archives_items() {
    TUI_ITEMS_ARCHIVES=()
    TUI_ITEMS_ARCHIVES_SELECTED=()

    while IFS='|' read -r project_name size_bytes path age_days archive_date; do
        [[ -z "$path" ]] && continue
        local display_name="${project_name} (${archive_date})"
        TUI_ITEMS_ARCHIVES+=("${display_name}|${size_bytes}|${path}")
        TUI_ITEMS_ARCHIVES_SELECTED+=(0)
    done < <(scan_archives)
}

# Load items for device support category
tui_load_device_support_items() {
    TUI_ITEMS_DEVICE_SUPPORT=()
    TUI_ITEMS_DEVICE_SUPPORT_SELECTED=()

    while IFS='|' read -r platform version size_bytes path age_days; do
        [[ -z "$path" ]] && continue
        local display_name="${platform} ${version}"
        TUI_ITEMS_DEVICE_SUPPORT+=("${display_name}|${size_bytes}|${path}")
        TUI_ITEMS_DEVICE_SUPPORT_SELECTED+=(0)
    done < <(scan_device_support)
}

# Load items for a category
tui_load_category_items() {
    local key="$1"
    case "$key" in
        derived) tui_load_derived_items ;;
        archives) tui_load_archives_items ;;
        device-support) tui_load_device_support_items ;;
    esac
}

# Get items array for category
tui_get_items_array() {
    local key="$1"
    case "$key" in
        derived) echo "TUI_ITEMS_DERIVED" ;;
        archives) echo "TUI_ITEMS_ARCHIVES" ;;
        device-support) echo "TUI_ITEMS_DEVICE_SUPPORT" ;;
    esac
}

# Get item count for expanded category
tui_get_item_count() {
    local key="$1"
    case "$key" in
        derived) echo "${#TUI_ITEMS_DERIVED[@]}" ;;
        archives) echo "${#TUI_ITEMS_ARCHIVES[@]}" ;;
        device-support) echo "${#TUI_ITEMS_DEVICE_SUPPORT[@]}" ;;
        *) echo "0" ;;
    esac
}

# Toggle expand/collapse for a category
tui_toggle_expand() {
    local key="$1"

    if [[ "$TUI_EXPANDED_CAT" == "$key" ]]; then
        # Collapse
        TUI_EXPANDED_CAT=""
        TUI_ITEM_CURSOR=0
        TUI_SCROLL_OFFSET=0
    else
        # Expand - load items first
        tui_load_category_items "$key"
        TUI_EXPANDED_CAT="$key"
        TUI_ITEM_CURSOR=0
        TUI_SCROLL_OFFSET=0
    fi
}

# Toggle individual item selection
tui_toggle_item() {
    local idx="$1"
    case "$TUI_EXPANDED_CAT" in
        derived)
            if [[ "${TUI_ITEMS_DERIVED_SELECTED[$idx]}" == "1" ]]; then
                TUI_ITEMS_DERIVED_SELECTED[$idx]=0
            else
                TUI_ITEMS_DERIVED_SELECTED[$idx]=1
            fi
            ;;
        archives)
            if [[ "${TUI_ITEMS_ARCHIVES_SELECTED[$idx]}" == "1" ]]; then
                TUI_ITEMS_ARCHIVES_SELECTED[$idx]=0
            else
                TUI_ITEMS_ARCHIVES_SELECTED[$idx]=1
            fi
            ;;
        device-support)
            if [[ "${TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$idx]}" == "1" ]]; then
                TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$idx]=0
            else
                TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$idx]=1
            fi
            ;;
    esac
}

# Toggle all items in expanded category
tui_toggle_all_items() {
    local count
    local all_selected=1
    local i

    case "$TUI_EXPANDED_CAT" in
        derived)
            count=${#TUI_ITEMS_DERIVED_SELECTED[@]}
            for ((i=0; i<count; i++)); do
                if [[ "${TUI_ITEMS_DERIVED_SELECTED[$i]}" == "0" ]]; then
                    all_selected=0
                    break
                fi
            done
            for ((i=0; i<count; i++)); do
                if [[ "$all_selected" == "1" ]]; then
                    TUI_ITEMS_DERIVED_SELECTED[$i]=0
                else
                    TUI_ITEMS_DERIVED_SELECTED[$i]=1
                fi
            done
            ;;
        archives)
            count=${#TUI_ITEMS_ARCHIVES_SELECTED[@]}
            for ((i=0; i<count; i++)); do
                if [[ "${TUI_ITEMS_ARCHIVES_SELECTED[$i]}" == "0" ]]; then
                    all_selected=0
                    break
                fi
            done
            for ((i=0; i<count; i++)); do
                if [[ "$all_selected" == "1" ]]; then
                    TUI_ITEMS_ARCHIVES_SELECTED[$i]=0
                else
                    TUI_ITEMS_ARCHIVES_SELECTED[$i]=1
                fi
            done
            ;;
        device-support)
            count=${#TUI_ITEMS_DEVICE_SUPPORT_SELECTED[@]}
            for ((i=0; i<count; i++)); do
                if [[ "${TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$i]}" == "0" ]]; then
                    all_selected=0
                    break
                fi
            done
            for ((i=0; i<count; i++)); do
                if [[ "$all_selected" == "1" ]]; then
                    TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$i]=0
                else
                    TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$i]=1
                fi
            done
            ;;
    esac
}

# Count selected items in expanded category
tui_count_selected_items() {
    local count=0
    local i

    case "$TUI_EXPANDED_CAT" in
        derived)
            for ((i=0; i<${#TUI_ITEMS_DERIVED_SELECTED[@]}; i++)); do
                [[ "${TUI_ITEMS_DERIVED_SELECTED[$i]}" == "1" ]] && ((count++))
            done
            ;;
        archives)
            for ((i=0; i<${#TUI_ITEMS_ARCHIVES_SELECTED[@]}; i++)); do
                [[ "${TUI_ITEMS_ARCHIVES_SELECTED[$i]}" == "1" ]] && ((count++))
            done
            ;;
        device-support)
            for ((i=0; i<${#TUI_ITEMS_DEVICE_SUPPORT_SELECTED[@]}; i++)); do
                [[ "${TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$i]}" == "1" ]] && ((count++))
            done
            ;;
    esac
    echo "$count"
}

# Get total size of selected items
tui_get_selected_size() {
    local total=0
    local i item size_bytes

    case "$TUI_EXPANDED_CAT" in
        derived)
            for ((i=0; i<${#TUI_ITEMS_DERIVED[@]}; i++)); do
                if [[ "${TUI_ITEMS_DERIVED_SELECTED[$i]}" == "1" ]]; then
                    item="${TUI_ITEMS_DERIVED[$i]}"
                    size_bytes=$(echo "$item" | cut -d'|' -f2)
                    total=$((total + size_bytes))
                fi
            done
            ;;
        archives)
            for ((i=0; i<${#TUI_ITEMS_ARCHIVES[@]}; i++)); do
                if [[ "${TUI_ITEMS_ARCHIVES_SELECTED[$i]}" == "1" ]]; then
                    item="${TUI_ITEMS_ARCHIVES[$i]}"
                    size_bytes=$(echo "$item" | cut -d'|' -f2)
                    total=$((total + size_bytes))
                fi
            done
            ;;
        device-support)
            for ((i=0; i<${#TUI_ITEMS_DEVICE_SUPPORT[@]}; i++)); do
                if [[ "${TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$i]}" == "1" ]]; then
                    item="${TUI_ITEMS_DEVICE_SUPPORT[$i]}"
                    size_bytes=$(echo "$item" | cut -d'|' -f2)
                    total=$((total + size_bytes))
                fi
            done
            ;;
    esac
    echo "$total"
}

# Get selected items as newline-separated paths
tui_get_selected_paths() {
    local i item path

    case "$TUI_EXPANDED_CAT" in
        derived)
            for ((i=0; i<${#TUI_ITEMS_DERIVED[@]}; i++)); do
                if [[ "${TUI_ITEMS_DERIVED_SELECTED[$i]}" == "1" ]]; then
                    item="${TUI_ITEMS_DERIVED[$i]}"
                    path=$(echo "$item" | cut -d'|' -f3)
                    echo "$path"
                fi
            done
            ;;
        archives)
            for ((i=0; i<${#TUI_ITEMS_ARCHIVES[@]}; i++)); do
                if [[ "${TUI_ITEMS_ARCHIVES_SELECTED[$i]}" == "1" ]]; then
                    item="${TUI_ITEMS_ARCHIVES[$i]}"
                    path=$(echo "$item" | cut -d'|' -f3)
                    echo "$path"
                fi
            done
            ;;
        device-support)
            for ((i=0; i<${#TUI_ITEMS_DEVICE_SUPPORT[@]}; i++)); do
                if [[ "${TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$i]}" == "1" ]]; then
                    item="${TUI_ITEMS_DEVICE_SUPPORT[$i]}"
                    path=$(echo "$item" | cut -d'|' -f3)
                    echo "$path"
                fi
            done
            ;;
    esac
}

# Draw expanded items for a category
draw_expanded_items() {
    local key="$1"
    local width="${2:-60}"
    local items_ref selected_ref item_count
    local i start end

    case "$key" in
        derived)
            item_count=${#TUI_ITEMS_DERIVED[@]}
            ;;
        archives)
            item_count=${#TUI_ITEMS_ARCHIVES[@]}
            ;;
        device-support)
            item_count=${#TUI_ITEMS_DEVICE_SUPPORT[@]}
            ;;
    esac

    if [[ "$item_count" -eq 0 ]]; then
        printf "     ${DIM}(no items)${RESET}%s\n" "${CLEAR_EOL}"
        return
    fi

    # Calculate visible range with scrolling
    local visible=$TUI_MAX_VISIBLE_ITEMS
    if [[ "$item_count" -le "$visible" ]]; then
        start=0
        end=$item_count
    else
        # Adjust scroll offset based on cursor
        if [[ "$TUI_ITEM_CURSOR" -lt "$TUI_SCROLL_OFFSET" ]]; then
            TUI_SCROLL_OFFSET=$TUI_ITEM_CURSOR
        elif [[ "$TUI_ITEM_CURSOR" -ge $((TUI_SCROLL_OFFSET + visible)) ]]; then
            TUI_SCROLL_OFFSET=$((TUI_ITEM_CURSOR - visible + 1))
        fi
        start=$TUI_SCROLL_OFFSET
        end=$((start + visible))
        if [[ "$end" -gt "$item_count" ]]; then
            end=$item_count
        fi
    fi

    # Show "N more above" indicator
    if [[ "$start" -gt 0 ]]; then
        printf "     ${DIM}... (%d more above)${RESET}%s\n" "$start" "${CLEAR_EOL}"
    fi

    # Draw items
    for ((i=start; i<end; i++)); do
        local item name size_bytes selected check cursor_mark

        case "$key" in
            derived)
                item="${TUI_ITEMS_DERIVED[$i]}"
                selected="${TUI_ITEMS_DERIVED_SELECTED[$i]}"
                ;;
            archives)
                item="${TUI_ITEMS_ARCHIVES[$i]}"
                selected="${TUI_ITEMS_ARCHIVES_SELECTED[$i]}"
                ;;
            device-support)
                item="${TUI_ITEMS_DEVICE_SUPPORT[$i]}"
                selected="${TUI_ITEMS_DEVICE_SUPPORT_SELECTED[$i]}"
                ;;
        esac

        name=$(echo "$item" | cut -d'|' -f1)
        size_bytes=$(echo "$item" | cut -d'|' -f2)

        # Truncate long names
        if [[ ${#name} -gt 28 ]]; then
            name="${name:0:25}..."
        fi

        if [[ "$selected" == "1" ]]; then
            check="${GREEN}${CHECK_ON}${RESET}"
        else
            check="${DIM}${CHECK_OFF}${RESET}"
        fi

        # Highlight current cursor position
        if [[ "$i" == "$TUI_ITEM_CURSOR" ]]; then
            printf " ${REVERSE}    %s %-28s %10s${RESET}%s\n" "$check" "$name" "$(format_size "$size_bytes")" "${CLEAR_EOL}"
        else
            printf "     %s %-28s %10s%s\n" "$check" "$name" "$(format_size "$size_bytes")" "${CLEAR_EOL}"
        fi
    done

    # Show "N more below" indicator
    local remaining=$((item_count - end))
    if [[ "$remaining" -gt 0 ]]; then
        printf "     ${DIM}... (%d more below)${RESET}%s\n" "$remaining" "${CLEAR_EOL}"
    fi

    # Show delete prompt if items are selected
    local selected_count
    selected_count=$(tui_count_selected_items)
    if [[ "$selected_count" -gt 0 ]]; then
        local selected_size
        selected_size=$(tui_get_selected_size)
        printf '%s\n' "${CLEAR_EOL}"
        printf "     ${YELLOW}[d]${RESET} Delete Selected (%d item%s, %s)%s\n" \
            "$selected_count" \
            "$( [[ "$selected_count" -ne 1 ]] && echo "s" )" \
            "$(format_size "$selected_size")" \
            "${CLEAR_EOL}"
    fi
}

# Draw category table with expandable support
draw_category_table_simple() {
    local width="${1:-60}"

    printf " ${BOLD}%-3s   %-26s %10s %8s %5s${RESET}%s\n" "#" "Category" "Size" "Items" "" "${CLEAR_EOL}"
    printf " %s%s\n" "$(draw_hline $((width - 2)))" "${CLEAR_EOL}"

    local i
    local total_size=0

    for ((i=0; i<${#TUI_CAT_KEYS[@]}; i++)); do
        local key="${TUI_CAT_KEYS[$i]}"
        local name="${TUI_CAT_NAMES[$i]}"
        local size="${TUI_CAT_SIZES[$i]}"
        local count="${TUI_CAT_COUNTS[$i]}"
        local selected="${TUI_CAT_SELECTED[$i]}"

        total_size=$((total_size + size))

        local check
        if [[ "$selected" == "1" ]]; then
            check="${GREEN}${CHECK_ON}${RESET}"
        else
            check="${DIM}${CHECK_OFF}${RESET}"
        fi

        # Show expand indicator for expandable categories
        local expand_indicator=" "
        if tui_is_expandable "$key"; then
            if [[ "$TUI_EXPANDED_CAT" == "$key" ]]; then
                expand_indicator="v"
            else
                expand_indicator=">"
            fi
        fi

        # Highlight current cursor position when not in expanded view
        if [[ -z "$TUI_EXPANDED_CAT" ]] && [[ "$i" == "$TUI_CAT_CURSOR" ]]; then
            printf " ${REVERSE}${CYAN}[%d]${RESET}${REVERSE} %s %-26s %10s %8s %s${RESET}%s\n" \
                "$((i + 1))" "$expand_indicator" "$name" "$(format_size "$size")" "$count" "$check" "${CLEAR_EOL}"
        else
            printf " ${CYAN}[%d]${RESET} %s %-26s %10s %8s %s%s\n" \
                "$((i + 1))" "$expand_indicator" "$name" "$(format_size "$size")" "$count" "$check" "${CLEAR_EOL}"
        fi

        # Draw expanded items if this category is expanded
        if [[ "$TUI_EXPANDED_CAT" == "$key" ]]; then
            draw_expanded_items "$key" "$width"
        fi
    done

    printf " %s%s\n" "$(draw_hline $((width - 2)))" "${CLEAR_EOL}"
    printf " ${BOLD}%-34s %10s${RESET}%s\n" "Total Cleanable:" "$(format_size "$total_size")" "${CLEAR_EOL}"
    printf '%s\n' "${CLEAR_EOL}"
}

# Refresh TUI data
tui_refresh_data() {
    tui_clear_categories

    local scan_output
    scan_output=$(scan_all)

    while IFS='|' read -r key name size count; do
        [[ "$key" == "total" ]] && continue
        [[ -z "$key" ]] && continue
        tui_add_category "$key" "$name" "$size" "$count"
    done <<< "$scan_output"
}

# Refresh with animated spinner
tui_refresh_with_spinner() {
    local message="${1:-Scanning...}"
    local tmpfile="/tmp/xcclean_scan_$$"

    # Run scan_all in background and save to temp file
    scan_all > "$tmpfile" &
    local pid=$!

    # Show spinner while running
    spinner "$pid" "$message"

    # Wait for completion
    wait "$pid"

    # Now parse the results in the foreground (so variables persist)
    tui_clear_categories
    while IFS='|' read -r key name size count; do
        [[ "$key" == "total" ]] && continue
        [[ -z "$key" ]] && continue
        tui_add_category "$key" "$name" "$size" "$count"
    done < "$tmpfile"

    # Cleanup
    rm -f "$tmpfile"
}

# Delete selected items in the expanded category
tui_delete_selected_items() {
    local count
    count=$(tui_count_selected_items)

    if [[ "$count" -eq 0 ]]; then
        echo ""
        echo "${YELLOW}No items selected. Use [space] to select items.${RESET}"
        sleep 1.5
        return
    fi

    local size
    size=$(tui_get_selected_size)

    if confirm_dialog "Delete $count selected item(s)?" "$(format_size "$size")"; then
        echo ""
        local deleted=0
        local deleted_size=0

        while IFS= read -r path; do
            [[ -z "$path" ]] && continue
            if safe_delete "$path"; then
                ((deleted++))
                log "  ${GREEN}✓${RESET} Deleted: $(basename "$path")"
            fi
        done < <(tui_get_selected_paths)

        log ""
        log "Deleted $deleted items, freed $(format_size "$size")"
        echo ""
        echo "Press any key to continue..."
        read -rsn1

        # Refresh data and reload items
        local expanded_cat="$TUI_EXPANDED_CAT"
        tui_refresh_data
        if [[ -n "$expanded_cat" ]]; then
            tui_load_category_items "$expanded_cat"
            TUI_EXPANDED_CAT="$expanded_cat"
            TUI_ITEM_CURSOR=0
            TUI_SCROLL_OFFSET=0
        fi
    fi
}

# Run the interactive TUI
run_tui() {
    setup_chars
    get_term_size

    # Cache disk stats once at startup
    tui_cache_disk_stats

    # Initial scan
    tui_refresh_with_spinner "Scanning..."

    # Clear screen once before entering the loop
    clear_screen

    # Main loop
    while true; do
        # Move cursor to home instead of clearing (prevents flicker)
        move_cursor 1 1
        draw_header 60
        draw_storage_overview
        draw_category_table_simple 60
        draw_footer

        local key
        key=$(read_key)

        # Handle keys differently based on whether we're in expanded view
        if [[ -n "$TUI_EXPANDED_CAT" ]]; then
            # Expanded item view
            local item_count
            item_count=$(tui_get_item_count "$TUI_EXPANDED_CAT")

            case "$key" in
                quit)
                    clear_screen
                    show_cursor
                    exit 0
                    ;;
                escape|left)
                    # Collapse back to category view
                    TUI_EXPANDED_CAT=""
                    TUI_ITEM_CURSOR=0
                    TUI_SCROLL_OFFSET=0
                    ;;
                up)
                    # Navigate up in items
                    if [[ "$TUI_ITEM_CURSOR" -gt 0 ]]; then
                        ((TUI_ITEM_CURSOR--))
                    fi
                    ;;
                down)
                    # Navigate down in items
                    if [[ "$TUI_ITEM_CURSOR" -lt $((item_count - 1)) ]]; then
                        ((TUI_ITEM_CURSOR++))
                    fi
                    ;;
                space)
                    # Toggle current item
                    tui_toggle_item "$TUI_ITEM_CURSOR"
                    ;;
                all)
                    # Toggle all items
                    tui_toggle_all_items
                    ;;
                delete)
                    # Delete selected items
                    tui_delete_selected_items
                    tui_cache_disk_stats
                    clear_screen
                    ;;
                refresh)
                    local expanded_cat="$TUI_EXPANDED_CAT"
                    tui_cache_disk_stats
                    tui_refresh_with_spinner "Refreshing..."
                    if [[ -n "$expanded_cat" ]]; then
                        tui_load_category_items "$expanded_cat"
                        TUI_EXPANDED_CAT="$expanded_cat"
                        TUI_ITEM_CURSOR=0
                        TUI_SCROLL_OFFSET=0
                    fi
                    clear_screen
                    ;;
            esac
        else
            # Category view
            local cat_count=${#TUI_CAT_KEYS[@]}

            case "$key" in
                quit)
                    clear_screen
                    show_cursor
                    exit 0
                    ;;
                up)
                    # Navigate up in categories
                    if [[ "$TUI_CAT_CURSOR" -gt 0 ]]; then
                        ((TUI_CAT_CURSOR--))
                    fi
                    ;;
                down)
                    # Navigate down in categories
                    if [[ "$TUI_CAT_CURSOR" -lt $((cat_count - 1)) ]]; then
                        ((TUI_CAT_CURSOR++))
                    fi
                    ;;
                refresh)
                    tui_cache_disk_stats
                    tui_refresh_with_spinner "Refreshing..."
                    clear_screen
                    ;;
                enter|right)
                    # Expand the currently highlighted category if expandable
                    local cat_key="${TUI_CAT_KEYS[$TUI_CAT_CURSOR]}"
                    if tui_is_expandable "$cat_key"; then
                        tui_toggle_expand "$cat_key"
                    fi
                    ;;
                space)
                    # Toggle selection of current category
                    tui_toggle_category "$TUI_CAT_CURSOR"
                    ;;
                all)
                    # Toggle all categories
                    local all_selected=1
                    local i
                    for ((i=0; i<${#TUI_CAT_SELECTED[@]}; i++)); do
                        if [[ "${TUI_CAT_SELECTED[$i]}" == "0" ]]; then
                            all_selected=0
                            break
                        fi
                    done

                    if [[ "$all_selected" == "1" ]]; then
                        for ((i=0; i<${#TUI_CAT_SELECTED[@]}; i++)); do
                            TUI_CAT_SELECTED[$i]=0
                        done
                    else
                        for ((i=0; i<${#TUI_CAT_SELECTED[@]}; i++)); do
                            TUI_CAT_SELECTED[$i]=1
                        done
                    fi
                    ;;
                clean)
                    # Calculate selected size
                    local total_selected=0
                    local selected_cats=()
                    local i
                    for ((i=0; i<${#TUI_CAT_KEYS[@]}; i++)); do
                        if [[ "${TUI_CAT_SELECTED[$i]}" == "1" ]]; then
                            total_selected=$((total_selected + TUI_CAT_SIZES[$i]))
                            selected_cats+=("${TUI_CAT_KEYS[$i]}")
                        fi
                    done

                    if [[ "${#selected_cats[@]}" -eq 0 ]]; then
                        echo ""
                        echo "${YELLOW}No categories selected. Use [space] or [a] to select.${RESET}"
                        sleep 1.5
                        clear_screen
                        continue
                    fi

                    if confirm_dialog "Delete ${#selected_cats[@]} selected categories?" "$(format_size "$total_selected")"; then
                        echo ""
                        for cat in "${selected_cats[@]}"; do
                            case "$cat" in
                                derived) clean_derived_data ;;
                                archives) clean_archives ;;
                                device-support) clean_device_support ;;
                                simulators) clean_simulators ;;
                                caches) clean_caches ;;
                            esac
                        done
                        # Reset selections
                        for ((i=0; i<${#TUI_CAT_SELECTED[@]}; i++)); do
                            TUI_CAT_SELECTED[$i]=0
                        done
                        echo ""
                        echo "Press any key to continue..."
                        read -rsn1
                        tui_cache_disk_stats
                        tui_refresh_data
                    fi
                    clear_screen
                    ;;
                [1-5])
                    # Toggle specific category selection and move cursor there
                    local idx=$((key - 1))
                    if [[ $idx -lt ${#TUI_CAT_KEYS[@]} ]]; then
                        TUI_CAT_CURSOR=$idx
                        tui_toggle_category "$idx"
                    fi
                    ;;
            esac
        fi
    done
}

# Initialize
setup_chars
