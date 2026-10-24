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

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local target
    local archive_url
    local checksum_url
    local expected_checksum

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

    expected_checksum="$(
        fetch_sha256_from_sums "$canonical_id" "$checksum_url" "codex-package-$target.tar.gz"
    )" || return $?

    tlog_info "pre-install:$canonical_id" "Downloading Codex CLI (%s)" "$target"
    stateful_download "$canonical_id" "ARCHIVE_FILE" "$archive_url" ".tar.gz" 1 \
        "$expected_checksum"
}

main "$CANONICAL_ID" "${CODEX_INSTALL_DIR:-$INSTALL_DIR/codex}"
