#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/external.sh"
source "${LIB_INSTALLER}/state.sh"

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

if ! url="$(
    sourceforge_find_release \
        "$CANONICAL_ID" "cudatext" "release" "$version_regex" "$artifact_regex"
)"; then
    tlog_error "$CANONICAL_ID" "Failed to resolve the latest CudaText release"

    exit 3
fi

tlog_info "$CANONICAL_ID" "Creating temporary package file"

if ! deb_file="$(mktemp --suffix=.deb)"; then
    tlog_error "$CANONICAL_ID" "Failed to create temporary package file"

    exit 4
fi

if ! download_file "$CANONICAL_ID" "$url" "$deb_file"; then
    rm -f "$deb_file"

    exit 5
fi

set_state "DEB_FILE" "$deb_file"

if ! save_states "$CANONICAL_ID"; then
    rm -f "$deb_file"

    exit 6
fi

tlog_info "$CANONICAL_ID" "Download completed successfully"
