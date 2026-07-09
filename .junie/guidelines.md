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

### 📦 PPA and Launchpad Modules
- If both the PPA format (e.g., `ppa:user/repo`) and ASC key information (URL and GPG key ID) are provided, the `pre_install.sh` MUST implement both methods, defaulting to `install_asc_key` unless `*_USE_APT_ADD_REPOSITORY` (or the global `USE_APT_ADD_REPOSITORY`) is set to `true`.
- Otherwise, the `pre_install.sh` MUST implement ONLY what is provided:
  - If ONLY the PPA format is provided, use the `add_ppa` command.
  - If ONLY the ASC key/direct URI is provided, use the `install_asc_key` command without checking for `*_USE_APT_ADD_REPOSITORY`.
- Example pattern for `pre_install.sh` (Both PPA and ASC key provided):
  ```bash
  if [[ "${MODULE_NAME_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
      log_info "[$MODULE] configuring PPA with add-ppa-repository command"
      add_ppa "$MODULE" "ppa:user/repo"
  else
      source "${LIB_DIR}/distro.sh"

      log_info "[$MODULE] configuring PPA with install_asc_key command"
      install_asc_key \
          "$MODULE" \
          "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xGPG_KEY_ID" \
          "https://ppa.launchpadcontent.net/user/repo/ubuntu" \
          "$(get_ubuntu_codename)" \
          "main"
  fi
  ```

- Example pattern for `pre_install.sh` (Only PPA format):
  ```bash
  log_info "[$MODULE] configuring PPA with add-ppa-repository command"
  add_ppa "$MODULE" "ppa:user/repo"
  ```

- Example pattern for `pre_install.sh` (Non-PPA format):
  ```bash
  source "${LIB_DIR}/distro.sh"

  log_info "[$MODULE] configuring PPA with install_asc_key command"
  install_asc_key \
      "$MODULE" \
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
      log_warn "[$MODULE] Skipping configuration as requested"

      exit 0
  fi

  log_info "[$MODULE] Creating symbolic links"
  if [[ -f "$MODULE_INSTALL_DIR/binary-name" ]]; then
      sudo ln -sf "$MODULE_INSTALL_DIR/binary-name" /usr/local/bin/
  else
      log_error "[$MODULE] Binary not found at $MODULE_INSTALL_DIR/binary-name"
  fi
  ```

- Example for multiple binaries/PATH (in `post_install.sh`):
  ```bash
  if [[ "${MODULE_NAME_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
      log_warn "[$MODULE] Skipping configuration as requested"

      exit 0
  fi

  ADB_PATH_SH="${CONFIG_DIR}/adb-path.sh"
  # ... creation of path script and sourcing ...
  ```

### 📦 GitHub and External Modules (Archive and .deb)
- For modules that download `.deb` files or archives (.zip, .txz) from GitHub releases or external URLs:
    - `pre_install.sh` MUST handle the downloading of the asset and store the absolute path of the downloaded file in a state file (e.g., `${STATE_DIR}/<module-name>.path`).
    - Use `github_find_release` and `download_file` from `lib/installer_external.sh`.
    - `install.sh` MUST read the path from the state file, perform the installation or extraction, and handle path registration.
    - If it's a `.deb` file, use `apt_install` with the absolute path.
    - If it's an archive:
        - If it contains a **suite of binaries** or a complex structure, extract it to a dedicated subdirectory in `INSTALL_DIR` and use `add_to_path` from `lib/installer_common.sh` for system-wide availability.
        - If it contains a **single binary** (or a few primary ones), extract it to a dedicated subdirectory in `INSTALL_DIR` and create symbolic links `symlink_binary` from `lib/installer_common.sh`.

- Example for `pre_install.sh` (GitHub Release):
  ```bash
  source "$LIB_DIR/installer_external.sh"

  MODULE="my-module"
  STATE_FILE="$STATE_DIR/my-module.path"

  if ! download_file="$(mktemp --suffix=.deb)"; then
      exit 1
  fi

  if ! url="$(github_find_release "$MODULE" "$OWNER" "$REPO" "$REGEX")"; then
      rm -f "$download_file"
      exit 2
  fi

  printf '%s\n' "$download_file" > "$STATE_FILE"

  if ! download_file "$MODULE" "$url" "$download_file"; then
      rm -f "$STATE_FILE" "$download_file"
      exit 3
  fi
  ```

- Example for `install.sh` (Archive with `add_to_path`):
  ```bash
  source "${LIB_DIR}/installer_common.sh"

  MODULE="my-module"
  STATE_FILE="${STATE_DIR}/my-module.path"
  
  if [[ -z "${MY_MODULE_INSTALL_DIR:-}" ]]; then
      MY_MODULE_INSTALL_DIR="$INSTALL_DIR/my-module"
  fi

  read -r ARCHIVE_FILE < "$STATE_FILE"

  SUDO_CMD=""
  if ! can_write "$MY_MODULE_INSTALL_DIR"; then
      SUDO_CMD="sudo"
  fi

  $SUDO_CMD mkdir -p "$MY_MODULE_INSTALL_DIR"
  # ... extraction logic ...
  
  add_to_path "$MODULE" "$MY_MODULE_INSTALL_DIR"
  ```

### 💻 Coding Style
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
