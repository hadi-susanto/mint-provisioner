# 📦 Mint Provisioner Modules

This directory contains the software modules supported by Mint Provisioner. Each module is a self-contained installation
unit that declares its metadata and owns the scripts needed to detect, prepare, install, and clean up one application or
system component.

For the framework command interface, see the [main project README](../README.md). For instructions on adding or changing
modules, see the [module contributor guide](CONTRIBUTING.md).

## 🗂️ Module Catalog

Mint Provisioner currently provides **107 modules** across **11 categories**. A category is part of a module's canonical
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

| Category                        | ID     | Modules                                                                                                                                                                                                          |
|---------------------------------|--------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Command Line](CLI.md)          | `cli`  | `adb`, `bat`, `delta`, `difftastic`, `eza`, `git`, `github-cli`, `k6`, `mkvtoolnix`, `onedrive`, `openconnect-saml`, `pay-respects`, `procs`, `rclone`, `tlp`, `yq`                                                                  |
| [Database](DB.md)               | `db`   | `dbeaver-community`, `dbgate-community`, `memcached`, `mongodb-community`, `mongodb-compass`, `mysql`, `mysql-tools`, `pg-admin`, `postgresql`, `redis`, `redis-insight`                                                        |
| [Development](DEV.md)           | `dev`  | `apache-maven`, `bruno`, `httptoolkit`, `kafdrop`, `mise`, `postman`, `sdkman`, `yaak`                                                                                                                           |
| [Desktop Applications](GUI.md)  | `gui`  | `avda`, `cryptomator`, `deadbeef`, `desk-otp`, `double-commander`, `flameshot`, `fman`, `insync`, `keepass-xc`, `lapce`, `meld`, `mu-commander`, `onedrive-gui`, `onedriver`, `otpclient`, `sunflower`, `tlp-ui` |
| [IDE](IDE.md)                   | `ide`  | `clion`, `cudatext`, `datagrip`, `geany`, `goland`, `gram`, `idea`, `phpstorm`, `pycharm`, `rider`, `rubymine`, `rustrover`, `vscode`, `vscodium`, `webstorm`                                                    |
| [System Administration](SYS.md) | `sys`  | `apt-fast`, `dconf-editor`, `dnscrypt-proxy`, `nerd-font`, `system-toolkit`                                                                                                                                      |
| [Terminal](TERM.md)             | `term` | `alacritty`, `ghostty`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`, `terminator`, `zsh`                                                                                                                |
| [Terminal UI](TUI.md)           | `tui`  | `bottom`, `du-analyzer`, `du-rust`, `duf`, `git-ui`, `lazy-git`                                                                                                                                                  |
| [Web](WEB.md)                   | `web`  | `brave-browser`, `brave-origin`, `firefox`, `firefox-pwa`, `google-chrome`, `librewolf`, `microsoft-edge`                                                                                                        |
| [DevOps Tools](OPS.md)          | `ops`  | `argocd`, `cloudflared`, `consul`, `docker`, `gcloud`, `k9s`, `kubectl`, `mkcert`, `vault`                                                                                                                                         |
| [Miscellaneous](MISC.md)        | `misc` | `any-desk`, `claude-code`, `codex`, `junie`, `virtual-box`                                                                                                                                                       |

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
        ├── latest.sh                   # Latest available version; required by UPDATE_MODE="external"
        ├── interactive.sh              # Optional interactive pre-install questions or customization
        ├── non-interactive.sh          # Alternative setup for --non-interactive; requires interactive.sh
        ├── pre-install.sh              # Optional installation preparation
        ├── install.sh                  # Required software installation
        ├── post-install.sh             # Optional post-install adjustment
        ├── cleanup.sh                  # Optional temporary-resource cleanup
        ├── remove.sh                   # Removal phase for mp remove|uninstall|purge
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

`mp upgrade` upgrades `UPDATE_MODE="apt"` modules with `apt-get install --only-upgrade` and, for `github`,
`external`, and `git` modules that ship `upgrade.sh`, runs `pre-upgrade.sh → upgrade.sh → cleanup.sh` (see "Upgrade
Phases" in `modules/AGENTS.md`). Install, interactive, and post-install phases do not run again.

`mp remove` (alias `mp uninstall`) and `mp purge` run only the module's `remove.sh`, with `PURGE=true` for purge (after the
user types `PURGE` to confirm). The framework deletes the module's registry after `remove.sh`
succeeds, except on a plain remove that kept a registry-recorded data directory (`DATA_RETAINED=1`), so a later
`mp purge` can still find it. `remove.sh` composes the helpers in `lib/remover/` (see "Removal" in `modules/AGENTS.md`).

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

| Phase                | Required | Responsibility                                                                                               |
|----------------------|:--------:|--------------------------------------------------------------------------------------------------------------|
| `installed.sh`       |    No    | Determine installed state when the default command detection is insufficient.                                |
| `interactive.sh`     |    No    | Collect required answers or apply user-selected installation customization before installation starts.       |
| `non-interactive.sh` |    No    | Provide the non-prompt equivalent of `interactive.sh`; valid only when `interactive.sh` exists.              |
| `pre-install.sh`     |    No    | Prepare repositories, dependencies, downloads, keys, or temporary files.                                     |
| `install.sh`         |   Yes    | Perform the software installation and save durable installation facts when needed.                           |
| `post-install.sh`    |    No    | Apply an installation-adjacent adjustment after a successful installation.                                   |
| `cleanup.sh`         |    No    | Remove temporary state, downloads, and intermediate files; also runs after `mp upgrade` phases.              |
| `pre-upgrade.sh`     |    No    | Download the new release for `mp upgrade` into the states `upgrade.sh` reads.                                |
| `upgrade.sh`         |    No    | Replace installed files and record `VERSION` for `mp upgrade`; required for `github`/`external`/`git`.       |
| `remove.sh`          |    No    | Undo the installation for `mp remove`, `mp uninstall`, and `mp purge`; modules without it cannot be removed. |
| `latest.sh`          |    No    | Print the latest available version for `mp outdated` and `pre-install.sh` (`UPDATE_MODE="external"`).        |

### Version tracking (`mp outdated`)

`mp outdated` (alias `mp update`) lists installed modules with their installed and latest versions; it never
upgrades anything. Each module declares how its versions are found with `UPDATE_MODE` in `metadata.conf`:

| `UPDATE_MODE` | Installed version                                    | Latest version                                       |
|---------------|------------------------------------------------------|------------------------------------------------------|
| `apt`         | dpkg version of each installed `UPDATE_PACKAGE`      | APT candidate (offers `apt-get update` after 7 days) |
| `github`      | Registry `VERSION` recorded at install time          | Latest release tag of `UPDATE_REPOSITORY`            |
| `external`    | Registry `VERSION` recorded at install time          | Output of the module's `latest.sh`                   |
| `git`         | Commit of the clone at registry `INSTALL_PATH`       | Latest commit of the same branch on `origin`         |
| `none`        | Not tracked (`-`)                                    | Not tracked (`-`)                                    |

For `github` and `external`, `pre-install.sh` passes the downloaded version to `stateful_download` and the install
workflows record it as registry `VERSION`. Installs that predate this have no recorded version and are reported as
having an update available. `latest.sh` must be read-only, print one version line to stdout, and stay silent on
success. See "Latest Version Detection" in [AGENTS.md](AGENTS.md) for the full contract.

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

When a module needs durable facts such as an installation path, version (`VERSION`, read by `mp outdated`), or managed
component list, its installation
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
UPDATE_MODE="github"
UPDATE_REPOSITORY="example/example-app"
```

| Key                 | Required | Purpose                                                                                                       |
|---------------------|:--------:|---------------------------------------------------------------------------------------------------------------|
| `NAME`              |   Yes    | Human-readable module name.                                                                                   |
| `DESCRIPTION`       |   Yes    | Concise user-facing description.                                                                              |
| `SOURCE`            |   Yes    | Installation source: `native`, `ppa`, `apt`, `github`, `external`, or `sourceforge`.                          |
| `CLI`               |    No    | Comma-separated executable names used for default installed-state detection. Every command must be non-empty. |
| `UPDATE_MODE`       |    No    | `mp outdated` version tracking: `apt`, `github`, `external`, `git`, or `none`; every catalog module sets it.  |
| `UPDATE_PACKAGE`    |   apt    | Debian package(s) to check; comma-separated candidates without spaces, every installed one counts.            |
| `UPDATE_REPOSITORY` |  github  | `owner/repo` whose latest release tag is the latest version.                                                  |

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
`LIB_COMMON`, `LIB_INSTALLER`, `LIB_WORKFLOW`, and `LIB_UPDATER`. `lib/workflow` provides reusable installation steps such as target
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
