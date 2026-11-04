#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_ARTCRAFT_DOWNLOAD_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_ARTCRAFT_DOWNLOAD_LOADED=1

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

##
# artcraft_download_release <canonical_id> <repository>
#
# Downloads the linux-x86_64 .deb of the latest release of an ArtCraft app from
# storytold/<repository>, verifies it against the GitHub digest, and saves
# DEB_FILE and VERSION in the module state; cleanup.sh removes the file. Used by
# the art modules' pre-install and pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   repository - GitHub repository and asset name, such as photocraft.
#
# Return:
#   1 - The architecture is unsupported, or the release lookup or download failed.
#   2 - No asset, or more than one asset, matched the release.
#
artcraft_download_release() {
    local canonical_id="$1"
    local repository="$2"
    local tag="download:$canonical_id"
    local regex="${repository}-.*-linux-x86_64[.]deb$"
    local -A asset=()

    if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
        tlog_error "$tag" "%s .deb installation supports amd64 only" "$repository"

        return 1
    fi

    github_find_release_asset "$canonical_id" "storytold" "$repository" "$regex" asset || return $?
    stateful_download "$canonical_id" "DEB_FILE" "${asset[URL]}" ".deb" 1 "${asset[SHA256]}" "${asset[VERSION]}"
}
