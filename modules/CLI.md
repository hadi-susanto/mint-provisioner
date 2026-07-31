# 💻 Command Line (`cli`)

Command-line utilities that improve everyday productivity, simplify common tasks, and enhance developer workflows. This
category includes modern replacements for classic Unix tools, version control utilities, and other command-line
applications such as **bat**, **eza**, **delta**, **git**, and **adb**.

## Contents

- [Android Debug Bridge](#android-debug-bridge-adb)
- [Bat](#bat-bat)
- [Delta](#delta-delta)
- [Eza](#eza-eza)
- [Git](#git-git)
- [MKVToolNix](#mkvtoolnix-mkvtoolnix-alias-mkvmerge)
- [Procs](#procs-procs)
- [TLP](#tlp-tlp)

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

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

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

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

### Official Website

https://github.com/dandavison/delta

---

## Eza (`eza`)

Eza is a modern replacement for the classic `ls` command. It provides icons, Git status, file type colors, tree view,
improved sorting, and rich metadata while remaining familiar to existing `ls` users.

### Installation Method

**External APT repository**

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

### Official Website

https://github.com/eza-community/eza

---

## Git (`git`)

Git is the industry-standard distributed version control system. It enables source control, collaboration, branching,
merging, rebasing, tagging, and repository management.

### Installation Method

**APT package (Linux Mint / Ubuntu repository)**

Installs Git directly from the distribution package repository.

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

### Official Website

https://git-scm.com/

---

## MKVToolNix (`mkvtoolnix`) [alias: `mkvmerge`]

MKVToolNix is a collection of command-line and graphical tools for creating, inspecting, modifying, splitting, and
merging Matroska media files. It provides utilities such as `mkvmerge`, `mkvinfo`, `mkvextract`, and `mkvpropedit`,
with optional installation of the MKVToolNix graphical interface.

### Installation Method

**Official MKVToolNix APT repository**

Adds the official MKVToolNix signing key and APT repository for the current Ubuntu base release.

The package installed depends on the selected configuration:

* Installs `mkvtoolnix` when the graphical interface is disabled.
* Installs `mkvtoolnix-gui` when the graphical interface is enabled.

### Supported ENV

* `MKVTOOLNIX_NON_INTERACTIVE`

    * Disables the MKVToolNix GUI-selection prompt.
    * Falls back to the global `NON_INTERACTIVE` value.
    * When enabled without `MKVTOOLNIX_GUI_ENABLED`, installs the command-line-only package.
    * Default: `${NON_INTERACTIVE}`

* `MKVTOOLNIX_GUI_ENABLED`

    * Controls whether the MKVToolNix graphical interface is installed alongside the command-line tools.
    * When set to `true`, installs the `mkvtoolnix-gui` package.
    * When set to `false`, installs the command-line-only `mkvtoolnix` package.
    * When unset during an interactive installation, the module asks whether the GUI should be installed.
    * When unset during a non-interactive installation, defaults to `false`.

### Installation Detection

The module always checks for the following command-line tools:

- `mkvextract`
- `mkvinfo`
- `mkvmerge`
- `mkvpropedit`

When `MKVTOOLNIX_GUI_ENABLED=true`, the module additionally requires `mkvtoolnix-gui` to consider the installation
complete.

When the variable is unset or set to `false`, an existing command-line-only installation is considered complete. The
configuration phase is therefore skipped, and the user is not prompted to install the GUI.

To add the GUI to an existing command-line-only installation, explicitly enable it:

```bash
MKVTOOLNIX_GUI_ENABLED=true ./install.sh cli/mkvtoolnix
```

Alternatively, force the configuration phase to run and select the GUI interactively:

```bash
FORCE_INSTALL=true ./install.sh cli/mkvtoolnix
```

```bash
./install.sh --force-install cli/mkvtoolnix
```

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

### Official Website

https://mkvtoolnix.download/

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

---

## TLP (`tlp`)

TLP is an advanced power-management utility for Linux laptops. It applies optimized settings for battery life and
performance without requiring extensive manual configuration, while still providing detailed configuration options for
advanced users.

### Installation Method

**APT packages (Linux Mint / Ubuntu repository)**

Installs the following packages from the native distribution repository:

- `tlp`
- `tlp-rdw`

The installer also enables and starts `tlp.service`.

### Installed Configuration

After installation, the module displays commands for checking battery support and modifying the TLP configuration:

```bash
sudo tlp-stat --battery
```

```bash
sudo nano /etc/tlp.conf
```

The optional graphical configuration interface can be installed separately:

```bash
./install.sh gui/tlp-ui
```

### Official Website

https://linrunner.de/tlp/
