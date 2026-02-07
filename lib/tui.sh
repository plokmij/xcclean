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
}

# Read a single keypress
read_key() {
    local key key2
    IFS= read -rsn1 key 2>/dev/null

    # Handle escape sequences (arrow keys)
    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key2 2>/dev/null
        key="${key}${key2}"
    fi

    case "$key" in
        $'\x1b[A') echo "up" ;;
        $'\x1b[B') echo "down" ;;
        $'\x1b[C') echo "right" ;;
        $'\x1b[D') echo "left" ;;
        $'\x0a'|$'\x0d') echo "enter" ;;
        ' ') echo "space" ;;
        q|Q) echo "quit" ;;
        a|A) echo "all" ;;
        c|C) echo "clean" ;;
        r|R) echo "refresh" ;;
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

# Draw the main TUI header
draw_header() {
    local width="${1:-60}"

    echo ""
    echo "${BOLD}${BOX_TL}$(draw_hline $((width - 2)))${BOX_TR}${RESET}"
    printf "${BOLD}${BOX_V}%*s${BOX_V}${RESET}\n" "$((width - 2))" "xcclean v${XCCLEAN_VERSION}"
    echo "${BOLD}${BOX_BL}$(draw_hline $((width - 2)))${BOX_BR}${RESET}"
    echo ""
}

# Draw storage overview
draw_storage_overview() {
    local total used available

    total=$(get_disk_total)
    used=$(get_disk_used)
    available=$(get_disk_available)

    local percentage=$((used * 100 / total))

    printf " ${BOLD}Mac Storage:${RESET} $(format_size "$used") / $(format_size "$total") (%d%%)\n" "$percentage"
    draw_storage_bar "$used" "$total" 50
    echo ""
    echo ""
}

# Draw footer with controls
draw_footer() {
    echo ""
    printf " ${DIM}[1-5]${RESET} Toggle  ${DIM}[a]${RESET} All  ${DIM}[c]${RESET} Clean  ${DIM}[r]${RESET} Refresh  ${DIM}[q]${RESET} Quit"
    echo ""
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

# Clear category data
tui_clear_categories() {
    TUI_CAT_KEYS=()
    TUI_CAT_NAMES=()
    TUI_CAT_SIZES=()
    TUI_CAT_COUNTS=()
    TUI_CAT_SELECTED=()
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

# Draw category table
draw_category_table_simple() {
    local width="${1:-60}"

    printf " ${BOLD}%-3s %-28s %10s %8s %5s${RESET}\n" "#" "Category" "Size" "Items" ""
    printf " %s\n" "$(draw_hline $((width - 2)))"

    local i
    local total_size=0

    for ((i=0; i<${#TUI_CAT_KEYS[@]}; i++)); do
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

        printf " ${CYAN}[%d]${RESET} %-28s %10s %8s %s\n" \
            "$((i + 1))" "$name" "$(format_size "$size")" "$count" "$check"
    done

    printf " %s\n" "$(draw_hline $((width - 2)))"
    printf " ${BOLD}%-32s %10s${RESET}\n" "Total Cleanable:" "$(format_size "$total_size")"
    echo ""
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

# Run the interactive TUI
run_tui() {
    setup_chars
    get_term_size

    # Initial scan
    echo "Scanning..."
    tui_refresh_data

    # Main loop
    while true; do
        clear_screen
        draw_header 60
        draw_storage_overview
        draw_category_table_simple 60
        draw_footer

        local key
        key=$(read_key)

        case "$key" in
            quit)
                clear_screen
                show_cursor
                exit 0
                ;;
            refresh)
                echo ""
                echo "Refreshing..."
                tui_refresh_data
                ;;
            all)
                # Toggle all
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
                    echo "${YELLOW}No categories selected. Use [1-5] or [a] to select.${RESET}"
                    sleep 1.5
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
                    tui_refresh_data
                fi
                ;;
            [1-5])
                # Toggle specific category
                local idx=$((key - 1))
                if [[ $idx -lt ${#TUI_CAT_KEYS[@]} ]]; then
                    tui_toggle_category "$idx"
                fi
                ;;
        esac
    done
}

# Initialize
setup_chars
