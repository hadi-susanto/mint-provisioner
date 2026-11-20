#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_RIO_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_RIO_DOWNLOADER_LOADED=1

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

##
# rio_display_server
#
# Selects the Rio build variant. RIO_DISPLAY_SERVER (wayland or x11) wins;
# otherwise a Wayland session (XDG_SESSION_TYPE=wayland or WAYLAND_DISPLAY set)
# selects wayland and anything else selects x11.
#
# Output:
#   Prints "wayland" or "x11".
#
# Return:
#   1 - RIO_DISPLAY_SERVER has an unsupported value.
#
rio_display_server() {
    local requested="${RIO_DISPLAY_SERVER:-}"

    case "$requested" in
        wayland|x11)
            printf '%s\n' "$requested"

            return 0
            ;;
        "")
            ;;
        *)
            log_error "Unsupported RIO_DISPLAY_SERVER: $requested (expected wayland or x11)"

            return 1
            ;;
    esac

    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" || -n "${WAYLAND_DISPLAY:-}" ]]; then
        printf 'wayland\n'
    else
        printf 'x11\n'
    fi
}

##
# rio_download_deb <canonical_id>
#
# Downloads the Rio .deb for the system architecture and display server into
# the DEB_FILE state, with the release tag as VERSION. Used by pre-install and
# pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Return:
#   1 - The architecture or RIO_DISPLAY_SERVER is unsupported, or the
#       download failed.
#   2 - No release asset, or more than one, matched.
#
rio_download_deb() {
    local canonical_id="$1"
    local tag="download:$canonical_id"
    local arch
    local display_server
    local -A rio_asset=()

    arch="$(dpkg --print-architecture)"

    if [[ "$arch" != "amd64" && "$arch" != "arm64" ]]; then
        tlog_error "$tag" "Unsupported architecture: %s (Rio ships amd64 and arm64 only)" "$arch"

        return 1
    fi

    display_server="$(rio_display_server)" || return 1
    tlog_info "$tag" "Using the %s build of Rio" "$display_server"

    github_find_release_asset "$canonical_id" "raphamorim" "rio" \
        "rioterm_[^/]*_${arch}_${display_server}[.]deb$" rio_asset || return $?
    stateful_download "$canonical_id" "DEB_FILE" "${rio_asset[URL]}" ".deb" 1 \
        "${rio_asset[SHA256]}" "${rio_asset[VERSION]}"
}
