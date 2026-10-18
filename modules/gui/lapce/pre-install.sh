#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

tag="pre-install:$CANONICAL_ID"

if [[ "$(uname -m)" != "x86_64" ]]; then
    tlog_error "$tag" "Only x86_64 is supported (Lapce grammars are published for x86_64 only)"

    exit 1
fi

if ! command -v zstd >/dev/null 2>&1; then
    tlog_error "$tag" "zstd is required to extract Lapce grammars and queries"

    exit 1
fi

codename="$(get_ubuntu_codename)" || exit $?
deb_regex="lapce[.]ubuntu[.]${codename}[.]amd64[.]deb$"
grammars_regex="grammars-linux-x86_64[.]tar[.]zst$"
queries_regex="queries[.]tar[.]zst$"

deb_url="$(github_find_release "$CANONICAL_ID" "lapce" "lapce" "$deb_regex")" || exit $?
grammars_url="$(github_find_release "$CANONICAL_ID" "lapce" "tree-sitter-grammars" "$grammars_regex")" || exit $?
queries_url="$(github_find_release "$CANONICAL_ID" "lapce" "tree-sitter-grammars" "$queries_regex")" || exit $?

__cleanup_downloads() {
    local key
    local file

    for key in DEB_FILE GRAMMARS_FILE QUERIES_FILE; do
        if file="$(get_state "$key" 2>/dev/null)"; then
            rm -f -- "$file" || true
        fi
    done
}

if ! stateful_download "$CANONICAL_ID" "DEB_FILE" "$deb_url" ".deb" 0 ||
    ! stateful_download "$CANONICAL_ID" "GRAMMARS_FILE" "$grammars_url" ".tar.zst" 0 ||
    ! stateful_download "$CANONICAL_ID" "QUERIES_FILE" "$queries_url" ".tar.zst" 0; then
    __cleanup_downloads

    exit 1
fi

save_states "$CANONICAL_ID"
