# Mint Provisioner

A modular shell script framework for automating software installation and system configuration on Linux Mint.

This framework is a modular revamp of [os-customizer](https://github.com/hadi-susanto/os-customizer/). While the code
was brought to life with the assistance of **Junie** (by JetBrains) and **ChatGPT**, the core ideas and supervision come
from [Hadi Susanto](https://id.linkedin.com/in/hadisusanto) 🔗.

## 🌟 Key Improvements

Compared to the original `os-customizer`, this framework offers:

* **Higher Modularity**: A cleaner separation of concerns between core logic and module definitions.
* **Flexible Installers**: Modules can use non-Bash scripts, such as Python, Go, or executable binaries.
* **Streamlined Lifecycle**: Only `is_installed.sh` and `install.sh` are mandatory. All other module phases are
  optional.
* **Pre-install Configuration**: Modules can collect and validate required configuration before any installation check
  or installation begins.
* **Greater Capability**: Each module has a dedicated directory for payloads, scripts, and multi-phase execution.

## 🚀 Overview

Mint Provisioner is designed to simplify the post-installation setup of Linux Mint.

It uses a phase-based module system to install software only when necessary and provides reusable helpers for common
operations such as APT repository management, GPG key installation, GitHub release downloads, interactive prompts, and
persistent module state.

The framework provides two primary entry points:

* `install.sh` installs one or more software modules.
* `configure.sh` applies or reapplies the post-install configuration of installed modules.

## 🏗️ Project Structure

```text
.
├── configure.sh               # Post-install configuration entry point
├── install.sh                 # Software installation entry point
├── lib/                       # Core framework libraries
│   ├── common.sh              # Logging and utility functions
│   ├── distro.sh              # OS and upstream distribution detection
│   ├── installer_apt.sh       # APT, PPA, and GPG key helpers
│   ├── installer_common.sh    # Common installation and shell integration helpers
│   ├── installer_external.sh  # GitHub release and URL download helpers
│   ├── messages.sh            # Messaging helpers, used to store post install messages
│   ├── metadata_parser.sh     # Module metadata parsing
│   ├── module_configurer.sh   # Post-install configuration lifecycle
│   ├── module_installer.sh    # Installation lifecycle
│   ├── prompt.sh              # Interactive terminal prompt helpers
│   └── state.sh               # Persistent framework state management
└── modules/                   # Software modules
    └── <category-name>/
        └── <module-name>/
            ├── metadata.conf          # Module information
            ├── configuration.sh       # Collect installation configuration (Optional)
            ├── is_installed.sh        # Check whether software is installed (Mandatory)
            ├── pre_install.sh         # Prepare installation prerequisites (Optional)
            ├── install.sh             # Perform software installation (Mandatory)
            ├── post_install.sh        # Apply software configuration (Optional)
            └── cleanup.sh             # Remove temporary installation files (Optional)
```

## 🔄 Installation Lifecycle

The installation process is divided into two stages.

### Stage 1: Module Configuration

Before checking whether any module is already installed, `install.sh` executes the optional `configuration.sh` phase for
every selected module.

All selected modules must complete this stage successfully before the framework proceeds.

The optional `configuration.sh` phase prepares all configuration required by a module before installation processing
begins.

Typical uses include:

* Asking the user which software variant to install, such as GTK, Qt 5, or Qt 6.
* Asking whether an optional GUI component should be enabled.
* Reading values from an external input or configuration file.
* Automatically selecting suitable installation options.
* Validating configuration before installation.
* Saving selected values in framework state for use by later phases.

The configuration phase can support both interactive and non-interactive execution.

When `NONINTERACTIVE=true`, a module should avoid prompting the user and instead automatically select an appropriate
default or derive the required value from the environment or another configuration source.

### Stage 2: Module Installation

After every configuration phase succeeds, each selected module follows this installation lifecycle:

1. **`is_installed.sh`** – Determines whether the software is already installed.
2. **`pre_install.sh`** *(Optional)* – Prepares repositories, GPG keys, dependencies, or other prerequisites.
3. **`install.sh`** – Performs the software installation.
4. **`post_install.sh`** *(Optional)* – Applies post-install customization and configuration.
5. **`cleanup.sh`** *(Optional)* – Removes temporary files and performs cleanup.

If `is_installed.sh` exits with `0`, the module is skipped unless `FORCE_INSTALL=true` is set.

### Execution Order

When `install.sh` is executed, the framework performs the following sequence:

1. Resolve all requested modules.
2. Execute `configuration.sh` for every selected module that provides it.
3. Abort the entire operation if any configuration phase fails.
4. Execute `is_installed.sh` for the first module.
5. If required, execute that module's `pre_install.sh`, `install.sh`, `post_install.sh`, and `cleanup.sh`.
6. Continue the installation lifecycle for each remaining module.

Therefore, **all module configuration phases run before any module's `is_installed.sh` phase**.

This ensures that every required choice and configuration value is available before the framework checks installation
status or modifies the system.

If any `configuration.sh` script exits with a non-zero status, the entire installation is aborted. No module
installation check or installation phase is executed.

> [!IMPORTANT]
> The module phase `configuration.sh` and the framework entry point `configure.sh` are separate concepts and serve
> different purposes.

| `configuration.sh`                                                              | `configure.sh`                                                      |
|---------------------------------------------------------------------------------|---------------------------------------------------------------------|
| Optional phase inside a module.                                                 | Top-level framework entry point similar to `install.sh`.            |
| Called by `install.sh`.                                                         | Called directly by the user.                                        |
| Runs before every module's `is_installed.sh`.                                   | Does not participate in the installation lifecycle.                 |
| Collects or automatically selects values required for installation.             | Executes the `post_install.sh` phase of selected installed modules. |
| May prompt for choices such as GUI support or software variants.                | Applies or reapplies software configuration after installation.     |
| Should avoid prompting and select suitable defaults when `NONINTERACTIVE=true`. | Is never called by `install.sh`.                                    |
| Failure aborts the complete installation before any installation check begins.  | Operates independently from `install.sh`.                           |

## 🛠️ Usage

### Installer (`install.sh`)

Main entry point for the framework, used to install and configure software modules. For available options or arguments
please invoke `install.sh --help`.

```bash
./install.sh --help
```

### Configurer (`configure.sh`)

Main entry point for the framework, used to configure installed software modules. For available options or arguments please
invoke `configure.sh --help`.

```bash
./configure.sh --help
```
### Administrative Privileges

Most installation operations require administrative privileges.

When necessary, the framework uses `sudo` to perform privileged operations.

## 📦 Modules

Mint Provisioner supports a wide variety of software modules.

See [modules/README.md](modules/README.md) for the complete module catalog.

## 🧰 Library Helpers

The framework provides reusable helper libraries under `lib/`.

| Library                 | Purpose                                                                                          |
|-------------------------|--------------------------------------------------------------------------------------------------|
| `common.sh`             | Logging, script execution, privilege detection, filesystem checks, and common utility functions. |
| `distro.sh`             | Linux Mint, Ubuntu, and upstream distribution detection.                                         |
| `installer_apt.sh`      | APT package installation, repository management, PPAs, and GPG keys.                             |
| `installer_common.sh`   | Shared installation and shell integration helpers.                                               |
| `installer_external.sh` | GitHub release discovery and generic file downloads.                                             |
| `metadata_parser.sh`    | Reading and parsing module metadata.                                                             |
| `module_configurer.sh`  | Executing module `post_install.sh` phases through `configure.sh`.                                |
| `module_installer.sh`   | Coordinating module configuration and installation lifecycles.                                   |
| `prompt.sh`             | Interactive option selection, confirmation, and terminal input helpers.                          |
| `state.sh`              | Persistent key-value state shared between module phases.                                         |

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

*Idea and supervision by [Hadi Susanto](https://id.linkedin.com/in/hadisusanto) 🔗. Implementation assisted by Junie (
JetBrains) and ChatGPT.*
