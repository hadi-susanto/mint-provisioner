# 🧰 Mint Provisioner

Mint Provisioner is a modular shell-script framework for automating software installation and system configuration on
Linux Mint.

It provides categorized, self-contained modules with reusable framework libraries, persistent state management,
installation summaries, and interactive or non-interactive provisioning.

Although designed primarily for Linux Mint, many modules may also work on Ubuntu and other Ubuntu-based distributions.

## ⚡ TL;DR

List the available categories:

```bash
mp list category
```

List available modules, optionally filtering by category or installation status:

```bash
mp list modules
mp list modules --category gui --status not-installed
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
environment variables, and configuration details.

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

## 📁 Project Structure

```text
mint-provisioner/
├── mp                                  # Root command dispatcher
├── command/                            # Command implementations
│   ├── main.sh                         # Command routing
│   ├── help.sh                         # Command help
│   ├── list.sh                         # Category and module catalog listings
│   └── install.sh                      # Module installation command
├── lib/                                # Reusable framework libraries
│   ├── common/
│   │   ├── common.sh                   # Logging and shared utilities
│   │   ├── metadata.sh                 # Metadata loading
│   │   ├── resolver.sh                 # Module resolution
│   │   └── script.sh                   # Phase-script execution
│   ├── installer/
│       ├── apt.sh                      # APT and repository helpers
│       ├── detection.sh                # Installation-state detection
│       ├── execution.sh                # Installation lifecycle execution
│       ├── registry.sh                 # Installed-module registry
│       ├── state.sh                    # Persistent module state
│       └── ...                         # Download, path, prompt, and system helpers
│   └── workflow/                       # Reusable module installation workflows
│       ├── install-target.sh           # Resolve and validate installation destinations
│       ├── stateful-downloader.sh      # Download and persist temporary artifacts
│       ├── stateful-*-install.sh       # Shared APT, Debian-package, and archive installation steps
│       └── state-cleaner.sh            # Clean temporary module state
├── modules/                            # Module catalog and lifecycle scripts
│   ├── README.md                       # Catalog and module-authoring documentation
│   ├── CONTRIBUTING.md                 # Category and module contribution guide
│   ├── CLI.md, DEV.md, GUI.md, ...     # Category documentation
│   └── <category>/<module>/            # Self-contained module directories
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
