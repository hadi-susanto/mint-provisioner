#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_EXTRACTOR_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_EXTRACTOR_LOADED=1

source "$LIB_COMMON/common.sh"

##
# extract_archive <canonical_id> <type> <source> <destination> <extractor args...>
#
# Extracts an archive to a destination directory using type-based dispatch.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging.
#   type - Archive type (for example: zip, tar, tar.gz).
#   source - Archive file path.
#   destination - Extraction destination directory.
#   extractor args... - Additional extractor arguments passed as-is.
#
# Return:
#   1 - Validation failed, archive type is unsupported, or extraction failed.
#
extract_archive() {
    local canonical_id="$1"
    local archive_type="$2"
    local source_file="$3"
    local destination_dir="$4"
    local tag="extract:$canonical_id"
    local status=0

    if [[ ! -f "$source_file" ]]; then
        tlog_error "$tag" "Archive file does not exist: %s" "$source_file"

        return 1
    fi

    if [[ -e "$destination_dir" ]]; then
        if [[ ! -d "$destination_dir" ]]; then
            tlog_error "$tag" "Destination exists but is not a directory: %s" \
                "$destination_dir"

            return 1
        fi
    else
        if ! mkdir -p -- "$destination_dir"; then
            tlog_error "$tag" "Failed to create extraction directory: %s" "$destination_dir"

            return 1
        fi
    fi

    shift 4

    tlog_info "$tag" "Extracting %s archive" "$archive_type"
    tlog_info "$tag" "Archive File: %s" "$source_file"
    tlog_info "$tag" "Destination: %s" "$destination_dir"

    case "$archive_type" in
        zip)
            unzip -o "$@" "$source_file" -d "$destination_dir" || status = $?
            ;;
        tar)
            tar --overwrite -xf "$source_file" -C "$destination_dir" "$@" || status = $?
            ;;
        tar.gz)
            tar --overwrite -xzf "$source_file" -C "$destination_dir" "$@" || status = $?
            ;;
        tar.bz2)
            tar --overwrite -xjf "$source_file" -C "$destination_dir" "$@" || status = $?
            ;;
        tar.bxz | txz)
            tar --overwrite -xJf "$source_file" -C "$destination_dir" "$@" || status = $?
            ;;
        *)
            tlog_error "$tag" "Unsupported archive type: %s" "$archive_type"

            return 1
            ;;
    esac

    if (( status == 0 )); then
        return 0
    fi

    tlog_error "$tag" "Failed to extract %s archive: %s" \
        "$archive_type" "$source_file"

    return 1
}
