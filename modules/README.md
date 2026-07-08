# 📦 Modules

This directory contains all software modules supported by the Linux Mint Provisioner.

Each subdirectory represents a single software module responsible for installing and, where applicable, configuring a specific application. A module is self-contained and typically includes the scripts and resources required to perform the installation and post-install configuration.

Typical module structure:

```text
modules/                # Root moduless directory
└── <category-name>/    # Category directory
    ├── git
    ├── lazy-git
    ├── sdkman
    └── (more) ...
```

## 🗂️ Module Categories

As the number of supported modules continues to grow, they are grouped into categories to make the documentation easier to navigate. Categories are intended solely for documentation purposes and do not affect how modules are installed.

Currently available categories:

* [Software Engineering](./SOFTWARE-ENGINEERING.md)
* Terminal Experience
* [System Administration](./SYSTEM-ADMINISTRATION.md)
* Desktop Utilities

Refer to the corresponding category document for detailed information about each module, including:

* Module overview
* Installation method
* Supported environment variables
* Automatic post-install configuration
* External project website

## ➕ Adding a New Module

1.  Create a new directory in `modules/<category-name>/`.
2.  Add a `metadata.conf` with `NAME`, `DESCRIPTION`, and `SOURCE`.
3.  Implement `is_installed.sh` (must exit with `0` if installed, `1` if not).
4.  Implement `install.sh`.
5.  (Optional) Add `pre_install.sh` for preparing installation (downloading artifact)
6.  (Optional) Add `post_install.sh` for configuration after installation. Be warn that `configure.sh` will execute this script automatically without execute other phases.

### Example `metadata.conf`:
```ini
NAME="MyTool"
DESCRIPTION="A cool utility"
SOURCE="apt"
```

---

# Global Environment Variables

Several global environment variables can be used to customize the behavior of all supported modules.

## `USE_APT_ADD_REPOSITORY`

Controls how APT repositories are added when a module requires an external repository.

When enabled, modules use `add-apt-repository` whenever possible.

When disabled, repository configuration is performed manually by creating the corresponding APT source files.

Default:

```text
true
```

---

## `SKIP_CONFIGURATION`

Skips all automatic post-install configuration.

When enabled, software is installed normally, but the provisioner will not:

* Copy configuration files
* Register Bash integration
* Register Zsh integration
* Install shell aliases
* Install shell functions

This is useful if you prefer to configure applications manually.

Default:

```text
false
```

---

## `FORCE_CONFIGURATION`

Controls whether existing configuration files should be overwritten.

When disabled, existing user configuration is preserved.

When enabled, configuration files managed by the provisioner are replaced.

Default for `install.sh` scripts:

```text
false
```

Default for `configure.sh` scripts:

```text
true
```

---

# Common Module Environment Variables

Many modules expose additional environment variables to customize their installation. To keep the framework consistent, similar variables share the same naming convention.

For a module named `example-module`, the variables below become:

```text
EXAMPLE_MODULE_*
```

---

## `*_USE_APT_ADD_REPOSITORY`

Overrides the global `USE_APT_ADD_REPOSITORY` setting for a specific module.

This is useful when you want only selected modules to use `add-apt-repository` while keeping the global default unchanged.

Example:

```text
JAVA_USE_APT_ADD_REPOSITORY=true
```

---

## `*_REGEX`

Specifies the regular expression used to locate downloadable assets.

This is commonly used for modules that retrieve the latest release from GitHub or another download page.

Example:

```text
LAZY_GIT_REGEX=lazygit_.*_linux_x86_64\.tar\.gz$
```

---

## `*_SUFFIX`

Specifies an optional filename suffix used when selecting downloadable assets.

Some software publishes multiple builds (for example, architecture-specific or distribution-specific archives). This variable allows a module to select the appropriate asset.

Not all modules support this variable.

---

## `*_INSTALL_DIR`

Specifies the installation directory for a module.

This is primarily used by modules installed from standalone archives instead of the system package manager.

Example:

```text
DELTA_INSTALL_DIR=/opt/tools/delta
```

---

## `*_SKIP_CONFIGURATION`

Overrides the global `SKIP_CONFIGURATION` setting for an individual module.

When enabled, only that module skips automatic post-install configuration.

Example:

```text
DELTA_SKIP_CONFIGURATION=true
```

---

## `*_FORCE_CONFIGURATION`

Overrides the global `FORCE_CONFIGURATION` setting for an individual module.

When enabled, only that module overwrites existing configuration files.

Example:

```text
GIT_FORCE_CONFIGURATION=true
```
