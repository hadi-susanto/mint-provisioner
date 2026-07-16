if ! command -v jq >/dev/null 2>&1; then
    mkvmerge-extract-info() {
        printf '\033[31m[ERROR]\033[0m jq not installed, please install jq and re-open terminal.\n' >&2
    }

    # Immediate return to prevent any script execution
    return 0
fi

##
# Prints track information from a Matroska-compatible media file.
#
# The output includes:
#   - Track ID
#   - Track type and language
#   - Enabled, default, and forced flags
#   - Track name
#
# Each flag is represented by:
#   ✓ = true
#   ✗ = false
#
# Parameters:
#   $1 - Path to the input media file.
#
# Returns:
#   0 when track information is printed successfully.
#   1 when the file argument is missing, does not exist, is not a regular file,
#     or track information cannot be extracted.
#
# Dependencies:
#   mkvmerge
#   jq
__mkvmerge_extract_info() {
    local file="$1"

    if [[ -z "$file" ]]; then
        printf 'Error: missing file argument\n' >&2

        return 1
    fi

    if [[ ! -e "$file" ]]; then
        printf 'Error: file does not exist: %s\n' "$file" >&2

        return 1
    fi

    if [[ ! -f "$file" ]]; then
        printf 'Error: not a regular file: %s\n' "$file" >&2

        return 1
    fi

    local filename
    filename="$(basename -- "$file")"

    local colorize=false
    if __supports_color; then
        colorize=true
    fi

    printf 'Filename: %s\n\n' "$filename"

    printf '%-3s | %-15s | %-5s | %s\n' \
        'ID' \
        'Type' \
        'E|D|F' \
        'Name'

    printf '%s\n' \
        '----+-----------------+-----------+----------------------------------------'

    local enabled_icon
    local default_icon
    local forced_icon
    mkvmerge -J "$file" |
        jq -r '
            .tracks[]
            | [
                .id,
                .type,
                (.properties.language // ""),
                (.properties.enabled_track // false),
                (.properties.default_track // false),
                (.properties.forced_track // false),
                (.properties.track_name // "")
            ]
            | @tsv
        ' |
        while IFS=$'\t' read -r id type lang enabled default forced name; do
            enabled_icon="$(__boolean_to_icon "$enabled" "$colorize")"
            default_icon="$(__boolean_to_icon "$default" "$colorize")"
            forced_icon="$(__boolean_to_icon "$forced" "$colorize")"

            printf '%3d | %-15s | ' \
                "$id" \
                "$type:$lang"

            printf '%s|%s|%s' \
                "$enabled_icon" \
                "$default_icon" \
                "$forced_icon"

            printf ' | %s\n' "$name"
        done

    printf '\nLegends: [E] = Enabled Flag, [D] = Default Flag, [F] = Forced Flag\n'
}

##
# Prints the usage information for mkvmerge-batch.
#
# This function is intended for internal use only.
#
# Usage:
#   __mkvmerge_extract_info_usage
#
__mkvmerge_extract_info_usage() {
    cat <<'EOF'
Usage:
  mkvmerge-extract-info [OPTIONS]

Description:
  Performs single or batch extracting of video info file(s) using mkvmerge and jq.

Options:
  -i,  --input FILE/DIR
      Input directory.
      Default: current directory.

  -e,  --extension EXT
      File extension(s) to process.
      Can be repeated to have multiple extensions
      Default: mkv

  -h,  --help
      Show this help message and exit.

Examples:
  mkvmerge-extract-info

  mkvmerge-extract-info \
      -i movies \
      -e mkv mp4
EOF
}

##
# Extract info for all matching media files in a directory using mkvmerge.
#
# This function is intended for internal use only.
#
# Usage:
#   __mkvmerge_extract_info_folder \
#       <input-folder> \
#       <extensions...> \
#
__mkvmerge_extract_info_folder() {
    local input_folder="$1"

    shift 1

    local -a files=()

    local file
    local ext
    local filename_lower

    while IFS= read -r -d '' file; do
        filename_lower="$(tolower "${file##*.}")"

        for ext in "$@"; do
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

    local i=0

    for file in "${files[@]}"; do
        ((++i))

        printf '[%d/%d] ' \
            "$i" \
            "${#files[@]}"

        __mkvmerge_extract_info "$file" || return $?

        printf '\n'
    done
}

##
# Performs single file or batch media info extractions.
#
# Usage:
#   mkvmerge-extract-info [OPTIONS]
#
# Custom options:
#   -i,  --input FILE/DIR
#       Input file or directory.
#
#   -e,  --extension EXT
#       File extension to process. Specify multiple -e options to process
#       multiple extensions. Default: mkv.
#
#   -h,  --help
#       Show usage information.
#
mkvmerge-extract-info() {
    local input="."
    local dry_run="false"

    local -a extensions=()

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

            -e|--extension)
                [[ $# -ge 2 ]] || {
                    printf 'Missing value for %s\n' "$1" >&2
                    return 1
                }

                extensions+=("${2#.}")
                shift 2
                ;;

            -h|--help)
                __mkvmerge_extract_info_usage
                return 0
                ;;

            *)
                printf 'Unknown option/parameter given: %s\n' "$1" >&2
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

    #
    # Dispatch to the appropriate helper.
    #
    if [[ -f "$input" ]]; then
        __mkvmerge_extract_info "$input"
        printf '\n'

    elif [[ -d "$input" ]]; then
        __mkvmerge_extract_info_folder \
            "$input" \
            "${extensions[@]}"

    else
        printf 'Unsupported input type: %s\n' "$input" >&2

        return 1
    fi

    printf 'mkvmerge-extract-info completed\n'
}
