# 🛠️ Software Engineering (`software-engineering`)

Software Engineering modules provide a complete development environment for Linux Mint. They include tools for source
control, build automation, SDK management, Android development, and modern terminal-based Git workflows.

Unlike traditional package installers, several modules also perform post-install configuration, such as installing
recommended configuration files, enabling Bash/Zsh integration, and adding productivity aliases or helper functions.

---

## Android Debug Bridge (`adb`)

Android Debug Bridge (ADB) is Google's official command-line toolkit for communicating with Android devices. It provides
debugging, application deployment, shell access, file transfer, log collection, and Fastboot support.

### Installation Method

**Official website (precompiled archive)**

Downloads the latest Android Platform Tools ZIP archive directly from Google's official distribution server.

### Supported ENV

- `ADB_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/adb`

### Official Website

https://developer.android.com/tools/releases/platform-tools

---

## Apache Maven (`apache-maven`)

Apache Maven is one of the most widely used Java build automation tools. It manages project dependencies, builds,
testing, packaging, and plugin execution using the standard Maven project structure.

### Installation Method

**Official website (precompiled archive)**

Automatically downloads the latest binary TAR.GZ release from the Apache Maven project.

### Supported ENV

- `APACHE_MAVEN_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/apache-maven`

### Official Website

https://maven.apache.org/

---

## Delta (`delta`)

Delta is a modern syntax-highlighting pager for Git. It enhances Git diffs with syntax highlighting, side-by-side
comparison, decorations, and keyboard navigation.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Linux x86_64 MUSL release archive from the official GitHub repository.

### Supported ENV

- `DELTA_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/delta`

- `DELTA_REGEX`
    - Regular expression used to locate the GitHub release asset.

- `DELTA_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `DELTA_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `delta-aliases.sh` into the provisioner configuration directory.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Functions

| Function         | Description                                                                                                                                                                                        |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `git-delta-diff` | Executes `git diff` using Delta with syntax highlighting, side-by-side view, keyboard navigation, and dark theme enabled. If Git is not installed, the function displays an error message instead. |

### Official Website

https://github.com/dandavison/delta

---

## Git (`git`)

Git is the industry-standard distributed version control system. It enables source control, collaboration, branching,
merging, rebasing, tagging, and repository management.

### Installation Method

**APT package (Linux Mint / Ubuntu repository)**

Installs Git directly from the distribution package repository.

### Supported ENV

- `GIT_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `GIT_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `git-aliases.sh` into the provisioner configuration directory.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Aliases

| Alias  | Expands To                          |
|--------|-------------------------------------|
| `gcm`  | `git commit -m`                     |
| `gp`   | `git push`                          |
| `gb`   | `git branch`                        |
| `gbr`  | `git branch --remote`               |
| `gba`  | `git branch --all`                  |
| `gbd`  | `git branch --delete`               |
| `gbD`  | `git branch --delete --force`       |
| `gbdr` | `git branch --delete --remote`      |
| `gco`  | `git checkout`                      |
| `gcor` | `git checkout --recurse-submodules` |
| `gsw`  | `git switch`                        |
| `gswc` | `git switch --create`               |
| `gf`   | `git fetch`                         |
| `gfo`  | `git fetch origin`                  |

#### Shell Functions

| Function | Description                                                                                |
|----------|--------------------------------------------------------------------------------------------|
| `gpsup`  | Pushes the current branch to `origin` and automatically sets the upstream tracking branch. |

### Official Website

https://git-scm.com/

---

## GitUI (`git-ui`)

GitUI is a fast terminal user interface for Git, providing an interactive workflow for staging changes, browsing
history, managing branches, and creating commits without leaving the terminal.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Linux x86_64 release archive from the official GitHub repository.

### Supported ENV

- `GIT_UI_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/git-ui`

- `GIT_UI_REGEX`
    - Regular expression used to locate the GitHub release asset.

- `GIT_UI_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `GIT_UI_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `git-ui-aliases.sh` into the provisioner configuration directory.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Aliases

| Alias | Expands To |
|-------|------------|
| `gui` | `gitui`    |

### Official Website

https://github.com/gitui-org/gitui

---

## Lazygit (`lazy-git`)

Lazygit is a simple yet powerful terminal user interface for Git. It streamlines staging, committing, rebasing,
stashing, conflict resolution, and repository navigation through an intuitive keyboard-driven interface.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Linux x86_64 release archive from the official GitHub repository.

### Supported ENV

- `LAZY_GIT_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/lazy-git`

- `LAZY_GIT_REGEX`
    - Regular expression used to locate the GitHub release asset.

- `LAZY_GIT_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `LAZY_GIT_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `lazy-git-aliases.sh` into the provisioner configuration directory.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Aliases

| Alias | Expands To |
|-------|------------|
| `lg`  | `lazygit`  |

### Official Website

https://github.com/jesseduffield/lazygit

---

## SDKMAN! (`sdkman`)

SDKMAN! is a Software Development Kit manager for the JVM ecosystem. It simplifies installing, updating, and switching
between multiple versions of Java, Maven, Gradle, Kotlin, Scala, Groovy, Spring Boot, and many other SDKs.

### Installation Method

**Official installation script**

Downloads and installs SDKMAN! using its official bootstrap script in a non-interactive manner.

### Supported ENV

- `SDKMAN_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/sdkman`

- `SDKMAN_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `SDKMAN_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies the bundled SDKMAN! configuration into `${SDKMAN_INSTALL_DIR}/etc/config`.
- Generates `sdkman-init.sh` inside the provisioner's configuration directory.

#### Shell Integration

- Registers SDKMAN! initialization for **Bash**.
- Registers SDKMAN! initialization for **Zsh**.

### Official Website

https://sdkman.io/
