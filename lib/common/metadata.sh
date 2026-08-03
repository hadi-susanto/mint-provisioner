#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_METADATA_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_METADATA_LOADED=1

source "$LIB_COMMON/common.sh"

__validate_required_metadata() {
    local metadata_name="$1"
    local metadata_file="$2"
    shift 2

    local -n metadata_ref="$metadata_name"
    local required_key

    for required_key in "$@"; do
        if [[ -z "${metadata_ref[$required_key]:-}" ]]; then
            tlog_error "metadata" "Missing required metadata key in %s: %s" \
                "$metadata_file" "$required_key"

            return 1
        fi
    done

    return 0
}

##
# parse_metadata
#
# Parses declarative metadata from a directory's metadata.conf file.
#
# Parameters:
#   directory     - Directory containing metadata.conf.
#   metadata_name - Name of the associative array that receives parsed values.
#
# Returns:
#   1 when the directory, metadata file, or metadata syntax is invalid.
#
parse_metadata() {
    local directory="$1"
    local metadata_name="$2"
    local -n metadata_ref="$metadata_name"
    local metadata_file="$directory/metadata.conf"
    local line
    local key
    local value
    local line_number=0
    local -A seen=()

    metadata_ref=()

    if [[ -z "$directory" ]] || [[ ! -d "$directory" ]] || [[ -L "$directory" ]]; then
        tlog_error "metadata" "Invalid metadata directory: %s" "${directory:-<missing>}"

        return 1
    fi

    if [[ ! -f "$metadata_file" ]] || [[ -L "$metadata_file" ]]; then
        tlog_error "metadata" "Metadata file not found or invalid: %s" "$metadata_file"

        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number += 1))
        line="${line%$'\r'}"
        __trim line

        if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
            continue
        fi

        if [[ "$line" != *=* ]]; then
            tlog_error "metadata" "Invalid metadata at %s:%d" "$metadata_file" "$line_number"

            return 1
        fi

        key="${line%%=*}"
        value="${line#*=}"
        __trim key
        __trim value

        if [[ ! "$key" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
            tlog_error "metadata" "Invalid metadata key at %s:%d: %s" \
                "$metadata_file" "$line_number" "$key"

            return 1
        fi

        if [[ -v "seen[$key]" ]]; then
            tlog_error "metadata" "Duplicate metadata key at %s:%d: %s" \
                "$metadata_file" "$line_number" "$key"

            return 1
        fi

        if [[ "$value" == \"* ]] || [[ "$value" == *\" ]]; then
            if [[ "$value" != \"*\" ]] || (( ${#value} < 2 )); then
                tlog_error "metadata" "Invalid quoted metadata value at %s:%d" \
                    "$metadata_file" "$line_number"

                return 1
            fi

            # Strip the surrounding double quotes.
            value="${value:1:${#value}-2}"
        fi

        metadata_ref["$key"]="$value"
        seen["$key"]=1
    done < "$metadata_file"

    return 0
}

##
# parse_category_metadata
#
# Parses and validates category metadata.
#
# Parameters:
#   directory     - Category directory containing metadata.conf.
#   metadata_name - Name of the associative array that receives parsed values.
#
# Returns:
#   1 when parsing fails or required category metadata is missing.
#
parse_category_metadata() {
    local directory="$1"
    local metadata_name="$2"

    parse_metadata "$directory" "$metadata_name" || return $?
    __validate_required_metadata \
        "$metadata_name" "$directory/metadata.conf" NAME DESCRIPTION
}

##
# parse_module_metadata
#
# Parses and validates module metadata.
#
# Parameters:
#   directory     - Module directory containing metadata.conf.
#   metadata_name - Name of the associative array that receives parsed values.
#
# Returns:
#   1 when parsing fails, required metadata is missing, or SOURCE is invalid.
#
parse_module_metadata() {
    local directory="$1"
    local metadata_name="$2"
    local -n metadata_ref="$metadata_name"

    parse_metadata "$directory" "$metadata_name" || return $?
    __validate_required_metadata \
        "$metadata_name" "$directory/metadata.conf" NAME DESCRIPTION SOURCE || return $?

    case "${metadata_ref[SOURCE]}" in
        native | ppa | apt | github | external | sourceforge)
            ;;
        *)
            tlog_error "metadata" "Invalid module metadata SOURCE in %s: %s" \
                "$directory/metadata.conf" "${metadata_ref[SOURCE]}"

            return 1
            ;;
    esac

    return 0
}
