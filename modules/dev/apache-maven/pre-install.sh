#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local version
    local url

    valid_install_target "$canonical_id" "$raw_install_path" "APACHE_MAVEN_INSTALL_DIR" || return $?
    version="$(module_latest_version "$canonical_id")" || return $?
    url="https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${version}/apache-maven-${version}-bin.tar.gz"
    stateful_download "$canonical_id" "ARCHIVE_FILE" "$url" ".tar.gz" 1 "" "$version"
}

main "$CANONICAL_ID" "${APACHE_MAVEN_INSTALL_DIR:-$INSTALL_DIR/apache-maven}"
