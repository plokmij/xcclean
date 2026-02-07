#compdef xcclean

# zsh completion for xcclean

_xcclean_categories() {
    local categories=(
        'derived:Xcode DerivedData'
        'archives:Xcode Archives'
        'device-support:iOS/watchOS/tvOS Device Support'
        'simulators:Unavailable Simulator devices'
        'caches:Xcode and build caches'
        'all:All categories'
    )
    _describe -t categories 'category' categories
}

_xcclean_commands() {
    local commands=(
        'status:Show storage overview'
        'scan:Scan and show all cleanable paths'
        'clean:Clean specified category'
        'list:List items in category'
    )
    _describe -t commands 'command' commands
}

_xcclean() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        '(-h --help)'{-h,--help}'[Show help message]' \
        '--version[Show version]' \
        '(-n --dry-run)'{-n,--dry-run}'[Preview without deleting]' \
        '(-y --yes)'{-y,--yes}'[Skip confirmation prompts]' \
        '(-q --quiet)'{-q,--quiet}'[Minimal output]' \
        '(-v --verbose)'{-v,--verbose}'[Verbose output]' \
        '--no-color[Disable colored output]' \
        '--json[Output in JSON format]' \
        '--trash[Move to Trash instead of delete]' \
        '--older-than[Only items older than N days]:days:(7 14 30 60 90)' \
        '--keep-latest[Keep N most recent items]:count:(1 2 3 5)' \
        '--project[Filter by project name]:project:' \
        '1: :_xcclean_commands' \
        '2: :->category' \
        && return 0

    case "$state" in
        category)
            case "${line[1]}" in
                clean|list)
                    _xcclean_categories
                    ;;
            esac
            ;;
    esac
}

_xcclean "$@"
