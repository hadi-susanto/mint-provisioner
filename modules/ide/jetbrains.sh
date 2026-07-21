#!/usr/bin/env bash

if (( ${__JETBRAINS_MODULE_LIB_LOADED:-0} )); then
    return 0
fi

readonly __JETBRAINS_MODULE_LIB_LOADED=1

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/sudo_refresher.sh"

__jetbrains_cleanup_downloads() {
    local file

    for file in "$@"; do
        if [[ -n "$file" && -f "$file" ]]; then
            rm -f "$file"
        fi
    done
}

##
# __jetbrains_download_artifact <canonical_id> <download_url> <output_file>
#
# Downloads a JetBrains installation artifact with four aria2 connections
# when aria2c is available, otherwise using the framework downloader.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#   download_url    URL to download.
#   output_file     Destination file path.
#
# Returns:
#   1 when required arguments are missing; 2 when the download fails.
#
__jetbrains_download_artifact() {
    local canonical_id="${1:-}"
    local download_url="${2:-}"
    local output_file="${3:-}"
    local output_dir
    local output_name
    local control_file

    if [[ -z "$canonical_id" || -z "$download_url" || -z "$output_file" ]]; then
        log_error "[download_artifacts] [$canonical_id] Missing required arguments"

        return 1
    fi

    if ! command -v aria2c >/dev/null 2>&1; then
        download_file "$canonical_id" "$download_url" "$output_file"

        return $?
    fi

    output_dir="$(dirname -- "$output_file")"
    output_name="${output_file##*/}"
    control_file="${output_file}.aria2"

    log_info "[download_artifacts] [$canonical_id] Using aria2c with 4 concurrent connections"
    log_info "[download_artifacts] [$canonical_id] Source: $download_url"
    log_info "[download_artifacts] [$canonical_id] Destination: $output_file"

    if ! aria2c \
        --allow-overwrite=true \
        --auto-file-renaming=false \
        --max-connection-per-server=4 \
        --split=4 \
        --dir="$output_dir" \
        --out="$output_name" \
        "$download_url"
    then
        log_error \
            "[download_artifacts] [$canonical_id] '$download_url' download failed"
        rm -f "$control_file"

        return 2
    fi

    log_info "[download_artifacts] [$canonical_id] '$download_url' downloaded"

    return 0
}

##
# jetbrains_load_product <canonical_id> <result_name>
#
# Resolves shared JetBrains product metadata for a module.
#
# Parameters:
#   canonical_id    Module canonical ID.
#   result_name     Caller-provided associative array receiving product data.
#
# Returns:
#   1 when the canonical ID is unsupported.
#
jetbrains_load_product() {
    local canonical_id="${1:-}"
    local result_name="${2:-}"

    declare -n result_ref="$result_name"
    result_ref=()

    case "$canonical_id" in
        ide/idea)
            result_ref[NAME]="idea"
            result_ref[DISPLAY_NAME]="IntelliJ IDEA"
            result_ref[RELEASE_CODE]="IIU"
            result_ref[KEYWORD]="Java;Kotlin;JVM;Spring"
            ;;
        ide/pycharm)
            result_ref[NAME]="pycharm"
            result_ref[DISPLAY_NAME]="PyCharm"
            result_ref[RELEASE_CODE]="PCP"
            result_ref[KEYWORD]="Python;Django;Jupyter"
            ;;
        ide/clion)
            result_ref[NAME]="clion"
            result_ref[DISPLAY_NAME]="CLion"
            result_ref[RELEASE_CODE]="CL"
            result_ref[KEYWORD]="C;C++;CMake;Embedded"
            ;;
        ide/rustrover)
            result_ref[NAME]="rustrover"
            result_ref[DISPLAY_NAME]="RustRover"
            result_ref[RELEASE_CODE]="RR"
            result_ref[KEYWORD]="Rust;Cargo"
            ;;
        ide/goland)
            result_ref[NAME]="goland"
            result_ref[DISPLAY_NAME]="GoLand"
            result_ref[RELEASE_CODE]="GO"
            result_ref[KEYWORD]="Go;Golang"
            ;;
        ide/phpstorm)
            result_ref[NAME]="phpstorm"
            result_ref[DISPLAY_NAME]="PhpStorm"
            result_ref[RELEASE_CODE]="PS"
            result_ref[KEYWORD]="PHP;Web"
            ;;
        ide/webstorm)
            result_ref[NAME]="webstorm"
            result_ref[DISPLAY_NAME]="WebStorm"
            result_ref[RELEASE_CODE]="WS"
            result_ref[KEYWORD]="JavaScript;TypeScript;Web"
            ;;
        ide/rider)
            result_ref[NAME]="rider"
            result_ref[DISPLAY_NAME]="Rider"
            result_ref[RELEASE_CODE]="RD"
            result_ref[KEYWORD]=".NET;C#;Unity"
            ;;
        ide/rubymine)
            result_ref[NAME]="rubymine"
            result_ref[DISPLAY_NAME]="RubyMine"
            result_ref[RELEASE_CODE]="RM"
            result_ref[KEYWORD]="Ruby;Rails"
            ;;
        ide/datagrip)
            result_ref[NAME]="datagrip"
            result_ref[DISPLAY_NAME]="DataGrip"
            result_ref[RELEASE_CODE]="DG"
            result_ref[KEYWORD]="Database;SQL"
            ;;
        *)
            log_error "[jetbrains] Unsupported JetBrains module: ${canonical_id:-unset}"

            return 1
            ;;
    esac

    return 0
}

##
# jetbrains_resolve_auto_install_jq <canonical_id> <value>
#
# Validates and normalizes the configured jq installation authorization.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#   value           Expected true or false value.
#
# Output:
#   Prints the normalized value.
#
# Returns:
#   1 when the value is not true or false.
#
jetbrains_resolve_auto_install_jq() {
    local canonical_id="${1:-}"
    local auto_install_jq="${2:-}"

    auto_install_jq="${auto_install_jq,,}"

    case "$auto_install_jq" in
        true | false)
            log_info "[$canonical_id] Automatically install jq when missing: $auto_install_jq"
            printf '%s\n' "$auto_install_jq"
            ;;
        *)
            log_error \
                "[$canonical_id] Invalid JETBRAINS_AUTO_INSTALL_JQ value: ${2:-empty}. Expected true or false."

            return 1
            ;;
    esac
}

##
# jetbrains_resolve_auto_install_aria2 <canonical_id> <value>
#
# Validates and normalizes the configured aria2 installation authorization.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#   value           Expected true or false value.
#
# Output:
#   Prints the normalized value.
#
# Returns:
#   1 when the value is not true or false.
#
jetbrains_resolve_auto_install_aria2() {
    local canonical_id="${1:-}"
    local auto_install_aria2="${2:-}"

    auto_install_aria2="${auto_install_aria2,,}"

    case "$auto_install_aria2" in
        true | false)
            log_info "[$canonical_id] Automatically install aria2 when missing: $auto_install_aria2"
            printf '%s\n' "$auto_install_aria2"
            ;;
        *)
            log_error \
                "[$canonical_id] Invalid JETBRAINS_AUTO_INSTALL_ARIA2 value: ${2:-empty}. Expected true or false."

            return 1
            ;;
    esac
}

##
# jetbrains_prompt_auto_install_jq <canonical_id>
#
# Asks whether Mint Provisioner may install jq when it is missing.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#
# Output:
#   Prints true when authorized or false when denied.
#
# Returns:
#   Non-zero when prompting fails or returns an unexpected selection.
#
jetbrains_prompt_auto_install_jq() {
    local canonical_id="${1:-}"
    local selected_index

    source "${LIB_DIR}/prompt.sh"

    selected_index="$(
        choose_option \
            "jq is required to read JetBrains release metadata. May Mint Provisioner install jq automatically if it is missing?" \
            "Yes, install jq when required" \
            "No, do not install jq"
    )" || return $?

    case "$selected_index" in
        0)
            jetbrains_resolve_auto_install_jq "$canonical_id" "true"
            ;;
        1)
            jetbrains_resolve_auto_install_jq "$canonical_id" "false"
            ;;
        *)
            log_error \
                "[$canonical_id] Unexpected jq installation selection index: $selected_index"

            return 1
            ;;
    esac
}

##
# jetbrains_prompt_auto_install_aria2 <canonical_id>
#
# Asks whether Mint Provisioner may install aria2 when it is missing.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#
# Output:
#   Prints true when authorized or false when denied.
#
# Returns:
#   Non-zero when prompting fails or returns an unexpected selection.
#
jetbrains_prompt_auto_install_aria2() {
    local canonical_id="${1:-}"
    local selected_index

    source "${LIB_DIR}/prompt.sh"

    selected_index="$(
        choose_option \
            "aria2 can accelerate JetBrains archive downloads. May Mint Provisioner install aria2 automatically if it is missing?" \
            "Yes, install aria2 when required" \
            "No, use the standard downloader"
    )" || return $?

    case "$selected_index" in
        0)
            jetbrains_resolve_auto_install_aria2 "$canonical_id" "true"
            ;;
        1)
            jetbrains_resolve_auto_install_aria2 "$canonical_id" "false"
            ;;
        *)
            log_error \
                "[$canonical_id] Unexpected aria2 installation selection index: $selected_index"

            return 1
            ;;
    esac
}

##
# jetbrains_auto_install_jq <canonical_id> <auto_install_jq>
#
# Ensures jq is available, installing it only when permission was granted.
#
# Parameters:
#   canonical_id       Module canonical ID used for logging.
#   auto_install_jq    true when automatic installation is authorized.
#
# Returns:
#   Non-zero when jq is unavailable, permission was denied, or installation
#   fails.
#
jetbrains_auto_install_jq() {
    local canonical_id="${1:-}"
    local auto_install_jq="${2:-}"

    if command -v jq >/dev/null 2>&1; then
        log_info "[$canonical_id] jq is already available"

        return 0
    fi

    if [[ "$auto_install_jq" != "true" ]]; then
        log_error \
            "[$canonical_id] jq is required and automatic installation was not authorized"

        return 1
    fi

    log_info "[$canonical_id] Installing required dependency: jq"

    if ! apt_install jq; then
        log_error "[$canonical_id] Failed to install required dependency: jq"

        return 2
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "[$canonical_id] jq is unavailable after dependency preparation"

        return 3
    fi

    return 0
}

##
# jetbrains_auto_install_aria2 <canonical_id> <auto_install_aria2>
#
# Ensures aria2c is available when automatic installation was authorized.
#
# Parameters:
#   canonical_id          Module canonical ID used for logging.
#   auto_install_aria2    true when automatic installation is authorized.
#
# Returns:
#   Non-zero when an authorized aria2 installation fails or does not provide
#   aria2c.
#
jetbrains_auto_install_aria2() {
    local canonical_id="${1:-}"
    local auto_install_aria2="${2:-}"

    if command -v aria2c >/dev/null 2>&1; then
        log_info "[$canonical_id] aria2c is already available"

        return 0
    fi

    if [[ "$auto_install_aria2" != "true" ]]; then
        log_info \
            "[$canonical_id] aria2 installation was not authorized; using the standard downloader"

        return 0
    fi

    log_info "[$canonical_id] Installing optional download accelerator: aria2"

    if ! apt_install aria2; then
        log_error "[$canonical_id] Failed to install optional download accelerator: aria2"

        return 1
    fi

    if ! command -v aria2c >/dev/null 2>&1; then
        log_error "[$canonical_id] aria2c is unavailable after dependency preparation"

        return 2
    fi

    return 0
}

##
# jetbrains_is_installed <name>
#
# Checks whether a module-named JetBrains wrapper is available on PATH.
#
# Parameters:
#   name    Module name and wrapper command.
#
# Returns:
#   0 when the wrapper is available; 1 otherwise.
#
jetbrains_is_installed() {
    local name="${1:-}"

    command -v "$name" >/dev/null 2>&1
}

##
# jetbrains_extract_metadata <canonical_id> <release_code> <result_name>
#
# Downloads official JetBrains release metadata and extracts the latest Linux
# artifact information.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging and downloads.
#   release_code    JetBrains release metadata product identifier.
#   result_name     Caller-provided associative array receiving DOWNLOAD_URL,
#                   CHECKSUM_URL, and VERSION.
#
# Returns:
#   Non-zero when metadata cannot be downloaded or parsed.
#
jetbrains_extract_metadata() {
    local canonical_id="${1:-}"
    local release_code="${2:-}"
    local result_name="${3:-}"
    local metadata_file=""
    local metadata_url
    local release_data
    local download_url
    local checksum_url
    local version

    declare -n result_ref="$result_name"
    result_ref=()

    metadata_url="https://data.services.jetbrains.com/products/releases?code=${release_code}&latest=true&type=release"

    metadata_file="$(mktemp --suffix=.json)" || {
        log_error "[extract_metadata] [$canonical_id] Failed to create metadata temporary file"

        return 1
    }
    
    log_info "[extract_metadata] [$canonical_id] Downloading $metadata_url"

    if ! download_file "$canonical_id" "$metadata_url" "$metadata_file"; then
        log_error "[extract_metadata] [$canonical_id] Failed to download JetBrains release metadata"
        __jetbrains_cleanup_downloads "$metadata_file"

        return 2
    fi

    if ! release_data="$(
        jq -er \
            --arg code "$release_code" \
            '.[$code][0] as $release
             | [$release.downloads.linux.link,
                $release.downloads.linux.checksumLink,
                $release.version]
             | if all(.[]; type == "string" and length > 0)
               then @tsv
               else error("release download metadata is incomplete")
               end' \
            "$metadata_file"
    )"; then
        log_error "[extract_metadata] [$canonical_id] Failed to resolve the latest JetBrains Linux release"
        __jetbrains_cleanup_downloads "$metadata_file"

        return 3
    fi

    __jetbrains_cleanup_downloads "$metadata_file"

    IFS=$'\t' read -r download_url checksum_url version <<< "$release_data"

    result_ref[DOWNLOAD_URL]="$download_url"
    result_ref[CHECKSUM_URL]="$checksum_url"
    result_ref[VERSION]="$version"

    return 0
}

##
# jetbrains_download_artifacts <canonical_id> <download_url> <checksum_url>
#                             <result_name>
#
# Downloads a JetBrains Linux archive and its official checksum, then verifies
# the archive.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging and downloads.
#   download_url    Official Linux archive URL.
#   checksum_url    Official SHA-256 checksum URL.
#   result_name     Caller-provided associative array receiving ARCHIVE_FILE.
#
# Returns:
#   Non-zero when temporary files, downloads, or verification fail.
#
jetbrains_download_artifacts() {
    local canonical_id="${1:-}"
    local download_url="${2:-}"
    local checksum_url="${3:-}"
    local result_name="${4:-}"
    local archive_file=""
    local checksum_file=""
    local expected_checksum
    local actual_checksum
    local sudo_refresh_pid=""
    local download_status=0
    local refresh_stop_status=0

    declare -n result_ref="$result_name"
    result_ref=()

    archive_file="$(mktemp --suffix=.tar.gz)" || {
        log_error "[download_artifacts] [$canonical_id] Failed to create archive temporary file"

        return 1
    }

    checksum_file="$(mktemp --suffix=.sha256)" || {
        log_error "[download_artifacts] [$canonical_id] Failed to create checksum temporary file"
        __jetbrains_cleanup_downloads "$archive_file"

        return 2
    }

    if ! start_sudo_refresher "$canonical_id" sudo_refresh_pid 120; then
        log_error "[download_artifacts] [$canonical_id] Failed to start sudo credential refresh"
        __jetbrains_cleanup_downloads "$archive_file" "$checksum_file"

        return 3
    fi
    
    log_info "[download_artifacts] [$canonical_id] Downloading $download_url"

    __jetbrains_download_artifact \
        "$canonical_id" \
        "$download_url" \
        "$archive_file" || download_status=$?
    stop_sudo_refresher "$canonical_id" "$sudo_refresh_pid" || refresh_stop_status=$?

    if (( download_status != 0 )); then
        log_error "[download_artifacts] [$canonical_id] Failed to download JetBrains installation archive"
        __jetbrains_cleanup_downloads "$archive_file" "$checksum_file"

        return 4
    fi

    if (( refresh_stop_status != 0 )); then
        __jetbrains_cleanup_downloads "$archive_file" "$checksum_file"

        return 5
    fi
    
    log_info "[download_artifacts] [$canonical_id] Downloading $checksum_url"

    if ! download_file "$canonical_id" "$checksum_url" "$checksum_file"; then
        log_error "[download_artifacts] [$canonical_id] Failed to download the official checksum"
        __jetbrains_cleanup_downloads "$archive_file" "$checksum_file"

        return 6
    fi

    expected_checksum="$(awk 'NR == 1 { print $1 }' "$checksum_file")"

    if [[ ! "$expected_checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
        log_error "[download_artifacts] [$canonical_id] Official checksum data is invalid"
        __jetbrains_cleanup_downloads "$archive_file" "$checksum_file"

        return 7
    fi
    
    log_info "[download_artifacts] [$canonical_id] Calculating checksum of $archive_file"

    if ! actual_checksum="$(sha256sum "$archive_file" | awk '{ print $1 }')"; then
        log_error "[download_artifacts] [$canonical_id] Failed to calculate the archive checksum"
        __jetbrains_cleanup_downloads "$archive_file" "$checksum_file"

        return 8
    fi

    if [[ "${actual_checksum,,}" != "${expected_checksum,,}" ]]; then
        log_error "[download_artifacts] [$canonical_id] JetBrains archive checksum verification failed"
        __jetbrains_cleanup_downloads "$archive_file" "$checksum_file"

        return 9
    fi

    log_info "[download_artifacts] [$canonical_id] JetBrains archive checksum verified"
    __jetbrains_cleanup_downloads "$checksum_file"

    result_ref[ARCHIVE_FILE]="$archive_file"

    return 0
}

##
# jetbrains_extract_archive <canonical_id> <install_path> <archive_file_path>
#
# Extracts a verified JetBrains archive into its installation directory.
#
# Parameters:
#   canonical_id         Module canonical ID used for logging.
#   install_path         Final product installation directory.
#   archive_file_path    Verified JetBrains archive path.
#
# Returns:
#   Non-zero when the archive or install path is invalid, or extraction fails.
#
jetbrains_extract_archive() {
    local canonical_id="${1:-}"
    local install_path="${2:-}"
    local archive_file_path="${3:-}"
    local archive_root
    local -a sudo_cmd=()

    if [[ ! -f "$archive_file_path" ]]; then
        log_error "[extract_archive] [$canonical_id] JetBrains archive not found: $archive_file_path"

        return 1
    fi

    if [[ -z "$install_path" || "$install_path" == "/" ]]; then
        log_error "[extract_archive] [$canonical_id] Unsafe installation directory: ${install_path:-empty}"

        return 2
    fi

    if ! can_write "$install_path"; then
        sudo_cmd=(sudo)
    fi

    log_info "[extract_archive] [$canonical_id] Extracting JetBrains archive to $install_path"

    if ! "${sudo_cmd[@]}" mkdir -p "$install_path"; then
        log_error "[extract_archive] [$canonical_id] Failed to create installation directory: $install_path"

        return 3
    fi

    if ! "${sudo_cmd[@]}" tar \
        --overwrite \
        -xzf "$archive_file_path" \
        -C "$install_path" \
        --strip-components=1
    then
        log_error "[extract_archive] [$canonical_id] Failed to extract the JetBrains archive"

        return 4
    fi

    log_info "[extract_archive] [$canonical_id] $archive_file_path extraction done"

    return 0
}

##
# jetbrains_integrate_cli <canonical_id> <install_path> <name>
#
# Registers the native JetBrains launcher system-wide.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#   install_path    Product installation directory.
#   name            Product name and native launcher filename under bin.
#
# Returns:
#   Non-zero when the native launcher is unavailable or link creation fails.
#
jetbrains_integrate_cli() {
    local canonical_id="${1:-}"
    local install_path="${2:-}"
    local name="${3:-}"
    local launcher_path="${install_path}/bin/${name}"

    log_info "[integrate_cli] [$canonical_id] Registering native JetBrains launcher: $name"

    if ! symlink_binary "$canonical_id" "$launcher_path"; then
        log_error "[integrate_cli] [$canonical_id] Failed to register the native $name launcher"

        return 1
    fi

    log_info "[integrate_cli] [$canonical_id] $name launcher registration done"

    return 0
}

##
# jetbrains_integrate_desktop <canonical_id> <name> <display_name>
#                              <install_path> <keyword>
#
# Installs the product icon and a system-wide desktop entry.
#
# Parameters:
#   canonical_id    Module canonical ID used for logging.
#   name            Product name and native launcher command.
#   display_name    Human-readable product name.
#   install_path    Product installation directory.
#   keyword         Product-specific semicolon-separated desktop keywords.
#
# Returns:
#   Non-zero when the icon or desktop integration fails.
#
jetbrains_integrate_desktop() {
    local canonical_id="${1:-}"
    local name="${2:-}"
    local display_name="${3:-}"
    local install_path="${4:-}"
    local keyword="${5:-}"
    local launcher_link="$(symlink_location)/${name}"
    local icon_source="${install_path}/bin/${name}.svg"
    local icon_theme_dir="/usr/share/icons/hicolor"
    local icon_path="${icon_theme_dir}/scalable/apps/${name}.svg"
    local application_dir="/usr/share/applications"
    local desktop_file="${application_dir}/${name}.desktop"
    
    log_info "[integrate_desktop] [$canonical_id] Begin desktop integration for $display_name"

    if [[ ! -f "$icon_source" ]]; then
        log_error "[integrate_desktop] [$canonical_id] JetBrains application icon not found: $icon_source"

        return 1
    fi

    if ! sudo install -Dm0644 "$icon_source" "$icon_path"; then
        log_error "[integrate_desktop] [$canonical_id] Failed to install the application icon: $icon_path"

        return 2
    fi

    if ! sudo mkdir -p "$application_dir"; then
        log_error "[integrate_desktop] [$canonical_id] Failed to create desktop application directory: $application_dir"

        return 3
    fi

    if ! sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=$display_name
Comment=Develop software with $display_name
Exec=$launcher_link %f
TryExec=$launcher_link
Icon=$name
Terminal=false
StartupNotify=true
Categories=Development;IDE;
Keywords=Development;IDE;Editor;JetBrains;$keyword;
EOF
    then
        log_error "[integrate_desktop] [$canonical_id] Failed to install desktop file: $desktop_file"

        return 4
    fi

    if ! sudo chmod 0644 "$desktop_file"; then
        log_error "[integrate_desktop] [$canonical_id] Failed to set desktop file permissions: $desktop_file"

        return 5
    fi

    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        if ! sudo gtk-update-icon-cache -f -t "$icon_theme_dir"; then
            log_warn "[integrate_desktop] [$canonical_id] Failed to refresh the icon cache"
        fi
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        if ! sudo update-desktop-database "$application_dir"; then
            log_warn "[integrate_desktop] [$canonical_id] Failed to refresh the desktop application database"
        fi
    fi
    
    log_info "[integrate_desktop] [$canonical_id] $display_name desktop integration done"

    return 0
}

##
# jetbrains_cleanup <canonical_id> <archive_file_path>
#
# Removes a downloaded JetBrains archive without accessing module state.
#
# Parameters:
#   canonical_id         Module canonical ID used for logging.
#   archive_file_path    Downloaded archive path, which may be empty.
#
# Returns:
#   Non-zero when an existing archive cannot be removed.
#
jetbrains_cleanup() {
    local canonical_id="${1:-}"
    local archive_file_path="${2:-}"

    if [[ -n "$archive_file_path" && -f "$archive_file_path" ]]; then
        log_info "[cleanup] [$canonical_id] Removing downloaded archive: $archive_file_path"

        if ! rm -f "$archive_file_path"; then
            log_error "[cleanup] [$canonical_id] Failed to remove downloaded archive: $archive_file_path"

            return 1
        fi
    fi

    return 0
}
