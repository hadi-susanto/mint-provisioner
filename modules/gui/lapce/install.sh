#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-deb-install.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"

tag="install:$CANONICAL_ID"
grammars_dir="${XDG_DATA_HOME:-$HOME/.local/share}/lapce-stable/grammars"
queries_dir="${XDG_CONFIG_HOME:-$HOME/.config}/lapce-stable/queries"

stateful_deb_install "$CANONICAL_ID" "DEB_FILE" || exit $?

if ! stateful_extract "$CANONICAL_ID" "GRAMMARS_FILE" "tar" "$grammars_dir"; then
    tlog_error "$tag" "Failed to install tree-sitter grammars to %s" "$grammars_dir"

    exit 1
fi

if ! stateful_extract "$CANONICAL_ID" "QUERIES_FILE" "tar" "$queries_dir"; then
    tlog_error "$tag" "Failed to install tree-sitter queries to %s" "$queries_dir"

    exit 1
fi
