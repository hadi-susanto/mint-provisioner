# 📦 Miscellaneous (`misc`)

Modules that do not fit into any specific category. 
This section is reserved for utilities with unique purposes or tools that do not naturally belong elsewhere.

## Contents

- [AnyDesk](#anydesk-any-desk-alias-anydesk)
- [Claude Code](#claude-code-claude-code-alias-claude)
- [Codex CLI](#codex-cli-codex)
- [Junie](#junie-junie)
- [mkcert](#mkcert-mkcert)
- [VirtualBox](#virtualbox-virtual-box-alias-vbox)

---

## AnyDesk (`any-desk`) [alias: `anydesk`]

AnyDesk is a remote desktop application for remotely accessing and controlling computers. It provides an alternative to
applications such as TeamViewer.

### Installation Method

**Official AnyDesk APT repository**

Adds the official AnyDesk repository and signing key, then installs the `anydesk` package using APT.

The module supports AMD64 systems.

### Official Website

https://anydesk.com/

---

## Claude Code (`claude-code`) [alias: `claude`]

Claude Code is Anthropic's command-line coding assistant for understanding,
editing, and working with software projects directly from the terminal.

### Installation Method

**Official website (precompiled executable)**

Resolves the latest version and downloads the matching Linux executable directly from Anthropic's official download
service, verifying its checksum against the published release manifest before installation.

### Supported ENV

* `CLAUDE_INSTALL_DIR`

  * Installation directory.
  * Default: `${INSTALL_DIR}/claude-code`
  * Must be writable by the current user; the resolved path is recorded in the module registry after installation.

### Official Website

https://code.claude.com/

---

## Codex CLI (`codex`)

Codex CLI is OpenAI's command-line coding agent for understanding, editing, and working with software projects
directly from the terminal.

### Installation Method

**GitHub latest release (precompiled archive)**

Resolves the latest release from OpenAI's Codex GitHub repository, downloads the matching Linux package archive,
verifies its checksum against the release's published `SHA256SUMS` file, and extracts it into the configured
installation directory.

### Supported ENV

* `CODEX_INSTALL_DIR`

  * Installation directory.
  * Default: `${INSTALL_DIR}/codex`
  * Must be writable by the current user; the resolved path is recorded in the module registry after installation.

### Official Website

https://developers.openai.com/codex/

### GitHub Repository

https://github.com/openai/codex

---

## Junie (`junie`)

Junie is JetBrains' command-line coding agent for understanding, editing, and working with software projects directly
from the terminal.

### Installation Method

**GitHub latest release (precompiled archive)**

Resolves the latest Linux release from JetBrains' published release index, downloads the matching archive, verifies
its checksum against the published value, and extracts it into the configured installation directory.

### Supported ENV

* `JUNIE_INSTALL_DIR`

  * Installation directory.
  * Default: `${INSTALL_DIR}/junie`
  * Must be writable by the current user; the resolved path is recorded in the module registry after installation.

### Official Website

https://junie.jetbrains.com/

### GitHub Repository

https://github.com/JetBrains/junie

---

## mkcert (`mkcert`)

mkcert is a simple command-line tool for creating locally trusted development
TLS certificates. It automatically creates a local CA and installs it into
supported system and browser trust stores.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest precompiled mkcert binary directly from the project's
GitHub releases.

### Supported ENV

* `MKCERT_INSTALL_DIR`

  * Installation directory.
  * Default: `${INSTALL_DIR}/mkcert`
  * Must be writable by the current user; the resolved path is recorded in the
    module registry after installation.

### Official Website

https://github.com/FiloSottile/mkcert

---

## VirtualBox (`virtual-box`) [alias: `vbox`]

Oracle VirtualBox is a cross-platform virtualization application that allows multiple operating systems to run as virtual
machines on a single computer.

### Installation Method

**Official Oracle APT repository**

Adds the official Oracle VirtualBox repository and signing key, then installs the `virtualbox-7.2` package using APT.

The module supports AMD64 systems.

After installation, the matching Oracle VirtualBox Extension Pack can optionally be downloaded from the official website.
The Extension Pack version must match the installed VirtualBox version.

### Official Website

https://www.virtualbox.org/
