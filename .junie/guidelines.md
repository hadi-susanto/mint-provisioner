# Mint Provisioner Guidelines

These guidelines are established to maintain consistency and quality across the Mint Provisioner codebase.

### 📦 Module Documentation
- Any changes to an existing module should be reflected in [MODULES.md](MODULES.md). This includes updating descriptions, adding/removing supported environment variables, or changing the source type.

### 🏗️ Module Pattern
- Any new module pattern should follow the convention similar to the existing modules. A standard module directory should look like this:
  ```text
  modules/<category-name>/<module-name>/
  ├── metadata.conf      # Mandatory: NAME, DESCRIPTION, SOURCE
  ├── is_installed.sh    # Mandatory: Check if software exists (exit 0 if installed, 1 if not)
  ├── pre_install.sh     # Optional: Prerequisites (PPA, GPG keys, etc.)
  ├── install.sh         # Mandatory: Core installation logic
  ├── post_install.sh    # Optional: Configuration and customization
  └── cleanup.sh         # Optional: Post-install cleanup
  ```

- On any module phase (pre_install, install, post_install, etc.), use `exit` instead of `return` unless it is within a function. The framework executes these scripts directly.
- In every module script, populate all required variables early, immediately after sourcing required libraries.
- `installer_common.sh` already sources `common.sh`. If you source `installer_common.sh`, do not explicitly source `common.sh` again.

- When creating a new `metadata.conf`, adhere to these:
  - **Description**: Length should be less than 100 characters if possible. It should tell what the module is best for and its main selling point without listing everything it can do.
  - **Source**:
    - In `metadata.conf`: Always all lower case (e.g., `native`, `github`, `launchpad`).
    - In `MODULES.md`: Human-readable format (capitalize each word, e.g., `Native`, `Launchpad`, `PPA`; use `GitHub` for GitHub).
    - Allowed values:
      - `native`: When there is no PPA involved.
      - `launchpad`: When the external PPA comes from Launchpad.
      - `ppa`: When the external PPA is other than Launchpad.
      - `github`: When the source is downloaded from GitHub or cloning GitHub.
      - `external`: When the source is downloaded directly from vendor site / outside GitHub.

### 📦 State Management
- Use `lib/state.sh` for managing persistent state between module phases.
- The framework automatically provides `CANONICAL_ID` (in `<category>/<module>` format) to all module scripts.
- Use `set_state "KEY" "VALUE"` and `save_states "$CANONICAL_ID"` to persist data.
- Use `load_states "$CANONICAL_ID"` and `get_state "KEY"` to retrieve persisted data.
- Always call `delete_states "$CANONICAL_ID"` in `cleanup.sh` to remove state files.

### 📦 Post-Installation Messages
- Use `lib/messages.sh` to store messages that should be displayed to the user after the provisioning process.
- Use `add_message "$CANONICAL_ID" "level" "message"` (levels: `info`, `warn`, `error`).
- This replaces any manual `post_message` function calls.

### 📦 PPA and Launchpad Modules
- If both the PPA format (e.g., `ppa:user/repo`) and ASC key information (URL and GPG key ID) are provided, the `pre_install.sh` MUST implement both methods, defaulting to `install_asc_key` unless `*_USE_APT_ADD_REPOSITORY` (or the global `USE_APT_ADD_REPOSITORY`) is set to `true`.
- Otherwise, the `pre_install.sh` MUST implement ONLY what is provided:
  - If ONLY the PPA format is provided, use the `add_ppa` command.
  - If ONLY the ASC key/direct URI is provided, use the `install_asc_key` command without checking for `*_USE_APT_ADD_REPOSITORY`.
- Example pattern for `pre_install.sh` (Both PPA and ASC key provided):
  ```bash
  if [[ "${MODULE_NAME_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
      log_info "[$CANONICAL_ID] configuring PPA with add-ppa-repository command"
      add_ppa "$CANONICAL_ID" "ppa:user/repo"
  else
      source "${LIB_DIR}/distro.sh"

      log_info "[$CANONICAL_ID] configuring PPA with install_asc_key command"
      install_asc_key \
          "$CANONICAL_ID" \
          "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xGPG_KEY_ID" \
          "https://ppa.launchpadcontent.net/user/repo/ubuntu" \
          "$(get_ubuntu_codename)" \
          "main"
  fi
  ```

- Example pattern for `pre_install.sh` (Only PPA format):
  ```bash
  log_info "[$CANONICAL_ID] configuring PPA with add-ppa-repository command"
  add_ppa "$CANONICAL_ID" "ppa:user/repo"
  ```

- Example pattern for `pre_install.sh` (Non-PPA format):
  ```bash
  source "${LIB_DIR}/distro.sh"

  log_info "[$CANONICAL_ID] configuring PPA with install_asc_key command"
  install_asc_key \
      "$CANONICAL_ID" \
      "https://example.com/repo.key" \
      "https://example.com/ubuntu" \
      "$(get_ubuntu_codename)" \
      "main"
  ```

### 📦 Binary Installation and Path Management
- For modules that install binaries:
    - If it's a single binary, prefer installing it to a dedicated subdirectory in `INSTALL_DIR` (e.g., `INSTALL_DIR/module-name/binary`) and then create a symbolic link in `/usr/local/bin` during the `post_install.sh` phase.
    - If it's a suite of binaries or requires a specific directory structure (like `adb`), install it to a dedicated subdirectory in `INSTALL_DIR` and append that directory to the `PATH` environment variable.
    - Path management should be done in `post_install.sh` by creating a shell script in the user's config directory (e.g., `~/.config/mint-provisioner/module-name-path.sh`) and using `add_bash_source` and `add_zsh_source` to load it.

- On `post_install.sh`, after sourcing and variable declaration, immediately check for `*_SKIP_CONFIGURATION` (e.g., `ADB_SKIP_CONFIGURATION`) or the global `SKIP_CONFIGURATION` environment variable. Use `exit 0` when skipping the phase.
- (Optional) After the skip check, define the `*_FORCE_CONFIGURATION` and `FORCE_CONFIGURATION` variables for use in the script.
- Configuration and symbolic links in `post_install.sh` MUST respect the skip configuration settings.

- Always check for the existence of the source file/directory before creating a symbolic link. Do log_error if the file/directory does not exist.

- Example for single binary (in `post_install.sh`):
  ```bash
  if [[ "${MODULE_NAME_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
      log_warn "[$CANONICAL_ID] Skipping configuration as requested"

      exit 0
  fi

  log_info "[$CANONICAL_ID] Creating symbolic links"
  if [[ -f "$MODULE_INSTALL_DIR/binary-name" ]]; then
      sudo ln -sf "$MODULE_INSTALL_DIR/binary-name" /usr/local/bin/
  else
      log_error "[$CANONICAL_ID] Binary not found at $MODULE_INSTALL_DIR/binary-name"
  fi
  ```

- Example for multiple binaries/PATH (in `post_install.sh`):
  ```bash
  if [[ "${MODULE_NAME_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
      log_warn "[$CANONICAL_ID] Skipping configuration as requested"

      exit 0
  fi

  ADB_PATH_SH="${CONFIG_DIR}/adb-path.sh"
  # ... creation of path script and sourcing ...
  ```

### 📦 GitHub and External Modules (Archive and .deb)
- For modules that download `.deb` files or archives (.zip, .txz) from GitHub releases or external URLs:
    - `pre_install.sh` MUST handle the downloading of the asset and use `set_state` and `save_states` to store the path of the downloaded file.
    - Use `github_find_release` and `download_file` from `lib/installer_external.sh`.
    - `install.sh` MUST use `load_states` and `get_state` to retrieve the path, perform the installation or extraction, and handle path registration.
    - If it's a `.deb` file, use `apt_install` with the absolute path.
    - If it's an archive:
        - If it contains a **suite of binaries** or a complex structure, extract it to a dedicated subdirectory in `INSTALL_DIR` and use `add_to_path` from `lib/installer_common.sh` for system-wide availability.
        - If it contains a **single binary** (or a few primary ones), extract it to a dedicated subdirectory in `INSTALL_DIR` and create symbolic links `symlink_binary` from `lib/installer_common.sh`.

- Example for `pre_install.sh` (GitHub Release):
  ```bash
  source "$LIB_DIR/installer_external.sh"
  source "$LIB_DIR/state.sh"

  if ! download_file="$(mktemp --suffix=.deb)"; then
      log_error "[$CANONICAL_ID] Failed to create temporary file"

      exit 1
  fi

  if ! url="$(github_find_release "$CANONICAL_ID" "$OWNER" "$REPO" "$REGEX")"; then
      log_error "[$CANONICAL_ID] Failed to resolve latest release"

      rm -f "$download_file"

      exit 2
  fi

  if ! download_file "$CANONICAL_ID" "$url" "$download_file"; then
      log_error "[$CANONICAL_ID] Download failed"

      rm -f "$download_file"

      exit 3
  fi

  set_state "DEB_FILE" "$download_file"
  save_states "$CANONICAL_ID" || exit 4
  ```

- Example for `install.sh` (Archive with `add_to_path`):
  ```bash
  source "${LIB_DIR}/installer_common.sh"
  source "${LIB_DIR}/state.sh"

  load_states "$CANONICAL_ID" || exit 1
  ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

  if [[ -z "${MY_MODULE_INSTALL_DIR:-}" ]]; then
      MY_MODULE_INSTALL_DIR="$INSTALL_DIR/my-module"
  fi

  SUDO_CMD=""
  if ! can_write "$MY_MODULE_INSTALL_DIR"; then
      SUDO_CMD="sudo"
  fi

  $SUDO_CMD mkdir -p "$MY_MODULE_INSTALL_DIR"
  # ... extraction logic ...
  
  add_to_path "$CANONICAL_ID" "$MY_MODULE_INSTALL_DIR"
  ```

### 💻 Coding Style
- **Canonical ID and Logging**: Use `$CANONICAL_ID` (automatically provided) for logging and state management. Avoid defining a local `$MODULE` variable.
  - *Example:* `log_info "[$CANONICAL_ID] Starting installation"`
- **Script Directory**: Use `"${MODULES_DIR}/${CANONICAL_ID}"` to refer to the module's directory. This replaces `$(dirname "$0")` or similar constructs.
- **Return and Exit Statements**: Any `return` or `exit` statement should have preceding empty lines to improve readability.
  - *Correct:*
    ```bash
    if [[ "$FAILED" == "true" ]]; then
        log_error "Operation failed"

        exit 1
    fi
    ```
  - *Incorrect:*
    ```bash
    if [[ "$FAILED" == "true" ]]; then
        log_error "Operation failed"
        exit 1
    fi
    ```

- **Guard Clauses**: For any logic or loops, prefer guard clauses whenever possible to reduce nesting and improve code clarity.
  - *Example:*
    ```bash
    if [[ "${SKIP_CONFIGURATION:-false}" == "true" ]]; then
        log_warn "Skipping configuration"

        exit 0
    fi

    # Continue with main logic...
    ```

- **Privilege Management**: Use `can_write` and `sudo` primarily during the `install` phase when modifying system directories. Avoid using them in `post_install` or other phases that deal with user-owned directories (like `~/.config`) unless specifically required.
