# Mint Provisioner Agent Guidelines for the `modules` Folder

## Module Contract

- New modules must follow the contract below. Existing modules may be used as references only when they conform to this contract.

  ```text
  modules/<category-name>/<module-name>/
  ├── metadata.conf      # Mandatory: NAME, DESCRIPTION, and SOURCE
  ├── configuration.sh   # Optional: Collect and validate installation choices
  ├── is_installed.sh    # Mandatory: Detect whether the software is installed
  ├── pre_install.sh     # Optional: Configure prerequisites, repositories, or keys
  ├── install.sh         # Mandatory: Perform the core installation
  ├── post_install.sh    # Optional: Apply configuration and customization
  └── cleanup.sh         # Optional: Remove installation-only state or artifacts
  ```

- Only `metadata.conf`, `is_installed.sh`, and `install.sh` are mandatory.
- `configuration.sh` collects, resolves, validates, and stores choices required during installation.
- The top-level `configure.sh` reruns a module's `post_install.sh`; it does not run `configuration.sh`.
- Add `cleanup.sh` when a module creates framework state, downloaded artifacts, temporary files or directories, or installation-only data.
- In module phase scripts such as `pre_install.sh`, `install.sh`, and `post_install.sh`, use `exit` instead of `return` unless the statement is inside a function. The framework executes phase scripts directly.

### Metadata

When creating or updating `metadata.conf`, follow these rules:

- `DESCRIPTION` should be fewer than 100 characters when possible. Describe what the module is best for and its main selling point without listing every feature.
- `SOURCE` must use one of the following lowercase values:
  - `native`: The package is provided by repositories configured by the operating system.
  - `ppa`: The package is provided by a Launchpad PPA.
  - `apt`: The package is provided by a third-party APT repository that is not a Launchpad PPA.
  - `github`: The module downloads an artifact from GitHub or installs the software by cloning a GitHub repository.
  - `external`: The module downloads an artifact directly from a vendor or another non-GitHub source.
- In `modules/README.md` and category documentation, display source names in human-readable form: `Native`, `PPA`, `APT`, `GitHub`, and `External`.

### Module Documentation

- Keep module scripts, `modules/README.md`, and `modules/<category>.md` consistent.
- When adding, removing, or renaming a module:
  - Update the module count and table index in `modules/README.md`.
  - Update the corresponding `modules/<category>.md` file.
  - Add or update the table of contents after the category description, with a correct link to every module in that category.
- When changing a module's behavior, installation source, configuration, or requirements, update the corresponding documentation.

## Installation Detection

`is_installed.sh` must return:

- `0` when the module is installed.
- `1` when the module is not installed.
- Any other value when installation detection encounters an error.

`is_installed.sh` must remain read-only and must not modify the system.

## Canonical ID and Logging

- In module phase scripts, use `$CANONICAL_ID`, which is provided automatically by the framework.
- Use `$CANONICAL_ID` for logging, state management, and messages.

Example:

```bash
log_info "[$CANONICAL_ID] Starting installation"
```

## Module Directory

Use the following expression to resolve the current module directory:

```bash
SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
```

Do not use `$(dirname "$0")`, `${BASH_SOURCE[0]}`, or similar alternatives in module phase scripts.

## Interactive and Non-Interactive Configuration (`configuration.sh`)

- Provide a resolver function for each required or configurable environment variable so invalid values cannot be stored.
- Resolver functions must validate values and store the resolved choices with `set_state`.
- Prefer guard clauses with immediate returns to reduce nesting.
- When non-interactive mode is enabled, resolve all choices from environment variables or defaults, save the states, and exit without loading interactive prompt helpers.
- Use `NON_INTERACTIVE` as the global flag.
- A module-specific non-interactive flag may override the global flag.
- In the example below, `MODULE_NAME` is a placeholder. Replace it with the module's uppercase environment-variable prefix, such as `TERMINATOR_NON_INTERACTIVE` or `TERMINATOR_PROFILE`.

Example:

```bash
__resolve_module_name_xxx() {
    local xxx="${1:-}"

    if [[ -z "$xxx" ]]; then
        log_error \
            "[$CANONICAL_ID] MODULE_NAME_XXX cannot be empty; specify a valid value or remove the environment variable to use automatic configuration"

        return 1
    fi

    case "$xxx" in
        aaa | bbb)
            set_state "MODULE_NAME_XXX" "$xxx"
            log_info "[$CANONICAL_ID] Set MODULE_NAME_XXX to $xxx"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Invalid value '$xxx' for MODULE_NAME_XXX; supported values: aaa, bbb"

            return 1
            ;;
    esac
}

__resolve_module_name_yyy() {
    local yyy="${1:-}"

    if [[ ! "$yyy" =~ ^([1-9]|10)$ ]]; then
        log_error \
            "[$CANONICAL_ID] Invalid value '$yyy' for YYY; expected a number from 1 to 10"

        return 1
    fi

    set_state "MODULE_NAME_YYY" "$yyy"
    log_info "[$CANONICAL_ID] Set MODULE_NAME_YYY to $yyy"
}

# Handle the non-interactive session before loading prompt helpers.
if [[ "${MODULE_NAME_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __resolve_xxx "${MODULE_NAME_XXX:-aaa}" || exit $?
    __resolve_yyy "${MODULE_NAME_YYY:-5}" || exit $?
    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_module_name_xxx() {
    local selected_index

    selected_index="$(
        choose_option \
            "Which option do you want to use?" \
            "first" \
            "second"
    )" || return $?

    case "$selected_index" in
        0)
            __resolve_xxx "aaa"
            ;;
        1)
            __resolve_xxx "bbb"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected option index: $selected_index"

            return 1
            ;;
    esac
}

__ask_module_name_yyy() {
    local yyy

    yyy="$(ask_number "Enter a number" "5" "1" "10")" || return $?
    __resolve_yyy "$yyy"
}

if [[ -n "${MODULE_NAME_XXX:-}" ]]; then
    __resolve_xxx "$MODULE_NAME_XXX" || exit $?
else
    __ask_xxx || exit $?
fi

if [[ -n "${MODULE_NAME_YYY:-}" ]]; then
    __resolve_yyy "$MODULE_NAME_YYY" || exit $?
else
    __ask_yyy || exit $?
fi

save_states "$CANONICAL_ID" || exit $?
```

## PPA Pre-Installation Phase (`pre_install.sh`)

- When the user provides a Launchpad PPA and repository-signing-key information, support both `add_ppa` and `install_asc_key` as shown below.
- Repository-signing-key information should include the ASCII-armored key URL or GPG key ID required by `install_asc_key`.
- If the signing-key information is unavailable, ask the user whether to proceed using only `add_ppa`. Do not make that choice silently.
- Use `add_ppa` for Launchpad PPAs.
- Use `install_asc_key` when configuring a repository with an explicit signing key and repository URL, including third-party APT repositories that are not Launchpad PPAs.

Example for a Launchpad PPA with signing-key information:

```bash
if [[ "${MODULE_NAME_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:user/repo"
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] Configuring PPA with install_asc_key"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xGPG_KEY_ID" \
        "https://ppa.launchpadcontent.net/user/repo/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
```

Example for a Launchpad PPA without explicit signing-key information, after the user confirms:

```bash
log_info "[$CANONICAL_ID] Configuring PPA with add-apt-repository"
add_ppa "$CANONICAL_ID" "ppa:user/repo"
```

Example for a third-party APT repository:

```bash
source "${LIB_DIR}/distro.sh"

log_info "[$CANONICAL_ID] Configuring external APT repository"
install_asc_key \
    "$CANONICAL_ID" \
    "https://example.com/repo.key" \
    "https://example.com/ubuntu" \
    "$(get_ubuntu_codename)" \
    "main"
```

## Binary Installation and Path Management

- Install downloaded binaries and register their commands during `install.sh`.
- Do not defer required symbolic links or PATH registration to `post_install.sh`.
- `post_install.sh` is reserved for optional, rerunnable user configuration such
  as aliases, shell completion, and configuration payloads.

### Single Binary

- Extract or copy the binary into a dedicated subdirectory of `INSTALL_DIR`.

Example:

    PROCS_INSTALL_DIR="${PROCS_INSTALL_DIR:-$INSTALL_DIR/procs}"

- Make the binary executable.
- Use `symlink_binary` from `lib/installer_common.sh` to create its symbolic link.
- Do not call `sudo ln` directly.
- `symlink_binary` validates that the source exists, is a regular file, and is
  executable before creating a link in the directory returned by
  `symlink_location`.

Example for `install.sh`:

```bash
source "${LIB_DIR}/installer_common.sh"

if ! chmod +x "$MODULE_INSTALL_DIR/binary-name"; then
    log_error "[$CANONICAL_ID] Failed to make binary executable"

    exit 1
fi

log_info "[$CANONICAL_ID] Creating symbolic link"

if [[ "$MODULE_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$MODULE_INSTALL_DIR/binary-name"
else
    log_info \
        "[$CANONICAL_ID] Install directory matches symlink location, skipping symbolic link"
fi
```

### Multiple Binaries or Structured Tool Suites

- Extract the complete directory structure into a dedicated subdirectory of
  `INSTALL_DIR`.
- Use `add_to_path` from `lib/installer_common.sh` after extraction succeeds.
- Pass the directory containing the executable files, not necessarily the
  installation root.
- `add_to_path` validates that the directory exists and is not empty.
- It creates a system-wide PATH script under `/etc/profile.d`.

Examples:

```bash
# ADB binaries are stored directly in this directory.
add_to_path "$CANONICAL_ID" "$ADB_INSTALL_DIR"

# Maven executables are stored in its bin directory.
add_to_path "$CANONICAL_ID" "${APACHE_MAVEN_INSTALL_DIR}/bin"
```

Do not create a user configuration script or call `add_bash_source` and
`add_zsh_source` solely to register an installed binary directory.

### Post-Installation Configuration

- When `post_install.sh` exists, source required libraries and declare essential
  module paths before performing the skip check.
- Check the module-specific `*_SKIP_CONFIGURATION` variable, falling back to
  the global `SKIP_CONFIGURATION` variable.
- Exit successfully when configuration is skipped.
- Define the module-specific `*_FORCE_CONFIGURATION` value after the skip check
  when the phase supports overwriting existing configuration.
- All optional operations in `post_install.sh` must respect the skip setting.
- Required installation work, including binary symbolic links and PATH
  registration, must remain in `install.sh` and must not be controlled by
  `SKIP_CONFIGURATION`.
- Use `add_bash_source` and `add_zsh_source` only for existing user-shell
  integration files, such as aliases or completion scripts.

Example:

```bash
source "${LIB_DIR}/installer_common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${MODULE_NAME_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] Skipping configuration as requested"

    exit 0
fi

if [[ -z "${MODULE_NAME_FORCE_CONFIGURATION:-}" ]]; then
    MODULE_NAME_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

copy_to_config_dir \
    "$CANONICAL_ID" \
    "$PAYLOAD_DIR/module-aliases.sh" \
    "MODULE_NAME_FORCE_CONFIGURATION"

add_bash_source \
    "$CANONICAL_ID" \
    "$(get_config_dir)/module-aliases.sh"

add_zsh_source \
    "$CANONICAL_ID" \
    "$(get_config_dir)/module-aliases.sh"
```

`MODULE_NAME` is a placeholder and must be replaced with the module's uppercase
environment-variable prefix.

## GitHub and External Modules

These rules apply to modules that download `.deb` packages or archives such as
`.zip`, `.tar.gz`, and `.txz`.

### Download Phase (`pre_install.sh`)

- Download installation assets during `pre_install.sh`.
- Source `lib/installer_external.sh` and `lib/state.sh`.
- Create temporary download paths with `mktemp`.
- For GitHub releases:
  - Use `github_find_release` to resolve the latest matching asset.
  - Ensure the regular expression identifies exactly one release asset.
  - Use `download_file` to download it.
- For external vendor sources:
  - Resolve the URL using a stable URL or appropriate vendor-specific discovery.
  - Do not use `github_find_release` for non-GitHub sources.
  - Use `download_file` for the actual download.
- Delete the temporary file when URL resolution or downloading fails.
- Store the downloaded path with `set_state`.
- Save the state with `save_states`.

Example for a GitHub release:

```bash
source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/state.sh"

if ! download_file="$(mktemp --suffix=.tar.gz)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        "$OWNER" \
        "$REPO" \
        "$REGEX"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"
    rm -f "$download_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_file"; then
    log_error "[$CANONICAL_ID] Download failed"
    rm -f "$download_file"

    exit 3
fi

set_state "ARCHIVE_FILE" "$download_file"
save_states "$CANONICAL_ID" || exit 4
```

### Installation Phase (`install.sh`)

- Source `lib/state.sh`.
- Load the saved state with `load_states`.
- Retrieve the downloaded path with `get_state`.
- Verify that the downloaded file exists before using it.
- Install or extract the asset into its final destination.
- Perform required symbolic-link or PATH registration in this phase.

For `.deb` packages:

- Source `lib/installer_apt.sh`.
- Call `apt_install` with the absolute path to the downloaded package.

Example:

```bash
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
DEB_FILE="$(get_state "DEB_FILE")" || exit 1

if [[ ! -f "$DEB_FILE" ]]; then
    log_error "[$CANONICAL_ID] Package file not found: $DEB_FILE"

    exit 2
fi

apt_install "$DEB_FILE"
```

For archives containing a single primary binary:

- Extract into a dedicated subdirectory of `INSTALL_DIR`.
- Make the binary executable.
- Register it with `symlink_binary`.

For archives containing multiple binaries or a required directory structure:

- Extract into a dedicated subdirectory of `INSTALL_DIR`.
- Register the appropriate executable directory with `add_to_path`.

### Cleanup Phase (`cleanup.sh`)

- Modules that download temporary assets and save their paths must provide
  `cleanup.sh`.
- Load the module state.
- Remove the downloaded temporary file when it exists.
- Delete the module state after cleanup.
- Missing state should produce a warning and exit successfully.

## GUI Desktop Entry Management

- When creating or modifying a GUI module, determine whether its installation
  source already provides a `.desktop` file.

### Package-Managed Installations

- When installing from a `.deb` package, assume the package already provides
  its desktop entry, application icon, and menu integration.
- Do not create or overwrite a desktop entry for a `.deb` installation unless:
  - The user explicitly requests one.
  - The package is known not to provide one.
  - The provided desktop entry is unusable for the framework's installation.
- Apply the same default assumption to GUI applications installed from a
  distribution or third-party APT repository.

### Archive, Binary, and Source Installations

- For GUI modules installed from an archive, standalone binary, cloned
  repository, or another manual source, do not assume that desktop integration
  is provided.
- If the user did not specify whether a desktop entry is required, ask whether
  Mint Provisioner should create one.
- Do not silently create or omit the desktop entry.
- If the user confirms, create the desktop entry during `install.sh`.
- Desktop-entry creation is part of installing the GUI application. It must not
  be placed in `post_install.sh` or controlled by `SKIP_CONFIGURATION`.

### Desktop Entry Installation

- Install system-wide desktop entries under:

  `/usr/share/applications/<module-name>.desktop`

- Ensure the parent directory exists.
- Use `0644` permissions for the installed desktop file.
- Ensure `Exec` refers to an installed executable or launcher.
- Use `TryExec` when it provides useful validation that the launcher exists.
- Ensure `Terminal` is set appropriately for the application.
- Include appropriate `Categories` and, when useful, `Keywords`,
  `StartupWMClass`, `MimeType`, or desktop actions.
- Do not use an unverified executable or icon path.

Example:

```bash
APPLICATION_DIR="/usr/share/applications"
DESKTOP_FILE="${APPLICATION_DIR}/module-name.desktop"
EXEC_PATH="/usr/local/bin/module-name"

if [[ ! -x "$EXEC_PATH" ]]; then
    log_error "[$CANONICAL_ID] Application launcher not found or not executable: $EXEC_PATH"

    exit 1
fi

if ! sudo mkdir -p "$APPLICATION_DIR"; then
    log_error \
        "[$CANONICAL_ID] Failed to create desktop application directory: $APPLICATION_DIR"

    exit 2
fi

if ! sudo tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Application Name
Comment=Application description
Exec=$EXEC_PATH
TryExec=$EXEC_PATH
Icon=application-icon
Terminal=false
Categories=Utility;
EOF
then
    log_error "[$CANONICAL_ID] Failed to install desktop file: $DESKTOP_FILE"

    exit 3
fi

if ! sudo chmod 0644 "$DESKTOP_FILE"; then
    log_error "[$CANONICAL_ID] Failed to set desktop file permissions: $DESKTOP_FILE"

    exit 4
fi
```

### Application Icons

- Prefer an icon supplied by the application archive or repository.
- Validate that a file-based icon exists before installing or referencing it.
- Install theme icons under an appropriate directory such as:

  `/usr/share/icons/hicolor/<size>/apps/<module-name>.png`

- Alternatively, use an existing icon-theme name when an appropriate system
  icon is available.
- Do not reference a missing icon path.
- Refresh the icon cache and desktop application database when their commands
  are available.
- Cache-refresh failures may log warnings and continue because they do not
  invalidate an otherwise successful installation.

Example:

```bash
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    if ! sudo gtk-update-icon-cache -f -t "/usr/share/icons/hicolor"; then
        log_warn "[$CANONICAL_ID] Failed to refresh the icon cache"
    fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    if ! sudo update-desktop-database "/usr/share/applications"; then
        log_warn \
            "[$CANONICAL_ID] Failed to refresh the desktop application database"
    fi
fi
```
