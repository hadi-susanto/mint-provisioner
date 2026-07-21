##
# Internal helper to invoke mkvmerge with automatic option expansion.
#
# This function is intended for internal use only and should not be called
# directly by end users.
#
# Usage:
#   __mkvmerge_process_execute <dry-run> <input-file> <output-file> [options...]
#
# Parameters:
#   $1  Dry-run mode. Accepted values:
#         true  - Print the command instead of executing it.
#         false - Execute the command.
#   $2  Input MKV file.
#   $3  Output MKV file.
#   $4... mkvmerge options and their arguments.
#
# Parsing rules:
#   - Any parameter beginning with '-' is treated as an mkvmerge option.
#   - Any parameter not beginning with '-' is treated as an argument for the
#     previously encountered option.
#   - If multiple consecutive arguments follow an option, the option is
#     repeated for each argument.
#   - Options without arguments are forwarded unchanged.
#
# Example:
#   __mkvmerge_process_execute \
#       false \
#       input.mkv \
#       output.mkv \
#       --language eng jpn \
#       --track-name "0:English" "1:Japanese" \
#       --no-audio \
#       -y
#
# Executes:
#   mkvmerge \
#       -o output.mkv \
#       --language eng \
#       --language jpn \
#       --track-name "0:English" \
#       --track-name "1:Japanese" \
#       --no-audio \
#       -y \
#       input.mkv
#
# Notes:
#   - This helper assumes that option arguments never begin with '-'.
#   - If an argument is encountered before any option, the function returns
#     an error.
#
__mkvmerge_process_execute() {
    local dry_run="$1"
    local input_file="$2"
    local output_file="$3"

    shift 3

    local current_option=""
    local option_has_value=false
    local -a args=()

    for arg in "$@"; do
        if [[ "$arg" == -* ]]; then
            if [[ -n "$current_option" && "$option_has_value" == false ]]; then
                args+=("$current_option")
            fi

            current_option="$arg"
            option_has_value=false
        else
            if [[ -z "$current_option" ]]; then
                printf 'Error: value "%s" has no preceding option.\n' "$arg" >&2

                return 1
            fi

            args+=("$current_option" "$arg")
            option_has_value=true
        fi
    done

    # Emit the final flag-only option.
    if [[ -n "$current_option" && "$option_has_value" == false ]]; then
        args+=("$current_option")
    fi

    local -a cmd=(
        mkvmerge
        -o "$output_file"
        "${args[@]}"
        "$input_file"
    )

    if [ "$dry_run" = "true" ]; then
        printf '[DRY RUN] '
        for c in "${cmd[@]}"; do
            printf '%s ' "$c"
        done
        printf '\n'

        return 0
    fi

    "${cmd[@]}"
}

##
# Prints the usage information for mkvmerge-batch.
#
# This function is intended for internal use only.
#
# Usage:
#   __mkvmerge_process_usage
#
__mkvmerge_process_usage() {
    cat <<'EOF'
Usage:
  mkvmerge-process [OPTIONS] [MKVMERGE_OPTIONS...]

Description:
  Performs single or batch processing of video file(s) using mkvmerge.

Options:
  -i,  --input FILE/DIR
      Input directory.
      Default: current directory.

  -o,  --output DIR
      Output directory.
      Default: <input-directory>/output

  -e,  --extension EXT
      File extension(s) to process.
      Can be repeated to have multiple extensions
      Default: mkv

  -d,  --default TID[:bool] ...
      Shorthand for --default-track-flag of mkvmerge options

  -f,  --forced TID[:bool] ...
      Shorthand for --forced-display-flag of mkvmerge options

  -dr, --dry-run
  -pc, --print-command
      Print the mkvmerge command(s) without executing them.

  -h,  --help
      Show this help message and exit.

MKVMERGE_OPTIONS:
  Any unrecognized options are forwarded to mkvmerge. If an option accepts
  multiple values, the option is automatically repeated for each value.

Examples:
  mkvmerge-process

  mkvmerge-process \
      -i movies \
      -o output \
      -e mkv mp4

  mkvmerge-process \
      -e mkv \
      --language eng jpn \
      --track-name "0:English" "1:Japanese"

  mkvmerge-process \
      --dry-run \
      --no-audio
EOF
}

##
# Prints a summary of the batch operation.
#
# This function is intended for internal use only.
#
# Usage:
#   __mkvmerge_process_summary \
#       <input-file-or-folder> \
#       <output-folder> \
#       <dry-run> \
#       <file-count> \
#       <extensions-array>
#
# Parameters:
#   $1  Input file or folder.
#   $2  Output folder.
#   $3  Dry-run mode ("true" or "false").
#   $4  Number of files to process.
#   $5... File extensions.
#
__mkvmerge_process_summary() {
    local input="$1"
    local output_folder="$2"
    local dry_run="$3"
    local file_count="$4"

    shift 4

    printf 'Summary\n'
    printf '=======\n'
    printf 'Input File/Folder : %s\n' "$input"
    printf 'Output Folder     : %s\n' "$output_folder"

    printf 'Extensions   : '
    printf '%s ' "$@"
    printf '\n'

    printf 'Files Found  : %s\n' "$file_count"
    printf 'Dry Run      : %s\n' "$dry_run"
    printf '\n'
}

##
# Prompts the user for confirmation.
#
# This function is intended for internal use only.
#
# Usage:
#   __mkvmerge_process_confirm
#
# Returns:
#   0  User confirmed.
#   1  User declined or pressed Enter.
#
# Notes:
#   - The default answer is "No".
#   - Only "y" or "yes" (case-insensitive) are treated as confirmation.
#
__mkvmerge_process_confirm() {
    local answer

    printf 'Continue? [y/N]: '
    read -r answer

    case "${answer:l}" in
        y|yes)
            return 0
            ;;
        *)
            printf 'Operation cancelled.\n'

            return 1
            ;;
    esac
}

##
# Processes a single media file using mkvmerge.
#
# This function is intended for internal use only.
#
# Usage:
#   __mkvmerge_process_file \
#       <input-file> \
#       <output-folder> \
#       <dry-run> \
#       [mkvmerge-options...]
#
__mkvmerge_process_file() {
    local input_file="$1"
    local output_folder="$2"
    local dry_run="$3"

    shift 3

    local output_file
    output_file="${output_folder}/$(basename "$input_file")"

    __mkvmerge_process_summary \
        "$input_file" \
        "$output_folder" \
        "$dry_run" \
        1 \
        "$(tolower "${input_file##*.}")"

    printf 'mkvmerge Options:\n  '
    printf '%q ' "$@"
    printf '\n\n'

    if [[ "$dry_run" != "true" ]]; then
        __mkvmerge_process_confirm || return 0
        printf '\n'
    fi

    printf '[1/1] %s\n' "$(basename "$input_file")"
    printf '%s\n' '--------------------------------------------------'

    __mkvmerge_process_execute \
        "$dry_run" \
        "$input_file" \
        "$output_file" \
        "$@"

    printf '\n'
}

##
# Processes all matching media files in a directory using mkvmerge.
#
# This function is intended for internal use only.
#
# Usage:
#   __mkvmerge_process_folder \
#       <input-folder> \
#       <output-folder> \
#       <dry-run> \
#       <extensions...> \
#       -- \
#       <mkvmerge-options...>
#
__mkvmerge_process_folder() {
    local input_folder="$1"
    local output_folder="$2"
    local dry_run="$3"

    shift 3

    local -a extensions=()
    local -a mkvmerge_args=()
    local -a files=()

    while (($#)); do
        [[ "$1" == "--" ]] && {
            shift
            break
        }

        extensions+=("$1")
        shift
    done

    mkvmerge_args=("$@")

    local file
    local ext
    local filename_lower

    while IFS= read -r -d '' file; do
        filename_lower="$(tolower "${file##*.}")"

        for ext in "${extensions[@]}"; do
            if [[ "$filename_lower" == "$ext" ]]; then
                files+=("$file")
                break
            fi
        done
    done < <(find "$input_folder" -maxdepth 1 -type f -print0)

    if ((${#files[@]} == 0)); then
        printf 'No matching files found.\n'

        return 0
    fi

    __mkvmerge_process_summary \
        "$input_folder" \
        "$output_folder" \
        "$dry_run" \
        "${#files[@]}" \
        "${extensions[@]}"

    printf 'mkvmerge Options:\n  '
    printf '%q ' "${mkvmerge_args[@]}"
    printf '\n\n'

    if [[ "$dry_run" != "true" ]]; then
        __mkvmerge_process_confirm || return 0
        printf '\n'
    fi

    local i=0
    local output_file

    for file in "${files[@]}"; do
        ((++i))

        output_file="${output_folder}/$(basename "$file")"

        printf '[%d/%d] %s\n' \
            "$i" \
            "${#files[@]}" \
            "$(basename "$file")"

        printf '%s\n' '--------------------------------------------------'

        __mkvmerge_process_execute \
            "$dry_run" \
            "$file" \
            "$output_file" \
            "${mkvmerge_args[@]}" || return $?

        printf '\n'
    done
}

##
# Performs single file or batch processing of media files using mkvmerge.
#
# Usage:
#   mkvmerge-process [OPTIONS] [MKVMERGE_OPTIONS...]
#
# Custom options:
#   -i,  --input FILE/DIR
#       Input file or directory.
#
#   -o,  --output DIR
#       Output directory.
#
#   -e,  --extension EXT
#       File extension to process. Specify multiple -e options to process
#       multiple extensions. Default: mkv.
#
#   -d,  --default TID[:bool]
#       Shorthand for --default-track-flag of mkvmerge options
#
#   -f,  --forced TID[:bool]
#       Shorthand for --forced-track-flag of mkvmerge options
#
#   -dr, --dry-run
#   -pc, --print-command
#       Print mkvmerge commands without executing them.
#
#   -h,  --help
#       Show usage information.
#
# Any remaining options are forwarded to mkvmerge.
#
mkvmerge-process() {
    local input="."
    local output_folder=""
    local dry_run="false"

    local -a extensions=()
    local -a mkvmerge_args=()

    #
    # Parse command line.
    #
    while (($#)); do
        case "$1" in
            -i|--input)
                [[ $# -ge 2 ]] || {
                    printf 'Missing value for %s\n' "$1" >&2

                    return 1
                }

                input="$2"
                shift 2
                ;;

            -o|--output)
                [[ $# -ge 2 ]] || {
                    printf 'Missing value for %s\n' "$1" >&2

                    return 1
                }

                output_folder="$2"
                shift 2
                ;;

            -e|--extension)
                [[ $# -ge 2 ]] || {
                    printf 'Missing value for %s\n' "$1" >&2

                    return 1
                }

                extensions+=("${2#.}")
                shift 2
                ;;

            -dr|--dry-run|-pc|--print-command)
                dry_run="true"
                shift
                ;;

            -h|--help)
                __mkvmerge_process_usage

                return 0
                ;;

            -d|--default)
                mkvmerge_args+=("--default-track-flag")
                shift
                ;;

            -f|--forced)
                mkvmerge_args+=("--forced-display-flag")
                shift
                ;;

            *)
                mkvmerge_args+=("$1")
                shift
                ;;
        esac
    done

    #
    # Validate input.
    #
    if [[ ! -e "$input" ]]; then
        printf 'Input does not exist: %s\n' "$input" >&2

        return 1
    fi

    #
    # Validate mkvmerge options.
    #
    if ((${#mkvmerge_args[@]} == 0)); then
        printf 'Error: no mkvmerge options provided.\n' >&2
        printf 'Provide at least one mkvmerge option or argument.\n' >&2
        printf '\n' >&2
        __mkvmerge_process_usage

        return 1
    fi

    #
    # Apply default output directory.
    #
    if [[ -z "$output_folder" ]]; then
        if [[ -f "$input" ]]; then
            output_folder="$(dirname "$input")/output"
        else
            output_folder="${input}/output"
        fi
    fi

    #
    # Create output directory.
    #
    if ! mkdir -p "$output_folder"; then
        printf 'Failed to create output directory: %s\n' "$output_folder" >&2

        return 1
    fi

    #
    # Apply default extensions.
    #
    if ((${#extensions[@]} == 0)); then
        extensions=("mkv")
    fi

    #
    # Normalize extensions.
    #
    local -a normalized_extensions=()
    local ext

    for ext in "${extensions[@]}"; do
      ext="$(tolower "$ext")"
      normalized_extensions+=("${ext#.}")
    done

    extensions=("${normalized_extensions[@]}")

    #
    # Canonicalize paths.
    #
    input="$(realpath "$input")"
    output_folder="$(realpath "$output_folder")"

    #
    # Dispatch to the appropriate helper.
    #
    if [[ -f "$input" ]]; then
        __mkvmerge_process_file \
            "$input" \
            "$output_folder" \
            "$dry_run" \
            "${mkvmerge_args[@]}"

    elif [[ -d "$input" ]]; then
        __mkvmerge_process_folder \
            "$input" \
            "$output_folder" \
            "$dry_run" \
            "${extensions[@]}" \
            -- \
            "${mkvmerge_args[@]}"

    else
        printf 'Unsupported input type: %s\n' "$input" >&2

        return 1
    fi

    printf 'mkvmerge-process completed\n'
}
