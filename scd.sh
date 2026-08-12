# scd - Jump to the working directory of a Slurm job.
#
# Source this file so that scd can change the current shell's directory:
#   . /path/to/scd.sh

scd() {
    local mode=cd
    local jobid=
    local jobinfo=
    local workdir=

    case "${1-}" in
        -h|--help)
            if [ "$#" -ne 1 ]; then
                printf 'scd: too many arguments\n' >&2
                printf 'Usage: scd JOBID\n       scd -p JOBID\n       scd -h\n' >&2
                return 2
            fi
            printf '%s\n' \
                'Usage: scd JOBID' \
                '       scd -p JOBID' \
                '       scd --print JOBID' \
                '       scd -h | --help' \
                '' \
                "Change to a Slurm job's WorkDir, or print it with -p/--print." \
                'Bash tab completion is available for RUNNING and PENDING jobs.'
            return 0
            ;;
        -p|--print)
            mode=print
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                printf 'scd: missing JOBID\n' >&2
                printf 'Usage: scd [-p|--print] JOBID\n' >&2
                return 2
            elif [ "$#" -gt 2 ]; then
                printf 'scd: too many arguments\n' >&2
                printf 'Usage: scd [-p|--print] JOBID\n' >&2
                return 2
            fi
            jobid=$2
            ;;
        '')
            printf 'scd: missing JOBID\n' >&2
            printf 'Usage: scd [-p|--print] JOBID\n' >&2
            return 2
            ;;
        -*)
            printf 'scd: unknown option: %s\n' "$1" >&2
            printf 'Usage: scd [-p|--print] JOBID\n' >&2
            return 2
            ;;
        *)
            if [ "$#" -gt 1 ]; then
                printf 'scd: too many arguments\n' >&2
                printf 'Usage: scd [-p|--print] JOBID\n' >&2
                return 2
            fi
            jobid=$1
            ;;
    esac

    if ! command -v scontrol >/dev/null 2>&1; then
        printf 'scd: scontrol is not available\n' >&2
        return 127
    fi

    # Let Slurm validate all supported job identifier forms.
    if ! jobinfo=$(scontrol show job -o "$jobid" 2>/dev/null) ||
       [ -z "$jobinfo" ]; then
        printf 'scd: job not found or unavailable: %s\n' "$jobid" >&2
        return 1
    fi

    # In scontrol's one-line output, fields are separated by whitespace.
    if [[ $jobinfo =~ (^|[[:space:]])WorkDir=([^[:space:]]*) ]]; then
        workdir=${BASH_REMATCH[2]}
    fi

    if [ -z "$workdir" ]; then
        printf 'scd: WorkDir is missing for job %s\n' "$jobid" >&2
        return 1
    fi

    if [ ! -d "$workdir" ]; then
        printf 'scd: directory does not exist: %s\n' "$workdir" >&2
        return 1
    fi

    if [ "$mode" = print ]; then
        printf '%s\n' "$workdir"
        return 0
    fi

    if ! builtin cd -- "$workdir"; then
        printf 'scd: unable to enter directory: %s\n' "$workdir" >&2
        return 1
    fi
}

_scd_completion() {
    local current=${COMP_WORDS[COMP_CWORD]}
    local jobid
    local jobids
    local option

    COMPREPLY=()

    if [ "$COMP_CWORD" -eq 1 ] && [[ $current == -* ]]; then
        for option in -p --print -h --help; do
            [[ $option == "$current"* ]] && COMPREPLY+=("$option")
        done
        return 0
    fi

    case $COMP_CWORD in
        1) ;;
        2)
            case ${COMP_WORDS[1]} in
                -p|--print) ;;
                *) return 0 ;;
            esac
            ;;
        *) return 0 ;;
    esac

    command -v squeue >/dev/null 2>&1 || return 0
    if ! jobids=$(command squeue --all --noheader \
        --states=RUNNING,PENDING --format='%i' 2>/dev/null); then
        return 0
    fi

    while read -r jobid; do
        [ -n "$jobid" ] &&
            [[ $jobid == "$current"* ]] &&
            COMPREPLY+=("$jobid")
    done <<< "$jobids"
}

complete -F _scd_completion scd
