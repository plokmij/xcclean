# bash completion for xcclean

_xcclean() {
    local cur prev words cword
    _init_completion || return

    local commands="status scan clean list"
    local categories="derived archives device-support simulators caches all"
    local options="-h --help --version -n --dry-run -y --yes -q --quiet -v --verbose --no-color --json --trash --older-than --keep-latest --project"

    case "$prev" in
        clean|list)
            COMPREPLY=($(compgen -W "$categories" -- "$cur"))
            return
            ;;
        --older-than|--keep-latest)
            # Suggest some common values
            COMPREPLY=($(compgen -W "7 14 30 60 90" -- "$cur"))
            return
            ;;
        --project)
            # No completion for project names
            return
            ;;
    esac

    case "$cur" in
        -*)
            COMPREPLY=($(compgen -W "$options" -- "$cur"))
            ;;
        *)
            if [[ ${cword} -eq 1 ]]; then
                COMPREPLY=($(compgen -W "$commands $options" -- "$cur"))
            fi
            ;;
    esac
}

complete -F _xcclean xcclean
