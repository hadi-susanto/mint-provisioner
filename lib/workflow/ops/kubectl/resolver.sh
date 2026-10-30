#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_KUBECTL_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_KUBECTL_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

__KUBECTL_RELEASE_URL="https://dl.k8s.io/release"

##
# kubectl_latest_version <canonical_id>
#
# Resolves the latest stable Kubernetes release from dl.k8s.io.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#
# Output:
#   Prints the version tag, such as v1.34.1.
#
# Return:
#   1 - The lookup failed or returned an unexpected value.
#
kubectl_latest_version() {
    local canonical_id="$1"
    local tag="latest:$canonical_id"
    local version

    if ! version="$(curl -fsSL "$__KUBECTL_RELEASE_URL/stable.txt")"; then
        tlog_error "$tag" "Failed to query the latest kubectl version"

        return 1
    fi

    if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        tlog_error "$tag" "Unexpected kubectl version: %s" "${version:-<empty>}"

        return 1
    fi

    printf '%s\n' "$version"
}

##
# kubectl_download_binary <canonical_id>
#
# Downloads the latest linux/amd64 kubectl binary, verifies it against the
# checksum published next to it, and stores its path in the BINARY_FILE state
# together with VERSION. Used by pre-install.sh and pre-upgrade.sh.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Return:
#   1 - The architecture is unsupported, or a lookup or download failed.
#
kubectl_download_binary() {
    local canonical_id="$1"
    local tag="download:$canonical_id"
    local version
    local url
    local checksum

    if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
        tlog_error "$tag" "kubectl binary installation supports amd64 only"

        return 1
    fi

    version="$(kubectl_latest_version "$canonical_id")" || return $?
    tlog_info "$tag" "Latest kubectl version: %s" "$version"

    url="$__KUBECTL_RELEASE_URL/$version/bin/linux/amd64/kubectl"

    if ! checksum="$(curl -fsSL "$url.sha256")"; then
        tlog_error "$tag" "Failed to download the kubectl checksum: %s" "$url.sha256"

        return 1
    fi

    checksum="${checksum%%[[:space:]]*}"

    if [[ ! "$checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
        tlog_error "$tag" "Invalid kubectl checksum from %s" "$url.sha256"

        return 1
    fi

    stateful_download "$canonical_id" "BINARY_FILE" "$url" "" 1 "$checksum" "$version"
}
