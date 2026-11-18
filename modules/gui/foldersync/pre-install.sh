#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

tag="pre-install:$CANONICAL_ID"
arch="$(dpkg --print-architecture)"

case "$arch" in
    amd64 | arm64) ;;
    *)
        tlog_error "$tag" "Unsupported architecture: %s" "$arch"

        exit 1
        ;;
esac

regex="tacit-dynamics-aps-foldersync-desktop_[^/]*_${arch}[.]deb$"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "tacitdynamics" "foldersync-desktop-production" "$regex" asset || exit $?

# The package ships its own APT source and signing key, so APT tracks later releases;
# UPDATE_MODE="apt" reads the version from dpkg and no registry VERSION is recorded.
stateful_download "$CANONICAL_ID" "DEB_FILE" "${asset[URL]}" ".deb" 1 "${asset[SHA256]}"
