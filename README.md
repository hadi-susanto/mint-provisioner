# Mint Provisioner

A modular shell script framework for automating software installation and system configuration on Linux Mint.

This framework is a modular revamp of [os-customizer](https://github.com/hadi-susanto/os-customizer/). While the code was brought to life with the assistance of **Junie** (by JetBrains) and **ChatGPT**, the core ideas and supervision come from [Hadi Susanto](https://id.linkedin.com/in/hadisusanto) 🔗.

## 🌟 Key Improvements

Compared to the original `os-customizer`, this framework offers:

*   **Higher Modularity**: A cleaner separation of concerns between core logic and module definitions.
*   **Flexible Installers**: Modules can now use non-bash scripts (e.g., Python, Go, or binaries) as long as they are executable.
*   **Streamlined Lifecycle**: Mandatory phases have been reduced to just `is_installed.sh` and `install.sh`.
*   **Greater Capability**: Each module has a dedicated directory for payloads, scripts, and multi-phase execution.

## 🚀 Overview

Mint Provisioner is designed to simplify the post-installation setup of Linux Mint. It uses a phase-based module system to ensure that software is installed only when necessary and provides a set of helpers to handle common tasks like PPA management, GPG keys, and GitHub release downloads.

## 🏗️ Project Structure

```text
.
├── configure.sh               # Configuration entry point
├── install.sh                 # Installation entry point
├── lib/                       # Core framework libraries
│   ├── common.sh              # Logging and utility functions
│   ├── distro.sh              # OS and Upstream detection
│   ├── installer_apt.sh       # APT, PPA, and GPG key helpers
│   ├── installer_external.sh  # GitHub release and URL downloaders
│   ├── metadata_parser.sh     # Module config parsing
│   ├── module_configurer.sh   # Configuration management logic
│   └── module_installer.sh    # Installation lifecycle logic
└── modules/                   # Software modules
    └── <module-name>/
        ├── metadata.conf      # Module information (Name, Source, Desc)
        ├── is_installed.sh    # Check if software exists (Mandatory)
        ├── pre_install.sh     # Prerequisites (Optional)
        ├── install.sh         # Core installation (Mandatory)
        ├── post_install.sh    # Configuration (Optional)
        └── cleanup.sh         # Post-install cleanup (Optional)
```

## 🔄 Installation Lifecycle

Each module follows a strict execution flow:

1.  **`is_installed.sh`**: Checks if the package is already installed. If it exits with `0`, the module is skipped unless `FORCE_INSTALL=true` is set.
2.  **`pre_install.sh`**: Handles APT repositories, PPA additions, or dependency setup.
3.  **`install.sh`**: The main installation command.
4.  **`post_install.sh`**: Performs customization and configuration.
5.  **`cleanup.sh`**: Removes temporary installation files.

## 🛠️ Usage

### List available modules
Run the script without arguments to see what can be installed:
```bash
./install.sh
```

### Install specific modules
Pass the module directory names as arguments:
```bash
./install.sh <module> [module...]
```

### Configure modules
Re-run configuration for installed modules:
```bash
./configure.sh <module> [module...]
```
If no arguments are provided, it will prompt to iterate through all available modules.

### Administrative Privileges
The framework requires `sudo` for most operations. If not running as root, `install.sh` will prompt to escalate privileges.

## ⚙️ Configuration

The framework and modules can be configured via environment variables.

### Global Variables
*   `FORCE_INSTALL=true`: Forces reinstallation of modules even if they are already detected as installed.
*   `INSTALL_DIR`: The base directory where external software is installed (defaults to the parent directory of the project root).

### Module-Specific Variables
Many modules support override variables (e.g., `STARSHIP_REGEX`). See [MODULES.md](MODULES.md) for a full list of available modules and their specific configuration options.

## ➕ Adding a New Module

1.  Create a new directory in `modules/`.
2.  Add a `metadata.conf` with `NAME`, `DESCRIPTION`, and `SOURCE`.
3.  Implement `is_installed.sh` (must return `0` if installed, `1` if not).
4.  Implement `install.sh`.
5.  (Optional) Add `pre_install.sh` for repositories or `post_install.sh` for configuration.

### Example `metadata.conf`:
```ini
NAME="MyTool"
DESCRIPTION="A cool utility"
SOURCE="apt"
```

## 🧰 Library Helpers

The framework provides powerful helpers in `lib/`:

*   **APT/PPA**: `add_ppa_repository`, `fetch_and_install_asc_key`, `apt_install`.
*   **External**: `github_find_latest_release`, `download_from_url`.
*   **Distro**: `get_mint_version`, `get_mint_codename`, `get_ubuntu_version`, `get_ubuntu_codename`.
*   **Common**: `can_write`, `run_script`, `is_admin`, `get_user_home`.

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---
*Idea and supervision by [Hadi Susanto](https://id.linkedin.com/in/hadisusanto) 🔗. Implementation assisted by Junie & ChatGPT.*
