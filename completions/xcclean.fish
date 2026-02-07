# fish completion for xcclean

# Disable file completions
complete -c xcclean -f

# Commands
complete -c xcclean -n "__fish_use_subcommand" -a "status" -d "Show storage overview"
complete -c xcclean -n "__fish_use_subcommand" -a "scan" -d "Scan and show all cleanable paths"
complete -c xcclean -n "__fish_use_subcommand" -a "clean" -d "Clean specified category"
complete -c xcclean -n "__fish_use_subcommand" -a "list" -d "List items in category"

# Categories for clean and list
complete -c xcclean -n "__fish_seen_subcommand_from clean list" -a "derived" -d "Xcode DerivedData"
complete -c xcclean -n "__fish_seen_subcommand_from clean list" -a "archives" -d "Xcode Archives"
complete -c xcclean -n "__fish_seen_subcommand_from clean list" -a "device-support" -d "iOS/watchOS/tvOS Device Support"
complete -c xcclean -n "__fish_seen_subcommand_from clean list" -a "simulators" -d "Unavailable Simulator devices"
complete -c xcclean -n "__fish_seen_subcommand_from clean list" -a "caches" -d "Xcode and build caches"
complete -c xcclean -n "__fish_seen_subcommand_from clean" -a "all" -d "All categories"

# Options
complete -c xcclean -s h -l help -d "Show help message"
complete -c xcclean -l version -d "Show version"
complete -c xcclean -s n -l dry-run -d "Preview without deleting"
complete -c xcclean -s y -l yes -d "Skip confirmation prompts"
complete -c xcclean -s q -l quiet -d "Minimal output"
complete -c xcclean -s v -l verbose -d "Verbose output"
complete -c xcclean -l no-color -d "Disable colored output"
complete -c xcclean -l json -d "Output in JSON format"
complete -c xcclean -l trash -d "Move to Trash instead of delete"
complete -c xcclean -l older-than -d "Only items older than N days" -x -a "7 14 30 60 90"
complete -c xcclean -l keep-latest -d "Keep N most recent items" -x -a "1 2 3 5"
complete -c xcclean -l project -d "Filter by project name" -x
