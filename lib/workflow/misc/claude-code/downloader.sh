#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_CLAUDE_CODE_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_CLAUDE_CODE_DOWNLOADER_LOADED=1

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/extractor.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/latest-version.sh"

readonly __CLAUDE_DOWNLOAD_BASE_URL="https://downloads.claude.ai/claude-code-releases"

__resolve_claude_platform() {
    local canonical_id="$1"
    local tag="platform:$canonical_id"
    local arch
    local platform

    case "$(uname -m)" in
        x86_64 | amd64)
            arch="x64"
            ;;
        aarch64 | arm64)
            arch="arm64"
            ;;
        *)
            tlog_error "$tag" "Unsupported architecture: %s" "$(uname -m)"

            return 1
            ;;
    esac

    platform="linux-$arch"
    if [[ -f "/lib/libc.musl-x86_64.so.1" || -f "/lib/libc.musl-aarch64.so.1" ]] ||
        ldd /bin/ls 2>&1 | grep -q musl; then
        platform="${platform}-musl"
    fi

    printf '%s\n' "$platform"
}

__resolve_claude_checksum() {
    local canonical_id="$1"
    local version="$2"
    local platform="$3"
    local tag="checksum:$canonical_id"
    local manifest_file
    local manifest

    if ! manifest_file="$(mktemp --suffix=.json)"; then
        tlog_error "$tag" "Failed to create manifest temporary file"

        return 1
    fi

    if ! curl_download \
        "$canonical_id" "$__CLAUDE_DOWNLOAD_BASE_URL/$version/manifest.json" "$manifest_file"; then
        tlog_error "$tag" "Failed to download the release manifest"
        rm -f -- "$manifest_file"

        return 1
    fi

    manifest="$(<"$manifest_file")"
    rm -f -- "$manifest_file"
    manifest="$(tr -d '\n\r\t' <<<"$manifest" | sed 's/ \+/ /g')"

    if [[ $manifest =~ \"$platform\"[[:space:]]*:[[:space:]]*[{][^{}]*\"checksum\"[[:space:]]*:[[:space:]]*\"([a-f0-9]{64})\" ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"

        return 0
    fi

    tlog_error "$tag" "Platform %s not found in release manifest" "$platform"

    return 1
}

__zstd_available() {
    command -v zstd >/dev/null 2>&1
}

__download_claude_binary() {
    local canonical_id="$1"
    local version="$2"
    local platform="$3"
    local checksum="$4"
    local result_name="$5"
    local tag="download:$canonical_id"
    local -n result_ref="$result_name"
    local use_zstd=0
    local asset_name="claude"
    local downloaded_file

    if __zstd_available; then
        use_zstd=1
        asset_name="claude.zst"
    fi

    if ! result_ref="$(mktemp)"; then
        tlog_error "$tag" "Failed to create a temporary file"

        return 1
    fi

    downloaded_file="$result_ref"
    if (( use_zstd == 1 )); then
        downloaded_file="${result_ref}.zst"
    fi

    tlog_info "$tag" "Downloading %s asset" "$asset_name"
    if ! download_file "$canonical_id" \
        "$__CLAUDE_DOWNLOAD_BASE_URL/$version/$platform/$asset_name" "$downloaded_file"; then
        tlog_error "$tag" "Download failed"
        rm -f -- "$result_ref" "$downloaded_file"

        return 1
    fi

    if (( use_zstd == 1 )); then
        if ! extract_archive "$canonical_id" "zst" "$downloaded_file" "$(dirname -- "$result_ref")"; then
            rm -f -- "$result_ref" "$downloaded_file"

            return 1
        fi

        rm -f -- "$downloaded_file"
    fi

    if [[ ! -f "$result_ref" ]]; then
        tlog_error "$tag" "Expected binary not found: %s" "$result_ref"
        rm -f -- "$result_ref"

        return 1
    fi

    # The manifest checksum is for the unpacked binary, so verify after extraction.
    if ! verify_sha256 "$canonical_id" "$result_ref" "$checksum"; then
        rm -f -- "$result_ref"

        return 1
    fi
}

##
# claude_code_download <canonical_id>
#
# Downloads the latest Claude Code binary for this platform, verifies it
# against the release manifest, and saves BINARY_FILE and VERSION in the
# module state. Used by pre-install and pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Return:
#   1 - The platform is unsupported, or a lookup, download, or state update failed.
#
claude_code_download() {
    local canonical_id="$1"
    local platform
    local version
    local checksum
    local binary_file

    platform="$(__resolve_claude_platform "$canonical_id")" || return $?
    version="$(module_latest_version "$canonical_id")" || return $?
    checksum="$(__resolve_claude_checksum "$canonical_id" "$version" "$platform")" || return $?

    tlog_info "download:$canonical_id" "Downloading Claude Code %s (%s)" "$version" "$platform"
    __download_claude_binary "$canonical_id" "$version" "$platform" "$checksum" binary_file || return $?

    if ! set_state "BINARY_FILE" "$binary_file" || ! set_state "VERSION" "$version"; then
        rm -f -- "$binary_file"

        return 1
    fi

    if save_states "$canonical_id"; then
        return 0
    fi

    rm -f -- "$binary_file"

    return 1
}
