#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_DESKTOP_INTEGRATION_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_DESKTOP_INTEGRATION_LOADED=1

source "$LIB_COMMON/common.sh"

##
# desktop_application_dir
#
# Resolves the system-wide directory for desktop entries.
#
# Output:
#   Prints the desktop application directory to standard output.
#
desktop_application_dir() {
    printf '%s\n' '/usr/share/applications'
}

##
# desktop_icon_theme_dir
#
# Resolves the system-wide icon theme directory used for application icons.
#
# Output:
#   Prints the icon theme directory to standard output.
#
desktop_icon_theme_dir() {
    printf '%s\n' '/usr/share/icons/hicolor'
}

##
# desktop_entry_path
#
# Resolves the system-wide path of a desktop entry.
#
# Parameters:
#   desktop_id - Desktop entry file name without the .desktop extension.
#
# Output:
#   Prints the desktop entry path to standard output.
#
desktop_entry_path() {
    local desktop_id="$1"

    printf '%s/%s.desktop\n' "$(desktop_application_dir)" "$desktop_id"
}

__desktop_parse_options() {
    local tag="$1"
    local options_name="$2"
    local actions_name="$3"
    shift 3

    local -n options_ref="$options_name"
    local -n actions_ref="$actions_name"
    local option
    local key

    while (( $# > 0 )); do
        option="$1"

        case "$option" in
            --exec-args | --try-exec | --generic-name | --comment | --categories | --keywords | --mime-type | \
                --startup-wm-class | --terminal | --startup-notify | --icon | --icon-file | --icon-size | --action)
                ;;
            *)
                tlog_error "$tag" "Unsupported desktop entry option: %s" "$option"

                return 1
                ;;
        esac

        if (( $# < 2 )); then
            tlog_error "$tag" "Missing value for desktop entry option: %s" "$option"

            return 1
        fi

        if [[ "$2" == *$'\n'* ]]; then
            tlog_error "$tag" "Desktop entry option value must be a single line: %s" "$option"

            return 1
        fi

        if [[ "$option" == "--action" ]]; then
            actions_ref+=("$2")
        else
            key="${option#--}"
            key="${key//-/_}"
            options_ref["${key^^}"]="$2"
        fi

        shift 2
    done
}

__desktop_validate_options() {
    local tag="$1"
    local options_name="$2"
    local -n options_ref="$options_name"
    local key

    for key in TERMINAL STARTUP_NOTIFY; do
        if [[ -n "${options_ref[$key]:-}" && ! "${options_ref[$key]}" =~ ^[01]$ ]]; then
            tlog_error "$tag" "Desktop entry option --%s accepts only 0 or 1" "${key,,}"

            return 1
        fi
    done

    if [[ -n "${options_ref[ICON]:-}" && -n "${options_ref[ICON_FILE]:-}" ]]; then
        tlog_error "$tag" "Desktop entry options --icon and --icon-file are mutually exclusive"

        return 1
    fi

    if [[ -n "${options_ref[ICON_SIZE]:-}" && -z "${options_ref[ICON_FILE]:-}" ]]; then
        tlog_error "$tag" "Desktop entry option --icon-size requires --icon-file"

        return 1
    fi

    if [[ -z "${options_ref[ICON_FILE]:-}" ]]; then
        return 0
    fi

    if [[ ! -f "${options_ref[ICON_FILE]}" ]]; then
        tlog_error "$tag" "Application icon not found: %s" "${options_ref[ICON_FILE]}"

        return 1
    fi

    if [[ -z "${options_ref[ICON_SIZE]:-}" && "${options_ref[ICON_FILE],,}" != *.svg ]]; then
        tlog_error "$tag" "Desktop entry option --icon-size is required for non-SVG icon: %s" "${options_ref[ICON_FILE]}"

        return 1
    fi
}

__desktop_validate_executable() {
    local tag="$1"
    local executable="$2"

    if [[ "$executable" == /* ]]; then
        if [[ ! -x "$executable" ]]; then
            tlog_error "$tag" "Application executable not found or not executable: %s" "$executable"

            return 1
        fi

        return 0
    fi

    if ! command -v "$executable" >/dev/null 2>&1; then
        tlog_error "$tag" "Application executable not found in PATH: %s" "$executable"

        return 1
    fi
}

##
# __desktop_quote_exec <tag> <executable>
#
# Quotes an executable for the desktop entry Exec key when it contains reserved characters.
#
# Output:
#   Prints the Exec-safe executable to standard output.
#
# Return:
#   1 when the executable contains characters that cannot be quoted safely.
#
__desktop_quote_exec() {
    local tag="$1"
    local executable="$2"
    local reserved_pattern="[[:space:]'><~|&;*?#()]"

    if [[ "$executable" == *[\"\`\$\\]* ]]; then
        tlog_error "$tag" "Application executable contains unsupported characters: %s" "$executable"

        return 1
    fi

    executable="${executable//%/%%}"
    if [[ "$executable" =~ $reserved_pattern ]]; then
        printf '"%s"\n' "$executable"

        return 0
    fi

    printf '%s\n' "$executable"
}

__desktop_icon_target() {
    local desktop_id="$1"
    local icon_file="$2"
    local icon_size="${3:-scalable}"
    local extension="${icon_file##*.}"

    printf '%s/%s/apps/%s.%s\n' "$(desktop_icon_theme_dir)" "$icon_size" "$desktop_id" "${extension,,}"
}

__desktop_append_key() {
    local content_name="$1"
    local key="$2"
    local value="$3"
    local -n content_ref="$content_name"

    if [[ -n "$value" ]]; then
        content_ref+="$key=$value"$'\n'
    fi
}

__desktop_render_actions() {
    local tag="$1"
    local exec_value="$2"
    local content_name="$3"
    shift 3

    local -n content_ref="$content_name"
    local action
    local action_id
    local action_name
    local action_args
    local action_ids=""
    local sections=""

    for action in "$@"; do
        IFS='|' read -r action_id action_name action_args <<< "$action" || true

        if [[ ! "$action_id" =~ ^[A-Za-z0-9-]+$ || -z "$action_name" ]]; then
            tlog_error "$tag" "Invalid desktop action, expected 'Id|Name|Exec arguments': %s" "$action"

            return 1
        fi

        action_ids+="$action_id;"
        sections+=$'\n'"[Desktop Action $action_id]"$'\n'"Name=$action_name"$'\n'
        sections+="Exec=$exec_value${action_args:+ $action_args}"$'\n'
    done

    __desktop_append_key "$content_name" "Actions" "$action_ids"
    content_ref+="$sections"
}

__desktop_refresh_caches() {
    local tag="$1"
    local icon_installed="$2"

    if (( icon_installed )) && command -v gtk-update-icon-cache >/dev/null 2>&1; then
        if ! sudo gtk-update-icon-cache -f -t "$(desktop_icon_theme_dir)"; then
            tlog_warn "$tag" "Failed to refresh the icon cache"
        fi
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        if ! sudo update-desktop-database "$(desktop_application_dir)"; then
            tlog_warn "$tag" "Failed to refresh the desktop application database"
        fi
    fi
}

__desktop_write_entry() {
    local tag="$1"
    local content="$2"
    local desktop_file="$3"
    local temp_file
    local status=0

    if ! temp_file="$(mktemp --suffix=.desktop)"; then
        tlog_error "$tag" "Failed to create a temporary desktop file"

        return 1
    fi

    if ! printf '%s' "$content" > "$temp_file"; then
        tlog_error "$tag" "Failed to render desktop file: %s" "$temp_file"
        rm -f -- "$temp_file"

        return 1
    fi

    if command -v desktop-file-validate >/dev/null 2>&1; then
        if ! desktop-file-validate "$temp_file"; then
            tlog_warn "$tag" "Desktop file validation reported issues: %s" "$desktop_file"
        fi
    fi

    if ! sudo install -Dm0644 "$temp_file" "$desktop_file"; then
        tlog_error "$tag" "Failed to install desktop file: %s" "$desktop_file"
        status=1
    fi

    rm -f -- "$temp_file"

    return "$status"
}

##
# install_desktop_entry
#
# Generates and installs a system-wide desktop entry, optionally installing its icon into the icon theme,
# then refreshes the icon cache and desktop application database.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   desktop_id - Desktop entry file name without the .desktop extension; also the installed icon name.
#   name - Application display name.
#   executable - Absolute executable path, or a command name available in PATH.
#   options - Optional "--key value" pairs:
#     --exec-args <args>          Arguments appended to Exec, such as %U, %F, or %f.
#     --try-exec <path>           TryExec value.
#     --generic-name <text>       GenericName value.
#     --comment <text>            Comment value.
#     --categories <list>         Categories value, such as "Development;IDE;".
#     --keywords <list>           Keywords value.
#     --mime-type <list>          MimeType value.
#     --startup-wm-class <class>  StartupWMClass value.
#     --terminal <0|1>            Terminal value; defaults to 0.
#     --startup-notify <0|1>      StartupNotify value; omitted by default.
#     --icon <name|path>          Icon value used as-is.
#     --icon-file <file>          Icon installed into the icon theme as <desktop_id>; excludes --icon.
#     --icon-size <size>          Icon theme size, such as 512x512; SVG icons default to scalable.
#     --action <Id|Name|args>     Desktop action; repeatable.
#
# Return:
#   0 - The desktop entry was installed.
#   1 - Validation or installation failed.
#
install_desktop_entry() {
    local canonical_id="${1:-}"
    local desktop_id="${2:-}"
    local name="${3:-}"
    local executable="${4:-}"
    local tag="desktop:$canonical_id"
    local desktop_file
    local exec_value
    local icon_value
    local icon_target
    local icon_installed=0
    local content=""
    local actions_content=""
    local -A options=()
    local -a actions=()

    if [[ -z "$canonical_id" || -z "$desktop_id" || -z "$name" || -z "$executable" ]]; then
        tlog_error "$tag" "Usage: install_desktop_entry <canonical_id> <desktop_id> <name> <executable> [options]"

        return 1
    fi

    if [[ ! "$desktop_id" =~ ^[A-Za-z0-9._-]+$ ]]; then
        tlog_error "$tag" "Invalid desktop entry ID: %s" "$desktop_id"

        return 1
    fi

    shift 4
    __desktop_parse_options "$tag" options actions "$@" || return $?
    __desktop_validate_options "$tag" options || return $?
    __desktop_validate_executable "$tag" "$executable" || return $?
    exec_value="$(__desktop_quote_exec "$tag" "$executable")" || return $?
    __desktop_render_actions "$tag" "$exec_value" actions_content "${actions[@]}" || return $?
    desktop_file="$(desktop_entry_path "$desktop_id")"
    icon_value="${options[ICON]:-}"

    tlog_info "$tag" "Installing desktop entry: %s" "$desktop_file"
    if [[ -n "${options[ICON_FILE]:-}" ]]; then
        icon_target="$(__desktop_icon_target "$desktop_id" "${options[ICON_FILE]}" "${options[ICON_SIZE]:-}")"
        if ! sudo install -Dm0644 "${options[ICON_FILE]}" "$icon_target"; then
            tlog_error "$tag" "Failed to install the application icon: %s" "$icon_target"

            return 1
        fi

        icon_value="$desktop_id"
        icon_installed=1
    fi

    content+="[Desktop Entry]"$'\n'
    content+="Type=Application"$'\n'
    content+="Version=1.0"$'\n'
    content+="Name=$name"$'\n'
    __desktop_append_key content "GenericName" "${options[GENERIC_NAME]:-}"
    __desktop_append_key content "Comment" "${options[COMMENT]:-}"
    content+="Exec=$exec_value${options[EXEC_ARGS]:+ ${options[EXEC_ARGS]}}"$'\n'
    __desktop_append_key content "TryExec" "${options[TRY_EXEC]:-}"
    __desktop_append_key content "Icon" "$icon_value"

    if (( ${options[TERMINAL]:-0} )); then
        content+="Terminal=true"$'\n'
    else
        content+="Terminal=false"$'\n'
    fi

    if [[ -n "${options[STARTUP_NOTIFY]:-}" ]]; then
        if (( options[STARTUP_NOTIFY] )); then
            content+="StartupNotify=true"$'\n'
        else
            content+="StartupNotify=false"$'\n'
        fi
    fi

    __desktop_append_key content "StartupWMClass" "${options[STARTUP_WM_CLASS]:-}"
    __desktop_append_key content "Categories" "${options[CATEGORIES]:-}"
    __desktop_append_key content "Keywords" "${options[KEYWORDS]:-}"
    __desktop_append_key content "MimeType" "${options[MIME_TYPE]:-}"
    content+="$actions_content"

    __desktop_write_entry "$tag" "$content" "$desktop_file" || return $?
    __desktop_refresh_caches "$tag" "$icon_installed"
    tlog_info "$tag" "Desktop entry installed: %s" "$desktop_file"
}
