# 🧰 Mint Provisioner

Mint Provisioner is a modular shell-script framework for automating software installation and system configuration on
Linux Mint.

It provides a structured, reusable module lifecycle for installing applications, collecting installation choices,
applying post-install configuration, managing temporary state, and cleaning up downloaded artifacts.

Although designed primarily for Linux Mint, many modules may also work on Ubuntu and other Ubuntu-based distributions.

## ⚡ TL;DR

Install modules using their canonical `<category>/<module>` or short module `<module>` IDs:

```bash
./install.sh <module> [<module>...]
./install.sh <category>/<module> [<category>/<module>...]
```

Both formats can be combined:

```bash
./install.sh git gui/flameshot term/kitty
```

Note:
- In case `<module>` resolved to 2 or more canonical id, the process is aborted

Reapply post-install configuration to installed modules:

```bash
./configure.sh <module> [<module>...]
./configure.sh <category>/<module> [<category>/<module>...]
```

For example:

```bash
./configure.sh git gui/flameshot
```

Configure every installed configurable module:

```bash
./configure.sh --all
```

List available modules:

```bash
./install.sh --list
```

See the [module catalog and documentation](modules/README.md) for available modules, installation methods, supported environment variables, and configuration details.

## 🌱 Project Origin

Mint Provisioner is a modular evolution of the earlier [os-customizer](https://github.com/hadi-susanto/os-customizer)
project.

The original framework stored installers as individual files inside a flat `installers/` directory. Each installer was
sourced into a single runner and had to expose several specially named functions.

Mint Provisioner replaces that design with categorized, self-contained modules, isolated phase scripts, reusable
framework libraries, persistent state management, richer command-line controls, and separate installation and
configuration entry points.

The project was designed and supervised by [Hadi Susanto](https://id.linkedin.com/in/hadisusanto). Its implementation
and refinement were completed with assistance from **ChatGPT** and **Junie by JetBrains**.

## ✨ Key Improvements

Compared with `os-customizer`, Mint Provisioner introduces the following improvements:

| Area                  | `os-customizer`                                                  | Mint Provisioner                                                         |
|-----------------------|------------------------------------------------------------------|--------------------------------------------------------------------------|
| Module organization   | Flat collection of installer files                               | Categorized, self-contained module directories                           |
| Module interface      | Specially named functions inside sourced files                   | Independent lifecycle scripts with standard filenames                    |
| Required phases       | Every installer had to implement the complete function interface | Only `is_installed.sh` and `install.sh` are mandatory                    |
| Configuration         | Coupled to pre-install and post-install functions                | Dedicated pre-install configuration phase with persistent state          |
| Reconfiguration       | Usually required rerunning an installer                          | Separate `configure.sh` entry point                                      |
| Module identification | Installer filename                                               | Canonical `<category>/<module>` ID                                       |
| Metadata              | Description functions and static arrays                          | Declarative category and module `metadata.conf` files                    |
| State handling        | Installer-specific variables and files                           | Shared persistent state library                                          |
| User messages         | Printed directly by individual installers                        | Stored, grouped, and displayed in the installation summary               |
| Reusable operations   | Repeated inside installer scripts                                | Shared libraries for APT, repositories, downloads, prompts, and more     |
| Execution             | Installer files sourced into the main shell                      | Phase scripts executed in isolated processes                             |
| Automation            | Primarily interactive                                            | Interactive and `NON_INTERACTIVE` execution                              |
| Cleanup               | Installer-specific and inconsistent                              | Standard optional `cleanup.sh` phase                                     |
| Reporting             | Basic success and failure lists                                  | Per-module status, timing, metadata, and post-install messages           |
| Extensibility         | One large installer file per application                         | Module directories may contain helpers, payloads, and executable scripts |

Executable phase files may use another interpreter through their shebang, such as Python. Non-executable phase files are
executed as Bash scripts with strict error handling.

## 🧭 Framework Entry Points

Mint Provisioner provides two independent entry points:

| Entry point    | Responsibility                                                               |
|----------------|------------------------------------------------------------------------------|
| `install.sh`   | Resolves modules and executes their configuration and installation lifecycle |
| `configure.sh` | Applies or reapplies post-install configuration to installed modules         |

`configure.sh` is not called by `install.sh`. It is a separate command intended for users who want to reapply
configuration without reinstalling an application.

### Configuration Naming

The similarly named scripts have different responsibilities:

| Script             | Scope     | Responsibility                                           |
|--------------------|-----------|----------------------------------------------------------|
| `/install.sh`      | Framework | Installs selected modules                                |
| `/configure.sh`    | Framework | Reconfigures already-installed modules                   |
| `configuration.sh` | Module    | Collects or resolves values required before installation |
| `post_install.sh`  | Module    | Applies application configuration after installation     |

## 🔄 Module Lifecycle

The installation process is divided into two stages.

### Stage 1: Module Configuration

Before installation begins, `install.sh` executes the optional `configuration.sh` phase for every selected module that
provides it.

All required configuration phases must complete successfully before the framework starts the installation lifecycle.

Typical configuration tasks include:

- Asking whether an optional GUI component should be installed.
- Selecting between GTK, Qt 5, or Qt 6 variants.
- Detecting a suitable package variant from the desktop environment.
- Reading an existing framework state.
- Validating values required by the installer.
- Saving user selections for later phases.

When `NON_INTERACTIVE=true`, `configuration.sh` must not prompt the user. It should use, in order of preference:

1. Existing saved state.
2. Safe automatic detection.
3. Documented default values.

If any configuration phase fails, the installation is aborted before software installation begins.

### Stage 2: Module Installation

After all module configuration phases succeed, each selected module follows this lifecycle:

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

Optional phases are skipped when their corresponding files do not exist.

#### Installation check

The mandatory `is_installed.sh` determines whether the module is already installed.

Its exit status is part of the module contract:

- `0` — The module is installed.
- `1` — The module is not installed.
- Any other value — The installation check encountered an error.

When the module is already installed, its installation lifecycle is skipped unless `FORCE_INSTALL=true`.

#### Pre-install preparation

The optional `pre_install.sh` prepares resources required by `install.sh`.

Typical responsibilities include:

- Adding package repositories.
- Installing GPG keys.
- Resolving release information.
- Downloading archives or Debian packages.
- Preparing temporary directories.
- Installing prerequisites.

#### Installation

The mandatory `install.sh` performs the actual software installation.

It should focus on installing the application and avoid unrelated user configuration whenever possible.

#### Post-install configuration

The optional `post_install.sh` applies configuration after installation succeeds.

Typical responsibilities include:

- Installing shell integrations.
- Creating aliases or helper commands.
- Writing application configuration files.
- Enabling optional features.
- Applying values saved during `configuration.sh`.
- Adding information to the final installation summary.

Modules that provide `post_install.sh` can also be reconfigured later through the top-level `configure.sh` command.

#### Cleanup

The optional `cleanup.sh` is the final phase of the installation lifecycle.

Although optional, it is highly recommended when a module:

- Creates temporary framework state used only during installation.
- Creates module-local message or status artifacts.
- Manually downloads an archive, installer, Debian package, or other artifact.
- Creates temporary directories.
- Generates intermediate files that are no longer needed.
- Stores sensitive or installation-only values.

Typical cleanup operations include:

```bash
delete_states "$CANONICAL_ID"
rm -f "$downloaded_artifact"
rm -rf "$temporary_directory"
```

Framework-managed messages required by the final installation summary should remain available until the summary is
printed. The framework removes those messages afterward.

Lifecycle execution stops when a phase fails. Consequently, `cleanup.sh` normally runs only when the preceding phases
succeed. A phase that creates temporary files should clean up immediately or use a suitable trap when those files must
also be removed after failure.

### Complete Execution Order

For multiple selected modules, the intended execution order is:

```text
Resolve and validate selected modules

Run configuration.sh for module A
Run configuration.sh for module B
Run configuration.sh for module C

Run installation lifecycle for module A
Run installation lifecycle for module B
Run installation lifecycle for module C

Print installation summary
Remove framework-managed messages
```

Collecting all required configuration first prevents the installer from stopping halfway through system changes to
request additional user input.

Once installation begins, a failed module does not prevent later selected modules from running. The framework records
each result, prints the complete summary, and exits non-zero after the summary if any module failed. Standalone
configuration follows the same rule when applying selected modules' `post_install.sh` phases.

## ⚙️ Framework Controls

The following environment variables affect framework behavior:

| Variable                   | Purpose                                                                            |
|----------------------------|------------------------------------------------------------------------------------|
| `NON_INTERACTIVE=true`     | Disables interactive prompts and uses saved, detected, or default values           |
| `FORCE_INSTALL=true`       | Runs installation even when `is_installed.sh` reports that the module is installed |
| `SKIP_CONFIGURATION=true`  | Skips supported post-install configuration                                         |
| `FORCE_CONFIGURATION=true` | Forces supported configuration to be reapplied or overwritten                      |

When both `SKIP_CONFIGURATION` and `FORCE_CONFIGURATION` are enabled, skipping configuration takes precedence.

The `--non-interactive` and `--unattended` installer options never read from standard input while acquiring sudo
privileges. Sudo credentials must already be cached, or passwordless sudo must be available; otherwise the installer
fails before module installation begins.

Modules may define additional environment variables for their own behavior. These variables should be documented in the
relevant module documentation.

## 📁 Project Structure

```text
mint-provisioner/
├── install.sh                         # Installation entry point
├── configure.sh                       # Reconfiguration entry point
├── lib/                               # Reusable framework libraries
│   ├── common.sh                      # Logging, execution, and common utilities
│   ├── distro.sh                      # Distribution detection
│   ├── installer_apt.sh               # APT, PPA, repository, and GPG helpers
│   ├── installer_common.sh            # Shared installation helpers
│   ├── installer_external.sh          # External download and release helpers
│   ├── messages.sh                    # Persistent module messages
│   ├── metadata_parser.sh             # Category and module metadata parser
│   ├── module_configurer.sh            # Reconfiguration lifecycle
│   ├── module_installer.sh             # Installation lifecycle
│   ├── prompt.sh                       # Interactive prompt helpers
│   └── state.sh                        # Persistent module state
├── modules/
│   ├── README.md                       # Module catalog and documentation index
│   └── <category>/
│       ├── metadata.conf               # Category metadata
│       └── <module>/
│           ├── metadata.conf           # Module metadata
│           ├── configuration.sh        # Installation choices (optional)
│           ├── is_installed.sh         # Installation check (mandatory)
│           ├── pre_install.sh          # Installation preparation (optional)
│           ├── install.sh              # Software installation (mandatory)
│           ├── post_install.sh         # Software configuration (optional)
│           ├── cleanup.sh              # Temporary resource cleanup (optional)
│           ├── helper.sh               # Module-specific helpers (optional)
│           └── resources/              # Module payloads or templates (optional)
├── states/                             # Generated persistent module state
└── messages/                           # Generated installation-summary messages
```

A minimal valid module contains:

```text
<module>/
├── metadata.conf
├── is_installed.sh
└── install.sh
```

A complete module may implement every lifecycle phase:

```text
<module>/
├── metadata.conf
├── configuration.sh
├── is_installed.sh
├── pre_install.sh
├── install.sh
├── post_install.sh
└── cleanup.sh
```

## 📦 Module Contract

| Phase              | Required | Primary responsibility                                            |
|--------------------|:--------:|-------------------------------------------------------------------|
| `configuration.sh` |    No    | Collect, detect, validate, and save installation choices          |
| `is_installed.sh`  |   Yes    | Report whether all required components are installed              |
| `pre_install.sh`   |    No    | Prepare repositories, keys, dependencies, or downloaded artifacts |
| `install.sh`       |   Yes    | Install the software                                              |
| `post_install.sh`  |    No    | Apply application and user configuration                          |
| `cleanup.sh`       |    No    | Remove temporary state, artifacts, and intermediate files         |

### Module metadata

Every module must provide `metadata.conf`:

```ini
NAME="Application Name"
SOURCE="Installation source"
DESCRIPTION="A short explanation of what the module installs."
```

Metadata is used for:

- Module discovery and listing.
- Installation headers.
- Canonical module resolution.
- Installation summaries.
- User-facing descriptions.

Keep `DESCRIPTION` concise and describe the result provided to the user rather than low-level implementation details.

### Canonical module IDs

Modules are identified using:

```text
<category>/<module>
```

Examples:

```text
cli/git
gui/double-commander
term/kitty
tui/lazygit
```

The short module name may be accepted when it is unique. Use the canonical ID whenever ambiguity is possible.

## 🧩 Extending the Framework

### Adding a category

Create a category directory and its metadata:

```text
modules/<category>/metadata.conf
```

Example:

```ini
NAME="Command Line Tools"
DESCRIPTION="Command-line applications and utilities for everyday use."
```

Category directory names should:

- Use lowercase characters.
- Use hyphens instead of spaces.
- Remain short and descriptive.
- Avoid overlapping responsibilities with an existing category.

### Adding a module

Create the module directory:

```bash
mkdir -p modules/<category>/<module>
```

Then:

1. Add `metadata.conf`.
2. Implement `is_installed.sh`.
3. Implement `install.sh`.
4. Add `configuration.sh` when installation requires choices or detected values.
5. Add `pre_install.sh` when installation requires preparation or manual downloads.
6. Add `post_install.sh` when the module provides configurable behavior.
7. Add `cleanup.sh` when state, messages, downloads, or temporary files are created.
8. Add module-specific helpers and resources when necessary.
9. Document the module in the appropriate category file under `modules/`.

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

## 🛡️ Module Design Guidelines

New modules should follow these conventions:

- Use Bash unless another interpreter provides a clear benefit.
- Use `#!/usr/bin/env bash` for Bash scripts.
- Enable `set -euo pipefail` immediately after the shebang in entrypoints and module phase scripts.
- Quote variable expansions unless word splitting is intentional.
- Use `CANONICAL_ID` when interacting with shared state or message helpers.
- Use shared logging helpers instead of printing errors directly.
- Keep `is_installed.sh` free of side effects.
- Verify every component the module promises to install.
- Keep `install.sh` focused on software installation.
- Keep user configuration in `post_install.sh`.
- Store cross-phase choices through the state library.
- Use the messages library for information that should appear in the final summary.
- Add `cleanup.sh` whenever temporary resources are created.
- Return non-zero immediately when a phase cannot complete successfully.
- Avoid interactive input when `NON_INTERACTIVE=true`.
- Respect `SKIP_CONFIGURATION`, `FORCE_CONFIGURATION`, and `FORCE_INSTALL`.
- Make repeated execution safe whenever practical.
- Use shared framework helpers before introducing duplicate module-specific logic.

## 📚 Module Documentation

For the complete module catalog, category index, supported environment variables, installation methods, and
module-specific configuration details, see [`modules/README.md`](modules/README.md).

## 🙏 Credits

Mint Provisioner is designed and supervised by [Hadi Susanto](https://id.linkedin.com/in/hadisusanto).

Implementation and refinement were completed with assistance from:

- **ChatGPT** by OpenAI
- **Junie** by JetBrains

Mint Provisioner is based on ideas developed in the
earlier [os-customizer](https://github.com/hadi-susanto/os-customizer) project.
