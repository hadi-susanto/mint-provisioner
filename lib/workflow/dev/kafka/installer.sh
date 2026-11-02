#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_KAFKA_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_KAFKA_INSTALLER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

##
# __kafka_sed_escape <value>
#
# Escapes characters special to a sed replacement string using | as delimiter.
#
# Output:
#   Prints the escaped value.
#
__kafka_sed_escape() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//&/\\&}"
    value="${value//|/\\|}"
    printf '%s\n' "$value"
}

##
# kafka_download_archive <canonical_id> <version>
#
# Downloads the Kafka binary archive (Scala 2.13 build) into the ARCHIVE_FILE
# state and verifies it against the SHA-512 checksum published by Apache. The
# version is stored in the VERSION state.
#
# Parameters:
#   canonical_id - Canonical module ID used for state and logging.
#   version - Kafka release version, such as 4.4.0.
#
# Return:
#   1 - The download, checksum lookup, or state update failed.
#   3 - The checksum did not match; the downloaded file is deleted.
#
kafka_download_archive() {
    local canonical_id="$1"
    local version="$2"
    local tag="checksum:$canonical_id"
    local file_name="kafka_2.13-${version}.tgz"
    local url="https://dlcdn.apache.org/kafka/${version}/${file_name}"
    local sums_url="https://downloads.apache.org/kafka/${version}/${file_name}.sha512"
    local sums
    local expected_sha512
    local actual_sha512
    local archive_file

    # Apache publishes SHA-512 only, so stateful_download skips its SHA-256 check.
    stateful_download "$canonical_id" "ARCHIVE_FILE" "$url" ".tgz" 1 "" "$version" || return $?
    archive_file="$(get_state "ARCHIVE_FILE")" || return $?

    if ! sums="$(curl -fsSL "$sums_url")"; then
        tlog_error "$tag" "Failed to download the checksum: %s" "$sums_url"
        rm -f -- "$archive_file" || true

        return 1
    fi

    # Format: "<file>: HEX HEX ..." in uppercase, wrapped over several lines.
    expected_sha512="${sums#*:}"
    expected_sha512="${expected_sha512//[[:space:]]/}"
    expected_sha512="${expected_sha512,,}"
    if [[ ! "$expected_sha512" =~ ^[0-9a-f]{128}$ ]]; then
        tlog_error "$tag" "Invalid SHA-512 checksum in %s" "$sums_url"
        rm -f -- "$archive_file" || true

        return 1
    fi

    if ! actual_sha512="$(sha512sum -- "$archive_file")"; then
        tlog_error "$tag" "Failed to compute the SHA-512 checksum of %s" "$archive_file"
        rm -f -- "$archive_file" || true

        return 1
    fi

    actual_sha512="${actual_sha512%% *}"
    if [[ "$actual_sha512" != "$expected_sha512" ]]; then
        tlog_error "$tag" "Checksum mismatch for %s" "$file_name"
        tlog_error "$tag" "Expected: %s" "$expected_sha512"
        tlog_error "$tag" "Actual:   %s" "$actual_sha512"
        rm -f -- "$archive_file" || true

        return 3
    fi

    tlog_info "$tag" "SHA-512 checksum verified"
}

##
# kafka_configure_log_dirs <canonical_id> <install_path>
#
# Points log.dirs in config/server.properties to
# <install_path>/kraft-combined-logs.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   install_path - Kafka installation directory.
#
# Return:
#   1 - The configuration file or its log.dirs entry is missing, or the
#       update failed.
#
kafka_configure_log_dirs() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="configure:$canonical_id"
    local config_file="$install_path/config/server.properties"
    local log_dirs="$install_path/kraft-combined-logs"
    local escaped_log_dirs

    if [[ ! -f "$config_file" ]]; then
        tlog_error "$tag" "Kafka configuration not found: %s" "$config_file"

        return 1
    fi

    if ! grep -q '^log\.dirs=' "$config_file"; then
        tlog_error "$tag" "No log.dirs entry in %s" "$config_file"

        return 1
    fi

    escaped_log_dirs="$(__kafka_sed_escape "$log_dirs")"
    if ! sed -i "s|^log\.dirs=.*|log.dirs=$escaped_log_dirs|" "$config_file"; then
        tlog_error "$tag" "Failed to update log.dirs in %s" "$config_file"

        return 1
    fi

    tlog_info "$tag" "Kafka log.dirs set to: %s" "$log_dirs"
}

##
# kafka_install_wrappers <canonical_id> <install_path>
#
# Installs the kafka-server and kafka-initialize wrappers into install_path,
# pointing them at that installation.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the wrapper payloads.
#   install_path - Kafka installation directory.
#
# Return:
#   1 - A wrapper could not be installed or configured.
#
kafka_install_wrappers() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="exec-wrapper:$canonical_id"
    local escaped_install_path
    local wrapper
    local wrapper_file

    escaped_install_path="$(__kafka_sed_escape "$install_path")"

    for wrapper in kafka-server kafka-initialize; do
        wrapper_file="$install_path/$wrapper"

        if ! install -m 755 "$MP_MODULES/$canonical_id/payload/$wrapper" "$wrapper_file"; then
            tlog_error "$tag" "Failed to install wrapper to %s" "$wrapper_file"

            return 1
        fi

        if ! sed -i "s|KAFKA_INSTALL_PATH|$escaped_install_path|g" "$wrapper_file"; then
            tlog_error "$tag" "Failed to configure wrapper %s" "$wrapper_file"

            return 1
        fi
    done
}
