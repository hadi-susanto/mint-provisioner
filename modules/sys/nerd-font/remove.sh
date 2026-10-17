#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"

font_dir="/usr/local/share/fonts/nerd-font"
tag="remove:$CANONICAL_ID"

if [[ -L "$font_dir" ]]; then
    tlog_error "$tag" "Refusing to remove a symlink: %s" "$font_dir"

    exit 1
fi

if [[ ! -d "$font_dir" ]]; then
    tlog_info "$tag" "Font directory does not exist, skipping: %s" "$font_dir"

    exit 0
fi

tlog_info "$tag" "Removing font directory: %s" "$font_dir"

if ! sudo rm -rf -- "$font_dir"; then
    tlog_error "$tag" "Failed to remove font directory: %s" "$font_dir"

    exit 1
fi

if ! sudo fc-cache -f /usr/local/share/fonts; then
    tlog_warn "$tag" "Failed to refresh the font cache; run 'sudo fc-cache -f' manually"
fi
