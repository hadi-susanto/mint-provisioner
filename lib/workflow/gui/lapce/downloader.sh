#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_LAPCE_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_LAPCE_DOWNLOADER_LOADED=1

source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

__cleanup_lapce_downloads() {
    local key
    local file

    for key in DEB_FILE GRAMMARS_FILE QUERIES_FILE; do
        if file="$(get_state "$key" 2>/dev/null)"; then
            rm -f -- "$file" || true
        fi
    done
}

##
# lapce_download_assets <canonical_id>
#
# Downloads the Lapce .deb for the running Ubuntu codename and the
# tree-sitter grammars and queries archives into the DEB_FILE, GRAMMARS_FILE,
# and QUERIES_FILE states, with the Lapce release as VERSION. Used by
# pre-install and pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Return:
#   1 - The platform is unsupported, zstd is missing, or a lookup or download
#       failed.
#
lapce_download_assets() {
    local canonical_id="$1"
    local tag="download:$canonical_id"
    local codename
    local deb_regex
    local grammars_regex="grammars-linux-x86_64[.]tar[.]zst$"
    local queries_regex="queries[.]tar[.]zst$"
    local -A deb_asset=()
    local -A grammars_asset=()
    local -A queries_asset=()

    if [[ "$(uname -m)" != "x86_64" ]]; then
        tlog_error "$tag" "Only x86_64 is supported (Lapce grammars are published for x86_64 only)"

        return 1
    fi

    if ! command -v zstd >/dev/null 2>&1; then
        tlog_error "$tag" "zstd is required to extract Lapce grammars and queries"

        return 1
    fi

    codename="$(get_ubuntu_codename)" || return $?
    deb_regex="lapce[.]ubuntu[.]${codename}[.]amd64[.]deb$"

    github_find_release_asset "$canonical_id" "lapce" "lapce" "$deb_regex" deb_asset || return $?
    github_find_release_asset "$canonical_id" "lapce" "tree-sitter-grammars" "$grammars_regex" grammars_asset || return $?
    github_find_release_asset "$canonical_id" "lapce" "tree-sitter-grammars" "$queries_regex" queries_asset || return $?

    if ! stateful_download "$canonical_id" "DEB_FILE" "${deb_asset[URL]}" ".deb" 0 \
        "${deb_asset[SHA256]}" "${deb_asset[VERSION]}" ||
        ! stateful_download "$canonical_id" "GRAMMARS_FILE" "${grammars_asset[URL]}" ".tar.zst" 0 \
            "${grammars_asset[SHA256]}" ||
        ! stateful_download "$canonical_id" "QUERIES_FILE" "${queries_asset[URL]}" ".tar.zst" 0 \
            "${queries_asset[SHA256]}"; then
        __cleanup_lapce_downloads

        return 1
    fi

    save_states "$canonical_id"
}
