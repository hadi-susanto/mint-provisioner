# 💻 Command Line (`cli`)

Command-line utilities that improve everyday productivity, simplify common tasks, and enhance developer workflows. This
category includes modern replacements for classic Unix tools, version control utilities, and other command-line
applications such as **bat**, **eza**, **delta**, **git**, and **adb**.

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

## Bat (`bat`)

Bat is a modern replacement for the traditional `cat` command. It adds syntax highlighting, Git integration, line
numbers, automatic paging, and many other quality-of-life improvements while remaining compatible with most `cat`
workflows.

### Installation Method

**GitHub latest release (.deb)**

Downloads the latest AMD64 Debian package from the official GitHub releases page and installs it using APT.

### Supported ENV

- `BAT_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `bat_.*_amd64\.deb$`

- `BAT_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `BAT_FORCE_CONFIGURATION`
    - Overwrite existing configuration.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Installs `bat-aliases.sh` into the provisioner's configuration directory.
- Configures the default Bat theme to **Dracula**.
- Configures `MANPAGER` so `man` pages are automatically rendered using Bat with syntax highlighting.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Aliases

| Alias | Description                                                                                                                         |
|-------|-------------------------------------------------------------------------------------------------------------------------------------|
| `cat` | **Expands to:** `bat --paging=never`<br><br>Displays files with syntax highlighting while behaving like the standard `cat` command. |

#### Shell Functions

| Function       | Description                                                                                                                                                   |
|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `bat-help`     | Displays the help output of any command using Bat syntax highlighting. If called without arguments, it renders help text from standard input.                 |
| `git-bat-diff` | Displays all modified tracked files in the current Git repository using `bat --diff`. If Git is not installed, an informative error message is shown instead. |

### Official Website

https://github.com/sharkdp/bat

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

## Eza (`eza`)

Eza is a modern replacement for the classic `ls` command. It provides icons, Git status, file type colors, tree view,
improved sorting, and rich metadata while remaining familiar to existing `ls` users.

### Installation Method

**External APT repository**

### Supported ENV

- `EZA_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `EZA_FORCE_CONFIGURATION`
    - Overwrite existing configuration.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Installs `eza-aliases.sh` into the provisioner's configuration directory.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Aliases

> **Note:** Unless otherwise specified, all aliases:
>
> * Display hidden files (`--all`)
> * Show colored output and file icons
> * Sort entries by file extension
> * List directories before files

| Alias          | Description                                                                                                                                                                                                                                         |
|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ls`           | **Expands to:** `eza --grid --color=always --icons=always --all --sort extension --group-directories-first`<br><br>Displays files in a compact grid layout.                                                                                         |
| `ls-tree`      | **Expands to:** `eza --grid --tree --color=always --icons=always --all --sort extension --group-directories-first`<br><br>Displays files and directories as a tree.                                                                                 |
| `ll`           | **Expands to:** `eza --long --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso`<br><br>Displays a detailed file listing with permissions, ownership, size, and ISO-formatted timestamps. |
| `ll-tree`      | **Expands to:** `eza --long --tree --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso`<br><br>Displays a detailed directory tree with file metadata and ISO-formatted timestamps.        |
| `ll-size`      | **Expands to:** `eza --long --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso --total-size`<br><br>Displays a detailed file listing with an overall directory size summary.             |
| `ll-tree-size` | **Expands to:** `eza --long --tree --color=always --icons=always --all --sort extension --group-directories-first --header --time-style long-iso --total-size`<br><br>Displays a detailed directory tree with an overall size summary.              |
| `ll-size-tree` | Alias of `ll-tree-size`.                                                                                                                                                                                                                            |

### Official Website

https://github.com/eza-community/eza

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

> **Note:** These aliases provide convenient shortcuts for commonly used Git commands.

| Alias  | Description                                                                                                                             |
|--------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `gcm`  | **Expands to:** `git commit -m`<br><br>Creates a commit with the message specified on the command line.                                 |
| `gp`   | **Expands to:** `git push`<br><br>Pushes local commits to the configured remote repository.                                             |
| `gb`   | **Expands to:** `git branch`<br><br>Lists, creates, or manages local branches.                                                          |
| `gbr`  | **Expands to:** `git branch --remote`<br><br>Lists remote-tracking branches.                                                            |
| `gba`  | **Expands to:** `git branch --all`<br><br>Lists both local and remote branches.                                                         |
| `gbd`  | **Expands to:** `git branch --delete`<br><br>Deletes a fully merged local branch.                                                       |
| `gbD`  | **Expands to:** `git branch --delete --force`<br><br>Forcefully deletes a local branch, even if it has unmerged changes.                |
| `gbdr` | **Expands to:** `git branch --delete --remote`<br><br>Deletes a remote-tracking branch reference from the local repository.             |
| `gco`  | **Expands to:** `git checkout`<br><br>Switches branches or restores files from the repository.                                          |
| `gcor` | **Expands to:** `git checkout --recurse-submodules`<br><br>Checks out a branch or commit while updating submodules recursively.         |
| `gsw`  | **Expands to:** `git switch`<br><br>Switches to an existing branch.                                                                     |
| `gswc` | **Expands to:** `git switch --create`<br><br>Creates a new branch and switches to it.                                                   |
| `gf`   | **Expands to:** `git fetch`<br><br>Downloads commits, branches, and tags from the configured remote without modifying the working tree. |
| `gfo`  | **Expands to:** `git fetch origin`<br><br>Fetches updates from the `origin` remote only.                                                |

#### Shell Functions

| Function | Description                                                                                |
|----------|--------------------------------------------------------------------------------------------|
| `gpsup`  | Pushes the current branch to `origin` and automatically sets the upstream tracking branch. |

### Official Website

https://git-scm.com/

---

## Procs (`procs`)

Procs is a modern replacement for the classic `ps` command. It provides colored output, process tree visualization,
improved searching, additional metadata, and a more user-friendly interface for inspecting running processes.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 archive from the official GitHub releases page, extracts it, and creates
a symbolic link for the executable.

### Supported ENV

- `PROCS_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `procs-.*-x86_64-linux\.zip$`

- `PROCS_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/procs`

### Official Website

https://github.com/dalance/procs
