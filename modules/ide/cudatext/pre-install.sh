#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/source-forge.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_error "$CANONICAL_ID" " CudaText installation state was not found"

    exit 1
fi

CUDATEXT_UI_TOOLKIT="$(get_state "CUDATEXT_UI_TOOLKIT")" || exit 1

case "$CUDATEXT_UI_TOOLKIT" in
    gtk2|gtk3|qt5|qt6)
        ;;

    *)
        tlog_error "$CANONICAL_ID" \
            "Invalid CudaText UI toolkit in state: %s" "$CUDATEXT_UI_TOOLKIT"

        exit 2
        ;;
esac

version_regex='^[0-9]+(\.[0-9]+){3}$'
artifact_regex="^cudatext_[0-9]+(\\.[0-9]+){3}-[0-9]+_${CUDATEXT_UI_TOOLKIT}_amd64\\.deb$"

tlog_info "$CANONICAL_ID" "Finding the latest CudaText %s package" "$CUDATEXT_UI_TOOLKIT"
url="$(sourceforge_find_release "$CANONICAL_ID" "cudatext" "release" "$version_regex" "$artifact_regex")" || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "$url" ".deb"
