# 📦 Mint Provisioner Modules

This directory contains the software modules supported by Mint Provisioner. Each module is a self-contained installation
unit that declares its metadata and owns the scripts needed to detect, prepare, install, and clean up one application or
system component.

For the framework command interface, see the [main project README](../README.md). For instructions on adding or changing
modules, see the [module contributor guide](CONTRIBUTING.md).

## 🗂️ Module Catalog

Mint Provisioner currently provides **67 modules** across **8 categories**. A category is part of a module's canonical
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

Each category page documents its modules' installation method, supported environment variables, shell integration, and
official project links.

| Category                        | ID     | Modules                                                                                                                                                                              |
|---------------------------------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Command Line](CLI.md)          | `cli`  | `adb`, `bat`, `delta`, `eza`, `git`, `mkvtoolnix`, `procs`, `tlp`                                                                                                                    |
| [Development](DEV.md)           | `dev`  | `apache-maven`, `bruno`, `dbeaver-community`, `dbgate-community`, `docker`, `httptoolkit`, `mongodb-compass`, `pg-admin`, `postman`, `sdkman`, `yaak`                                |
| [Desktop Applications](GUI.md)  | `gui`  | `brave-browser`, `brave-origin`, `cryptomator`, `deadbeef`, `double-commander`, `flameshot`, `fman`, `insync`, `keepass-xc`, `microsoft-edge`, `mu-commander`, `sunflower`, `tlp-ui` |
| [IDE](IDE.md)                   | `ide`  | `clion`, `cudatext`, `datagrip`, `geany`, `goland`, `idea`, `phpstorm`, `pycharm`, `rider`, `rubymine`, `rustrover`, `vscode`, `vscodium`, `webstorm`                                |
| [System Administration](SYS.md) | `sys`  | `apt-fast`, `dconf-editor`, `dnscrypt-proxy`, `nerd-font`, `system-toolkit`                                                                                                          |
| [Terminal](TERM.md)             | `term` | `alacritty`, `ghostty`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`, `terminator`, `zsh`                                                                                    |
| [Terminal UI](TUI.md)           | `tui`  | `bottom`, `du-analyzer`, `du-rust`, `duf`, `git-ui`, `lazy-git`                                                                                                                      |
| [Miscellaneous](MISC.md)        | `misc` | `any-desk`, `virtual-box`                                                                                                                                                            |

## 📁 Directory Structure

```text
modules/
├── README.md                           # Module catalog and lifecycle reference
├── CONTRIBUTING.md                     # Adding categories and modules
├── CLI.md, DEV.md, GUI.md, ...         # Category documentation
└── <category>/
    ├── metadata.conf                   # Required category name and description
    ├── shared-helper.sh                # Optional helpers shared by this category
    └── <module>/
        ├── metadata.conf               # Required module metadata and optional CLI commands
        ├── installed.sh                # Optional installed-state detector
        ├── interactive.sh              # Optional interactive pre-install questions or customization
        ├── non-interactive.sh          # Alternative setup for --non-interactive; requires interactive.sh
        ├── pre-install.sh              # Optional installation preparation
        ├── install.sh                  # Required software installation
        ├── post-install.sh             # Optional post-install adjustment
        ├── cleanup.sh                  # Optional temporary-resource cleanup
        ├── helper.sh                   # Optional module-local helpers
        └── resources/                  # Optional templates and payloads
```

Only `install.sh` is required. All other module scripts and resources are optional.

## 🔄 Module Lifecycle

`mp install` resolves the requested module selectors, checks their installed state, and queues only modules that need
installation. Use `--force` to queue a module even when it is already detected as installed.

Before any module installation begins, every queued module completes its optional setup phase. A normal installation
runs `interactive.sh`; `--non-interactive` and `--unattended` select `non-interactive.sh` instead. A non-interactive
setup phase is valid only when the module also provides `interactive.sh`; a module with `interactive.sh` but no
`non-interactive.sh` does not support non-interactive installation. If the selected setup phase fails, the command stops
before any installation phase is run. After the complete setup session succeeds, the framework processes each queued
module in order:

```text
Resolve module selectors
        ↓
Check installed state and filter modules
        ↓
interactive.sh or non-interactive.sh for every queued module
        ↓
pre-install.sh → install.sh → post-install.sh → cleanup.sh
```

Missing optional scripts are skipped. A failure in a normal installation phase stops that module's remaining normal
phases, then runs `cleanup.sh` when present. The framework records the result, continues with later selected modules,
prints a summary, and exits non-zero if any module failed.

### Installed-state detection

`installed.sh` is optional. When `mp install` or `mp list modules` needs a module's status, the framework uses the first
applicable method:

1. Run `<module>/installed.sh` when it exists. Its exit status is used directly.
2. Check every command named by the module metadata's `CLI` value.
3. Check the module-ID basename as a command; for example, `gui/example-app` falls back to `example-app`.

`CLI` is a comma-separated command list. Every listed command must resolve on `PATH` for the module to be considered
installed. The framework treats malformed or indeterminate detection as an error rather than assuming the module is
absent.

An `installed.sh` script must not change system state and should return:

|     Exit status | Meaning                           |
|----------------:|-----------------------------------|
|             `0` | The module is installed.          |
|             `1` | The module is not installed.      |
| Any other value | Installed-state detection failed. |

Use `installed.sh` when a command check cannot accurately represent the installed component, such as when validating
registry data, files, package variants, or multiple application artifacts.

### Phase responsibilities

| Phase             | Required | Responsibility                                                                                         |
|-------------------|:--------:|--------------------------------------------------------------------------------------------------------|
| `installed.sh`    |    No    | Determine installed state when the default command detection is insufficient.                          |
| `interactive.sh`  |    No    | Collect required answers or apply user-selected installation customization before installation starts. |
| `non-interactive.sh` | No | Provide the non-prompt equivalent of `interactive.sh`; valid only when `interactive.sh` exists. |
| `pre-install.sh`  |    No    | Prepare repositories, dependencies, downloads, keys, or temporary files.                               |
| `install.sh`      |   Yes    | Perform the software installation and save durable installation facts when needed.                     |
| `post-install.sh` |    No    | Apply an installation-adjacent adjustment after a successful installation.                             |
| `cleanup.sh`      |    No    | Remove temporary state, downloads, and intermediate files.                                             |

### Interactive setup

Use `interactive.sh` for questions or customization that must be resolved before installation, such as selecting a
package variant, enabling an optional component, detecting a suitable toolkit, or validating an installation target.
Save values that later phases need through the state library.

`mp install --non-interactive` and its `--unattended` alias run `non-interactive.sh` instead of `interactive.sh` for
each module that has an interactive setup. The non-interactive phase must resolve the same required choices without
prompts, using supplied values, current-configuration detection, or documented defaults. Modules with no setup phase
continue directly to installation. Do not provide a `non-interactive.sh` file without its corresponding
`interactive.sh`.

### Installation registry

Module state is temporary data shared between lifecycle phases. The installation registry is durable, module-owned data
stored per user at:

```text
$HOME/.local/state/mint-provisioner/registry/<category>/<module>.registry
```

When a module needs durable facts such as an installation path, version, or managed component list, its installation
code should save them with the registry library only after the required installation succeeds. An `installed.sh`
detector can load and validate those values later. A registry file alone does not prove that software is still
installed, and ordinary cleanup must not remove it.

Registry files are written atomically with owner-only permissions. The registry library reserves `SCHEMA_VERSION`;
module keys must be uppercase and values must be single-line.

## 🏷️ Metadata

Each category and module has its own `metadata.conf` file. Metadata uses uppercase `KEY=value` assignments; values may
be double quoted.

### Category metadata

Every category directory requires:

```ini
NAME="Command Line"
DESCRIPTION="Command-line applications and utilities for everyday use."
```

| Key           | Required | Purpose                                        |
|---------------|:--------:|------------------------------------------------|
| `NAME`        |   Yes    | Human-readable category name.                  |
| `DESCRIPTION` |   Yes    | Concise category description used by listings. |

### Module metadata

Every module directory requires:

```ini
NAME="Example App"
DESCRIPTION="A concise explanation of what the module installs."
SOURCE="github"
CLI="example,example-helper"
```

| Key           | Required | Purpose                                                                                                       |
|---------------|:--------:|---------------------------------------------------------------------------------------------------------------|
| `NAME`        |   Yes    | Human-readable module name.                                                                                   |
| `DESCRIPTION` |   Yes    | Concise user-facing description.                                                                              |
| `SOURCE`      |   Yes    | Installation source: `native`, `ppa`, `apt`, `github`, `external`, or `sourceforge`.                          |
| `CLI`         |    No    | Comma-separated executable names used for default installed-state detection. Every command must be non-empty. |

Omit `CLI` when the module ID basename is the executable name. Add it when the executable differs from that basename or
when all of several commands must be present. Use `installed.sh` instead when command availability alone is not an
accurate installed-state check.

## ⚙️ Commands and Environment

Use command options rather than the deprecated global `NON_INTERACTIVE` and `FORCE_INSTALL` environment variables:

```bash
mp install --non-interactive gui/double-commander
mp install --unattended gui/double-commander
mp install --force cli/git
```

Module-specific environment variables remain supported when their category documentation lists them. Use
`mp install --non-interactive` or `mp install --unattended` to run the whole installation without prompts; no
module-specific non-interactive environment-variable override is supported.

`USE_APT_ADD_REPOSITORY` remains a framework environment variable for modules that support alternate repository setup. A
module may expose a corresponding `*_USE_APT_ADD_REPOSITORY` override.

## 🧰 Framework Libraries

Phase scripts receive `CANONICAL_ID` and can use the framework paths exported by `mp`, including `MP_MODULES`,
`LIB_COMMON`, `LIB_INSTALLER`, and `LIB_WORKFLOW`. `lib/workflow` provides reusable installation steps such as target
resolution, stateful downloading, archive or package installation, state cleanup, and product-specific resolvers.
Source only the helpers a phase needs.

Executable phase files run directly and may select another interpreter through their shebang. Non-executable phase files
run through Bash, so Bash phase scripts must declare their own strict mode:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

## 📝 Module Documentation

Document every module in its category page. Include a concise overview, installation method, every supported environment
variable, relevant installation or registry behavior, System Toolkit integration when applicable, and the official
project link. Omit headings that do not apply.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the complete category and module creation workflow.
