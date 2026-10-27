#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

version="$(module_latest_version "$CANONICAL_ID")" || exit $?
url="https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${version}/apache-maven-${version}-bin.tar.gz"

stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz" 1 "" "$version"
