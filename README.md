# 🧰 Mint Provisioner

Mint Provisioner is a modular shell-script framework for automating software installation and system configuration on
Linux Mint.

It provides categorized, self-contained modules with reusable framework libraries, persistent state management,
installation summaries, and interactive or non-interactive provisioning.

Although designed primarily for Linux Mint, many modules may also work on Ubuntu and other Ubuntu-based distributions.

## ⚡ TL;DR

Install Mint Provisioner into `./mint-provisioner` (run it from the folder that should hold it, as your normal user):

```bash
curl -fsSL https://raw.githubusercontent.com/hadi-susanto/mint-provisioner/main/bootstrap.sh | bash
```

The bootstrap installs missing dependencies (`git`, `jq`, `aria2`, `curl`, `bash-completion`) with `apt-get`, clones
the repository over SSH when your GitHub key is authorized (HTTPS otherwise), links `mp` to `/usr/local/bin/mp`, and
sets up bash completion. It asks for your `sudo` password for the package install and the link. Run it again to
update an existing clone (`git pull --ff-only`).

To try another branch, fetch the script from that branch and set `MP_BRANCH` for the clone:

```bash
curl -fsSL https://raw.githubusercontent.com/hadi-susanto/mint-provisioner/<branch>/bootstrap.sh | MP_BRANCH=<branch> bash
```

List the available categories:

```bash
mp list category
```

List available modules, optionally filtering by category or installation status:

```bash
mp list modules
mp list modules --category gui --status not-installed
```

Preview what an install would do, then confirm to continue with the installation (default no):

```bash
mp plan git gui/flameshot term/kitty
```

Install modules using their canonical `<category>/<module>` or unique short `<module>` IDs:

```bash
mp install <module> [<module>...]
mp install <category>/<module> [<category>/<module>...]
```

Both ID formats can be combined:

```bash
mp install git gui/flameshot term/kitty
```

If a short module ID resolves to multiple canonical IDs, installation stops and asks you to use a canonical ID.

See the [module catalog and documentation](modules/README.md) for available modules, installation methods, supported
environment variables, and configuration details. See the [FAQ](FAQ.md) for common issues and solutions.


## 🌱 Project Origin

Mint Provisioner is a modular evolution of the earlier [os-customizer](https://github.com/hadi-susanto/os-customizer)
project.

The original framework stored installers as individual files inside a flat `installers/` directory. Each installer was
sourced into a single runner and had to expose several specially named functions.

Mint Provisioner replaces that design with categorized, self-contained modules, isolated phase scripts, reusable
framework libraries, persistent state management, and the `mp` command interface for catalog discovery and module
installation.

The project was designed and supervised by [Hadi Susanto](https://id.linkedin.com/in/hadisusanto). Its implementation
and refinement were completed with assistance from **ChatGPT** and **Junie by JetBrains**.

## ✨ Key Improvements

Compared with `os-customizer`, Mint Provisioner introduces the following improvements:

| Area                  | `os-customizer`                                                  | Mint Provisioner                                                           |
|-----------------------|------------------------------------------------------------------|----------------------------------------------------------------------------|
| Module organization   | Flat collection of installer files                               | Categorized, self-contained module directories                             |
| Module interface      | Specially named functions inside sourced files                   | Independent lifecycle scripts with standard filenames                      |
| Required phases       | Every installer had to implement the complete function interface | Only `install.sh` is mandatory                                             |
| Interactive setup     | Coupled to pre-install and post-install functions                | Optional `interactive.sh` completes for queued modules before installation |
| Command interface     | Installer execution from a single runner                         | `mp list` for catalog discovery and `mp install` for provisioning          |
| Module identification | Installer filename                                               | Canonical `<category>/<module>` ID                                         |
| Metadata              | Description functions and static arrays                          | Declarative category and module `metadata.conf` files                      |
| State handling        | Installer-specific variables and files                           | Shared persistent state library                                            |
| User messages         | Printed directly by individual installers                        | Stored, grouped, and displayed in the installation summary                 |
| Reusable operations   | Repeated inside installer scripts                                | Shared libraries for APT, repositories, downloads, prompts, and more       |
| Execution             | Installer files sourced into the main shell                      | Phase scripts executed in isolated processes                               |
| Automation            | Primarily interactive                                            | Interactive and non-interactive execution                                  |
| Cleanup               | Installer-specific and inconsistent                              | Standard optional `cleanup.sh` phase                                       |
| Reporting             | Basic success and failure lists                                  | Per-module status, timing, metadata, and post-install messages             |
| Extensibility         | One large installer file per application                         | Module directories may contain helpers, payloads, and executable scripts   |

Executable phase files may use another interpreter through their shebang, such as Python. Non-executable phase files are
executed as Bash scripts with strict error handling.

## 🧭 Framework Entry Point

### List All Categories

```bash
mp list category
```

### List All Modules

```bash
mp list modules [options]
```

| Option                        | Description                                                          |
|-------------------------------|----------------------------------------------------------------------|
| `-c`, `--category <category>` | Limit results to a category. May be supplied more than once.         |
| `-s`, `--status <status>`     | Filter by `all`, `installed`, or `not-installed`. Defaults to `all`. |

### Install Modules

```bash
mp install <module> [options]
```

| Option                     | Description                                                                                  |
|----------------------------|----------------------------------------------------------------------------------------------|
| `-f`, `--force`            | Process modules even when installed-state detection reports them as installed.               |
| `-ni`, `--non-interactive` | Run module interactive setup without prompts, using supplied values, detection, or defaults. |
| `--unattended`             | Alias for `--non-interactive`.                                                               |

`<module>` may be a canonical module ID, a unique short module ID, or a registered alias. Do not run `mp install` with
`sudo` or as root; module installers invoke `sudo` only when required.

### Preview an Installation

```bash
mp plan <module> [options]
```

Accepts the same `-f`/`--force` and `-ni`/`--non-interactive`/`--unattended` options as `mp install`. Resolves the
modules, runs installed-state detection, and prints each module's action (`install`, `reinstall`, `skip`, `blocked`, or
`error`), `SOURCE`, the phases that would run, and notes. Detection never prompts, installs, or uses `sudo`. Exits `1`
when a module is blocked (no non-interactive support under `-ni`) or detection fails.

When modules are queued, nothing is blocked, and a terminal is attached, `mp plan` then asks
`Continue with installation? [y/N]` (default no). Answering yes runs `mp install` with the same modules and options.
Piped or redirected runs only print the plan.

### Check for Updates

```bash
mp outdated [module...]          # alias: mp update
mp outdated --async N [module...]  # N background workers (default 6, max 9); alias: --batch
mp outdated --porcelain          # stdout: MODULE<TAB>INSTALLED<TAB>LATEST per update; table on stderr
```

Lists installed modules (or only the selected ones) as a `NAME CURRENT LATEST NOTE` table. The latest version is green
when an update is available; versions that cannot be resolved show `[unknown]`.
Nothing is upgraded. Modules with `UPDATE_MODE="apt"` read versions from dpkg and the APT cache; when apt-mode modules are
checked, the cache is older than 7 days, and a terminal is attached, `mp outdated` offers to run `sudo apt-get update`
first. Modules with `UPDATE_MODE="github"` compare the release recorded at install time with the latest GitHub
release; installs that predate version recording are reported as having an update available. Unauthenticated GitHub
API calls are limited to 60 per hour, so set `GITHUB_TOKEN` when checking many modules. Modules with
`UPDATE_MODE="external"` compare the recorded version with the vendor's latest version printed by the module's
`latest.sh`. Modules with `UPDATE_MODE="git"` compare the cloned commit with the latest commit of the same branch,
and `UPDATE_MODE="none"` marks modules whose version is not tracked. Modules are inspected by a pool of background
workers that share one queue (6 by default; `--async N` or `--batch N` sets 1-9), which shortens runs dominated by
network lookups; each worker shows its current module on its own line, and module logs are printed after inspection.
`--porcelain` prints only
modules with an available update to stdout (tab-separated module, installed and latest version), sends the table and
every other message to stderr, and never prompts. Exits `1` when detection or a version query fails.

### Upgrade Modules

```bash
mp upgrade [module...]           # all installed modules with an update, or only the selected ones
mp upgrade -y [module...]        # skip the confirmation (sudo must be cached or passwordless)
```

Runs `mp outdated --porcelain` to find modules with an available update, lists them, asks
`Upgrade N module(s)? [y/N]`, then upgrades them one at a time and prints a result summary. Module install scripts are
not run again. Upgrades are dispatched on `UPDATE_MODE`: for `apt`, every installed `UPDATE_PACKAGE` candidate is
upgraded with `apt-get install --only-upgrade` (`apt-fast` when available); for `github` and `external`, the module's
`pre-upgrade.sh` downloads the new release and `upgrade.sh` replaces the installed files in place (desktop entries,
symlinks, and user configuration are kept) and records the new version. An application still running from its install
directory (for example a JetBrains IDE) is not replaced; close it and run `mp upgrade` again. For `git`, `upgrade.sh`
moves the clone to the latest commit of its branch; a clone with local edits to tracked files is left untouched.
Modules without `upgrade.sh` are reported as not upgradable yet. A stale APT cache (older than 7 days) is offered for
refresh first; `-y` refreshes it without asking.
Without a terminal, `-y` is required. Exits `1` when an upgrade, detection, or version query fails.

### Remove Modules

```bash
mp remove <module> [options]     # alias: mp uninstall
mp purge <module> [options]      # remove plus well-known configuration
```

| Option               | Description                                                                         |
|----------------------|-------------------------------------------------------------------------------------|
| `-f`, `--force`      | Process modules even when installed-state detection reports them as not installed.  |
| `-h`, `--help`       | Show help for `remove` (or `purge`) and exit.                                       |

`purge` runs the module's `remove.sh` with `PURGE=true` and implies `--force`. A module supports removal only when it
ships `remove.sh`; otherwise it is reported as failed. Do not run these commands with `sudo` or as root.

Interactive questions use `whiptail` dialogs when `whiptail` is installed. Set `DISABLE_WHIPTAIL=true` to force
plain-text prompts (see the [FAQ](FAQ.md)).

### Shell Completion

Tab completion covers commands, options, `list` targets, categories and statuses, and module IDs (canonical IDs,
unique short IDs, and aliases). It requires `mp` on your `PATH`. The bootstrap installer sets up bash completion
automatically and prints the zsh lines when zsh is your login shell.

Bash: add to `~/.bashrc` (or link the file into `~/.local/share/bash-completion/completions/mp`):

```bash
source /path/to/mint-provisioner/completion/mp.bash
```

Zsh: add to `~/.zshrc` before `compinit`:

```zsh
fpath=(/path/to/mint-provisioner/completion $fpath)
autoload -Uz compinit && compinit
```

## 📁 Project Structure

```text
mint-provisioner/
├── mp                                  # Root command dispatcher
├── bootstrap.sh                        # curl | bash installer: dependencies, clone, /usr/local/bin/mp, completion
├── completion/                         # Shell completion
│   ├── mp.bash                         # Bash completion
│   └── _mp                             # Zsh completion
├── command/                            # Command implementations
│   ├── main.sh                         # Command routing
│   ├── complete.sh                     # Hidden 'mp __complete' candidates for shell completion
│   ├── help.sh                         # Command help
│   ├── list.sh                         # Category and module catalog listings
│   ├── install.sh                      # Module installation command
│   ├── plan.sh                         # Read-only installation preview
│   ├── outdated.sh                     # Installed vs latest versions (outdated, update)
│   ├── OUTDATED.md                     # How the 'mp outdated' worker pool works
│   ├── upgrade.sh                      # Upgrade outdated modules (UPDATE_MODE=apt, github)
│   └── remove.sh                       # Module removal command (remove, uninstall, purge)
├── lib/                                # Reusable framework libraries
│   ├── common/
│   │   ├── common.sh                   # Logging and shared utilities
│   │   ├── install-plan.sh             # Install/skip/reinstall decisions shared by install and plan
│   │   ├── metadata.sh                 # Metadata loading
│   │   ├── resolver.sh                 # Module resolution
│   │   ├── run-report.sh               # Per-module banners, timing, and result summaries
│   │   ├── script.sh                   # Phase-script execution
│   │   └── sudo.sh                     # Sudo privilege caching and validation
│   ├── remover/
│   │   ├── apt.sh                      # Remove PPAs and APT repository files (purge only)
│   │   ├── binary.sh                   # Remove symlinks, PATH entries, and install directories
│   │   ├── data.sh                     # Delete service data directories (purge only)
│   │   ├── desktop.sh                  # Remove desktop entries and icons
│   │   ├── execution.sh                # Removal lifecycle execution
│   │   ├── filter.sh                   # Select modules to remove
│   │   ├── home.sh                     # Purge lingering files under $HOME (purge only)
│   │   ├── jetbrains.sh                # Purge per-version JetBrains product directories
│   │   ├── package.sh                  # Remove or purge Debian packages
│   │   └── system.sh                   # Remove generated system files (APT pins, launchers)
│   ├── installer/
│   │   ├── apt.sh                      # APT and repository helpers
│   │   ├── desktop-integration.sh      # Generated desktop entries and icons
│   │   ├── detection.sh                # Installation-state detection
│   │   ├── execution.sh                # Installation lifecycle execution
│   │   ├── registry.sh                 # Installed-module registry
│   │   ├── state.sh                    # Persistent module state
│   │   └── ...                         # Download, path, prompt, and system helpers
│   ├── updater/                        # Version lookups and upgrades for mp outdated and mp upgrade
│   │   ├── versioning.sh               # Dispatch on UPDATE_MODE (apt, github, external, git, none)
│   │   ├── upgrader.sh                 # Upgrade dispatch on UPDATE_MODE (apt, github, external, git)
│   │   ├── execution.sh                # Upgrade lifecycle: pre-upgrade, upgrade, cleanup
│   │   ├── apt-versioning.sh           # dpkg installed version, APT candidate, cache age and refresh
│   │   ├── recorded-versioning.sh      # Registry VERSION recorded at install time
│   │   └── git-versioning.sh           # Cloned commit vs remote branch commit
│   └── workflow/                       # Reusable module installation workflows
│       ├── install-target.sh           # Resolve and validate installation destinations
│       ├── stateful-downloader.sh      # Download and persist temporary artifacts
│       ├── stateful-*-install.sh       # Shared APT, Debian-package, and archive installation steps
│       ├── stateful-*-upgrade.sh       # In-place Debian-package, archive, and binary upgrade steps
│       ├── latest-version.sh           # Run a module's latest.sh (pre-install and mp outdated)
│       ├── version-registry.sh         # Record the installed VERSION in the registry
│       ├── jetbrains-*.sh              # Shared JetBrains IDE workflow phases, release lookup, and download
│       ├── hashicorp-download.sh       # Download and verify a HashiCorp release binary (Consul, Vault)
│       ├── git-pull-upgrade.sh         # Fast-forward a git clone to its branch tip, or back on failure
│       ├── state-cleaner.sh            # Clean temporary module state
│       └── <category>/<module>/        # Product-specific resolvers and installers
├── modules/                            # Module catalog and lifecycle scripts
│   ├── README.md                       # Catalog and module-authoring documentation
│   ├── CONTRIBUTING.md                 # Category and module contribution guide
│   ├── CLI.md, DEV.md, GUI.md, ...     # Category documentation
│   └── <category>/<module>/            # Self-contained module directories
├── AGENTS.md, FAQ.md                   # Contributor/agent guidelines and troubleshooting
└── README.md
```

For module directory structure, lifecycle phases, authoring requirements, and design guidance, see [
`modules/README.md`](modules/README.md).

## 🙏 Credits

Mint Provisioner is designed and supervised by [Hadi Susanto](https://id.linkedin.com/in/hadisusanto).

Implementation and refinement were completed with assistance from:

- **ChatGPT** by OpenAI
- **Junie** by JetBrains

Mint Provisioner is based on ideas developed in the
earlier [os-customizer](https://github.com/hadi-susanto/os-customizer) project.
