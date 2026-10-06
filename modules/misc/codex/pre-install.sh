#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

declare -r CODEX_GITHUB_OWNER="openai"
declare -r CODEX_GITHUB_REPO="codex"

__resolve_codex_target() {
    local canonical_id="$1"
    local tag="platform:$canonical_id"

    case "$(uname -m)" in
        x86_64 | amd64)
            printf '%s\n' "x86_64-unknown-linux-musl"
            ;;
        aarch64 | arm64)
            printf '%s\n' "aarch64-unknown-linux-musl"
            ;;
        *)
            tlog_error "$tag" "Unsupported architecture: %s" "$(uname -m)"

            return 1
            ;;
    esac
}

__resolve_codex_checksum() {
    local canonical_id="$1"
    local target="$2"
    local checksum_url="$3"
    local tag="checksum:$canonical_id"
    local checksum_file
    local expected

    if ! checksum_file="$(mktemp --suffix=.sha256)"; then
        tlog_error "$tag" "Failed to create checksum temporary file"

        return 1
    fi

    if ! curl_download "$canonical_id" "$checksum_url" "$checksum_file"; then
        tlog_error "$tag" "Failed to download the release checksum file"
        rm -f -- "$checksum_file"

        return 1
    fi

    expected="$(awk -v name="codex-package-$target.tar.gz" '$2 == name { print $1 }' "$checksum_file")"
    rm -f -- "$checksum_file"

    if [[ ! "$expected" =~ ^[a-f0-9]{64}$ ]]; then
        tlog_error "$tag" "Checksum not found for target: %s" "$target"

        return 1
    fi

    printf '%s\n' "$expected"
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local target
    local archive_url
    local checksum_url
    local expected_checksum
    local archive_file

    valid_install_target "$canonical_id" "$raw_install_path" "CODEX_INSTALL_DIR" || return $?

    target="$(__resolve_codex_target "$canonical_id")" || return $?

    archive_url="$(
        github_find_release "$canonical_id" "$CODEX_GITHUB_OWNER" "$CODEX_GITHUB_REPO" \
            "codex-package-${target}\.tar\.gz$"
    )" || return $?
    checksum_url="$(
        github_find_release "$canonical_id" "$CODEX_GITHUB_OWNER" "$CODEX_GITHUB_REPO" \
            "codex-package_SHA256SUMS$"
    )" || return $?

    expected_checksum="$(__resolve_codex_checksum "$canonical_id" "$target" "$checksum_url")" || return $?

    tlog_info "pre-install:$canonical_id" "Downloading Codex CLI (%s)" "$target"
    stateful_download "$canonical_id" "ARCHIVE_FILE" "$archive_url" ".tar.gz" 0 || return $?

    archive_file="$(get_state "ARCHIVE_FILE")" || return $?
    if [[ "$(sha256sum "$archive_file" | awk '{ print $1 }')" != "$expected_checksum" ]]; then
        tlog_error "pre-install:$canonical_id" "Checksum verification failed"
        rm -f -- "$archive_file"

        return 1
    fi

    tlog_info "pre-install:$canonical_id" "Checksum verified"
    save_states "$canonical_id"
}

main "$CANONICAL_ID" "${CODEX_INSTALL_DIR:-$INSTALL_DIR/codex}"
