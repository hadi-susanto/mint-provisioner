# 📦 Mint Provisioner Modules

This directory contains the software modules supported by Mint Provisioner.

Each module is a self-contained installation unit responsible for detecting, installing, configuring, and cleaning up a
specific application or system component.

For an overview of the complete framework, see the [main project README](../README.md).

## 🗂️ Module Catalog

Mint Provisioner currently provides **49 modules** across **7 categories**.

Categories organize the module catalog, provide metadata for module listings, and form part of each module's canonical
ID:

```text
<category>/<module>
```

For example:

```text
cli/git
gui/double-commander
term/kitty
tui/lazy-git
```

Each category document contains detailed information about its modules, including:

- Module overview.
- Installation method.
- Supported environment variables.
- Post-install configuration.
- Shell integration, aliases, and helper functions.
- Official project website.

| Category                        | ID     | Modules                                                                                                                                                                              |
|---------------------------------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Command Line](CLI.md)          | `cli`  | `adb`, `bat`, `delta`, `eza`, `git`, `mkvtoolnix`, `procs`, `tlp`                                                                                                                    |
| [Development](DEV.md)           | `dev`  | `apache-maven`, `dbeaver-community`, `dbgate-community`, `docker`, `mongodb-compass`, `pg-admin`, `sdkman`                                                                           |
| [Desktop Applications](GUI.md)  | `gui`  | `brave-browser`, `brave-origin`, `cryptomator`, `deadbeef`, `double-commander`, `flameshot`, `fman`, `insync`, `keepass-xc`, `microsoft-edge`, `mu-commander`, `sunflower`, `tlp-ui` |
| [System Administration](SYS.md) | `sys`  | `apt-fast`, `dconf-editor`, `dnscrypt-proxy`, `nerd-font`, `oobe`                                                                                                                    |
| [Terminal](TERM.md)             | `term` | `alacritty`, `ghostty`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`, `terminator`, `zsh`                                                                                    |
| [Terminal UI](TUI.md)           | `tui`  | `bottom`, `du-analyzer`, `du-rust`, `duf`, `git-ui`, `lazy-git`                                                                                                                      |
| [Miscellaneous](MISC.md)        | `misc` | `any-desk`, `virtual-box`                                                                                                                                                            |

## 📁 Directory Structure

Categories and modules use the following structure:

```text
modules/
├── README.md
├── CLI.md
├── DEV.md
├── GUI.md
├── SYS.md
├── TERM.md
├── TUI.md
├── MISC.md
└── <category>/
    ├── metadata.conf
    └── <module>/
        ├── metadata.conf
        ├── configuration.sh
        ├── is_installed.sh
        ├── pre_install.sh
        ├── install.sh
        ├── post_install.sh
        ├── cleanup.sh
        ├── helper.sh
        └── resources/
```

Only the following module files are mandatory:

```text
<module>/
├── metadata.conf
├── is_installed.sh
└── install.sh
```

All other phase scripts, helpers, resources, templates, and payloads are optional.

## 🔄 Module Lifecycle

Module processing is divided into configuration and installation stages.

### Configuration stage

Before installation begins, the framework scans every selected module for an optional `configuration.sh`.

During this scan, `configure_module` first executes the module's `is_installed.sh`:

- If the application is already installed and `FORCE_INSTALL` is not enabled, `configuration.sh` is skipped.
- If the application is not installed, `configuration.sh` is executed.
- If `FORCE_INSTALL=true`, `configuration.sh` is executed even when the application is already installed.

This prevents users from being prompted for installation choices when the requested application is already available and
will not be reinstalled.

When several modules are selected, the complete configuration scan finishes before the installation stage begins.

If a required configuration phase fails, installation is aborted.

### Installation stage

After the configuration scan succeeds, each selected module follows this lifecycle:

```text
is_installed.sh
        ↓
pre_install.sh
        ↓
install.sh
        ↓
post_install.sh
        ↓
cleanup.sh
```

Missing optional phases are skipped automatically.

A module's lifecycle stops immediately when one of its phases fails. The framework records that module as failed,
continues with the remaining selected modules, prints the complete summary, and then exits non-zero.

### Phase responsibilities

| Phase              | Required | Responsibility                                                          |
|--------------------|:--------:|-------------------------------------------------------------------------|
| `configuration.sh` |    No    | Collect, detect, validate, and save choices required by installation    |
| `is_installed.sh`  |   Yes    | Determine whether the module is already installed                       |
| `pre_install.sh`   |    No    | Prepare repositories, dependencies, downloads, keys, or temporary files |
| `install.sh`       |   Yes    | Perform the software installation                                       |
| `post_install.sh`  |    No    | Apply application configuration and shell integration                   |
| `cleanup.sh`       |    No    | Remove temporary state, downloads, and intermediate files               |

### `configuration.sh`

Use `configuration.sh` when installation requires information before other installation phases can proceed.

Typical responsibilities include:

- Asking which package variant should be installed.
- Enabling or disabling an optional GUI.
- Detecting GTK, Qt 5, or Qt 6.
- Reading configuration from an external source.
- Validating installation settings.
- Saving selected values through the state library.

When `NON_INTERACTIVE=true`, the phase must not prompt the user. It should use:

1. Existing saved state.
2. Automatic detection.
3. Documented default values.

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
    package="example-default"
else
    # Collect the user's selection.
    package="example-selected"
fi

set_state "EXAMPLE_PACKAGE" "$package"
save_states "$CANONICAL_ID" || exit $?
```

### `is_installed.sh`

`is_installed.sh` must not modify the system.

Its exit status is part of the framework contract:

|     Exit status | Meaning                       |
|----------------:|-------------------------------|
|             `0` | The module is installed       |
|             `1` | The module is not installed   |
| Any other value | The installation check failed |

Framework status helpers preserve these exit codes so callers can distinguish a missing installation from a failed
status check. The check should verify every component promised by the module.

For example, a module that installs several commands should verify all required commands instead of checking only the
primary executable.

```bash
#!/usr/bin/env bash
set -euo pipefail

command -v example >/dev/null 2>&1 &&
    command -v example-helper >/dev/null 2>&1
```

### `pre_install.sh`

Use `pre_install.sh` for preparation that must happen before the application is installed.

Typical responsibilities include:

- Adding an external APT repository.
- Installing repository signing keys.
- Resolving the latest available release.
- Downloading an archive or Debian package.
- Creating a temporary working directory.
- Installing prerequisites.

When an artifact is downloaded manually, save its path in module state so that `install.sh` and `cleanup.sh` can access
the same file.

### `install.sh`

`install.sh` performs the actual software installation.

Keep this phase focused on installing the application. User configuration, aliases, shell integrations, and optional
customizations should normally be handled by `post_install.sh`.

### `post_install.sh`

Use `post_install.sh` for configuration applied after installation.

Typical responsibilities include:

- Installing configuration files.
- Registering Bash or Zsh integration.
- Creating shell aliases or helper functions.
- Setting an application theme.
- Enabling optional features.
- Adding information to the installation summary.

The top-level `configure.sh` command executes `post_install.sh` independently for installed modules. It does not execute
`configuration.sh`, `pre_install.sh`, `install.sh`, or `cleanup.sh`.

Because `configure.sh` may reapply this phase later, `post_install.sh` should not depend on temporary installation
artifacts.

### `cleanup.sh`

`cleanup.sh` is optional but highly recommended whenever a module creates temporary resources.

Add this phase when the module:

- Saves installation-only state.
- Downloads a package, archive, or installer manually.
- Creates a temporary working directory.
- Creates intermediate files.
- Stores module-local artifacts that should not remain after installation.

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || {
    log_warn "[$CANONICAL_ID] No cleanup state was found."
    exit 0
}

artifact="$(get_state "DOWNLOADED_ARTIFACT" "")"

if [[ -n "$artifact" && -f "$artifact" ]]; then
    log_info "[$CANONICAL_ID] Removing downloaded artifact: $artifact"
    rm -f "$artifact"
fi

delete_states "$CANONICAL_ID" || exit $?
```

Messages intended for the final installation summary must remain available until the summary is printed.
Framework-managed messages are deleted automatically afterward.

Because lifecycle execution stops when a phase fails, `cleanup.sh` normally runs only when all preceding phases succeed.
A phase that must remove an artifact after failure should perform its own immediate cleanup or register a suitable trap.

## 🏷️ Module Metadata

Every module must provide a `metadata.conf` file containing:

```ini
NAME="Application Name"
DESCRIPTION="A short description of what the module installs."
SOURCE="github"
```

`SOURCE` must be one of the lowercase values `native`, `ppa`, `apt`, `github`, or `external`. User-facing module
documentation uses the corresponding names Native, PPA, APT, GitHub, and External.

Example:

```ini
NAME="MyTool"
DESCRIPTION="A command-line utility for processing example files."
SOURCE="github"
```

Metadata is used when:

- Listing available modules.
- Resolving module selectors.
- Printing installation headers.
- Displaying installation summaries.
- Generating user-facing descriptions.

Keep `DESCRIPTION` concise and describe the result provided to the user rather than low-level implementation details.

## ➕ Adding a Category

Create the category directory:

```bash
mkdir -p modules/<category>
```

Then add:

```text
modules/<category>/metadata.conf
```

Example:

```ini
NAME="Command Line"
DESCRIPTION="Command-line utilities for everyday productivity and developer workflows."
```

Category conventions:

- Use lowercase directory names.
- Use hyphens instead of spaces.
- Keep the category ID short and descriptive.
- Use a readable display name in `NAME`.
- Keep `DESCRIPTION` to one clear sentence.
- Avoid creating a new category when an existing category already fits.

Create a corresponding uppercase documentation file in `modules/`:

```text
modules/<CATEGORY>.md
```

For example:

```text
modules/CLI.md
```

Finally, add the new category to the catalog table in this file.

## 🧩 Adding a Module

Create a module under the appropriate category:

```bash
mkdir -p modules/<category>/<module>
```

Then:

1. Add `metadata.conf`.
2. Implement `is_installed.sh`.
3. Implement `install.sh`.
4. Add `configuration.sh` when installation requires choices or automatic detection.
5. Add `pre_install.sh` when preparation or manual downloads are required.
6. Add `post_install.sh` when the application supports automatic configuration.
7. Add `cleanup.sh` when state, downloads, or temporary files are created.
8. Add module-specific helpers, templates, or resources when necessary.
9. Document the module in the corresponding category Markdown file.
10. Add the module to the catalog table in this file.

Example:

```text
modules/
└── gui/
    └── example-app/
        ├── metadata.conf
        ├── configuration.sh
        ├── is_installed.sh
        ├── pre_install.sh
        ├── install.sh
        ├── post_install.sh
        └── cleanup.sh
```

## 🧰 Using Framework Libraries

Module scripts may load the framework libraries they require:

```bash
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/messages.sh"
```

Important exported paths include:

| Variable       | Purpose                                               |
|----------------|-------------------------------------------------------|
| `ROOT_DIR`     | Mint Provisioner repository root                      |
| `INSTALL_DIR`  | Default parent directory for standalone installations |
| `LIB_DIR`      | Framework library directory                           |
| `MODULES_DIR`  | Module directory                                      |
| `CANONICAL_ID` | Current module ID in `<category>/<module>` format     |

Only source libraries that the phase actually needs.

### Script execution

If a phase file is executable, the framework executes it directly. Its shebang may therefore select Bash or another
suitable interpreter.

If the phase file is not executable, the framework executes it using:

```bash
bash -euo pipefail
```

Bash phase scripts should remain compatible with strict mode.

## ⚙️ Global Environment Variables

Global environment variables affect the framework or all supported modules.

### `NON_INTERACTIVE`

Disables interactive questions.

Modules should use saved values, automatic detection, or documented defaults instead.

Default:

```text
false
```

Example:

```bash
NON_INTERACTIVE=true ./install.sh gui/double-commander
```

### `FORCE_INSTALL`

Forces installation even when `is_installed.sh` reports that the module is already installed.

This also allows the module's `configuration.sh` to run during the configuration scan.

Default:

```text
false
```

Example:

```bash
FORCE_INSTALL=true ./install.sh cli/git
```

### `USE_APT_ADD_REPOSITORY`

Controls how modules add external APT repositories.

When enabled, modules use `add-apt-repository` where supported. When disabled, repository configuration is performed
manually through APT source files.

Default:

```text
false
```

### `SKIP_CONFIGURATION`

Skips supported automatic post-install configuration.

Software installation still proceeds, but supported modules avoid operations such as:

- Copying configuration files.
- Registering Bash or Zsh integration.
- Installing shell aliases.
- Installing shell helper functions.
- Replacing application defaults.

Default:

```text
false
```

### `FORCE_CONFIGURATION`

Allows supported post-install configuration to overwrite or reapply existing configuration.

Default for `install.sh`:

```text
false
```

Default for `configure.sh`:

```text
true
```

When both `SKIP_CONFIGURATION` and `FORCE_CONFIGURATION` are enabled, `SKIP_CONFIGURATION` takes precedence.

## 🔧 Common Module Environment Variables

Module-specific environment variables use an uppercase prefix derived from the module ID.

For example:

```text
example-module → EXAMPLE_MODULE_*
lazy-git       → LAZY_GIT_*
```

### `*_USE_APT_ADD_REPOSITORY`

Overrides `USE_APT_ADD_REPOSITORY` for an individual module.

Example:

```bash
TERMINATOR_USE_APT_ADD_REPOSITORY=true
```

### `*_REGEX`

Specifies the regular expression used to locate a downloadable release artifact.

Example:

```bash
LAZY_GIT_REGEX='lazygit_.*_linux_x86_64\.tar\.gz$'
```

### `*_SUFFIX`

Specifies an optional filename suffix used to select a release artifact.

This is useful when a project publishes several architecture-specific or distribution-specific files.

Not every module supports this variable.

### `*_INSTALL_DIR`

Overrides the default installation directory for a module installed from a standalone archive.

Example:

```bash
DELTA_INSTALL_DIR=/opt/tools/delta
```

### `*_SKIP_CONFIGURATION`

Overrides `SKIP_CONFIGURATION` for one module.

Example:

```bash
DELTA_SKIP_CONFIGURATION=true
```

### `*_FORCE_CONFIGURATION`

Overrides `FORCE_CONFIGURATION` for one module.

Example:

```bash
GIT_FORCE_CONFIGURATION=true
```

Module-specific variables that do not follow these common patterns must be documented in the relevant category file.

## 📝 Module Documentation Requirements

Each module must be documented under its corresponding category page.

Use the following structure:

```markdown
## Application Name (`module-id`)

A concise explanation of the application and its purpose.

### Installation Method

**Installation source or method**

Explain how the module installs the application.

### Supported ENV

- `MODULE_VARIABLE`
    - Explain what the variable controls.
    - Default: `value`

### Post-install Configuration

Describe installed configuration, shell integration, aliases, functions, or other automatic setup.

### Official Website

https://example.com/
```

If a section does not apply, omit it instead of adding an empty heading.

## 🛡️ Module Development Guidelines

New and updated modules should:

- Quote variable expansions unless word splitting is intentional.
- Remain compatible with `set -euo pipefail`.
- Use `CANONICAL_ID` with state and message helpers.
- Use framework logging helpers for diagnostic output.
- Keep `is_installed.sh` free of side effects.
- Return `1` only when the application is not installed.
- Return another non-zero status when detection itself fails.
- Keep `install.sh` focused on installation.
- Keep application configuration in `post_install.sh`.
- Avoid prompts when `NON_INTERACTIVE=true`.
- Respect global and module-specific configuration controls.
- Use state instead of unrelated global variables to share values between phases.
- Add cleanup whenever temporary resources are created.
- Use shared framework helpers before duplicating installation logic.
- Support repeated execution safely whenever practical.
- Document every supported environment variable.
