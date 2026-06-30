# Mint Provisioner Guidelines

These guidelines are established to maintain consistency and quality across the Mint Provisioner codebase.

### 📦 Module Documentation
- Any changes to an existing module should be reflected in [MODULES.md](MODULES.md). This includes updating descriptions, adding/removing supported environment variables, or changing the source type.

### 🏗️ Module Pattern
- Any new module pattern should follow the convention similar to the existing modules. A standard module directory should look like this:
  ```text
  modules/<module-name>/
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
- For any PPA or Launchpad type modules where the URL and GPG key ID are provided, the `pre_install.sh` MUST implement the `fetch_and_install_asc_key` variant as the default method.
- It should also support a fallback to the `add-ppa_repository` command if `*_USE_APT_ADD_REPOSITORY` (or the global `USE_APT_ADD_REPOSITORY`) environment variable is set to `true`.
- Example pattern for `pre_install.sh`:
  ```bash
  if [[ "${MODULE_NAME_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
      log_info "[$MODULE] configuring PPA with add-ppa-repository command"
      add_ppa_repository "$MODULE" "ppa:user/repo"
  else
      source "${LIB_DIR}/distro.sh"

      log_info "[$MODULE] configuring PPA with fetch_and_install_asc_key command"
      fetch_and_install_asc_key \
          "$MODULE" \
          "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xGPG_KEY_ID" \
          "https://ppa.launchpadcontent.net/user/repo/ubuntu" \
          "$(get_ubuntu_codename)" \
          "main"
  fi
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
