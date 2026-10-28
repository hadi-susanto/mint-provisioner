# 🛠️ Development (`dev`)

Software development tools, SDK managers, build systems, and programming environments. Modules in this category help set
up and maintain a productive development environment.

## Contents

- [Apache Maven](#apache-maven-apache-maven-alias-maven-alias-mvn)
- [Bruno](#bruno-bruno)
- [HTTP Toolkit](#http-toolkit-httptoolkit)
- [Kafdrop](#kafdrop-kafdrop)
- [Mise](#mise-mise)
- [Postman](#postman-postman)
- [SDKMAN!](#sdkman-sdkman)
- [Yaak](#yaak-yaak)

---

## Apache Maven (`apache-maven`) [alias: `maven`] [alias: `mvn`]

Apache Maven is one of the most widely used Java build automation tools. It manages project dependencies, builds,
testing, packaging, and plugin execution using the standard Maven project structure.

### Installation Method

**Official website (precompiled archive)**

Resolves the latest final release from the Maven Central metadata (`latest.sh`) and downloads its binary TAR.GZ
archive from Maven Central.

### Supported ENV

- `APACHE_MAVEN_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/apache-maven`
    - Must be writable by the current user; the resolved path is recorded in the module registry after installation.

### Official Website

https://maven.apache.org/

---

## Bruno (`bruno`)

Bruno is an offline-first API client that stores collections as plain-text files, making them easy to share and track
with version control.

### Installation Method

**Official Bruno APT repository**

Adds Bruno's official repository and signing key using `install_asc_key`, then installs the `bruno` package with APT.
Updates are delivered through the standard system package upgrade process.

### Official Website

https://www.usebruno.com/

### Documentation

https://docs.usebruno.com/get-started/bruno-basics/download

---

## HTTP Toolkit (`httptoolkit`)

HTTP Toolkit is an open-source HTTP debugging client for intercepting, inspecting, testing, and rewriting HTTP and
HTTPS traffic.

### Installation Method

**GitHub latest release (`.deb`)**

Locates and downloads the latest Linux x64 Debian package from the official HTTP Toolkit Desktop GitHub releases, then
installs it using APT. The package provides the `httptoolkit` command and desktop integration.

### Official Website

https://httptoolkit.com/

### Documentation

https://httptoolkit.com/docs/getting-started/installing/

### GitHub Repository

https://github.com/httptoolkit/httptoolkit-desktop

---

## Kafdrop (`kafdrop`)

Kafdrop is a web-based UI for viewing and monitoring Apache Kafka brokers,
topics, partitions, consumer groups, and messages.

### Installation Method

**GitHub latest release (`.jar`)**

Downloads the latest Kafdrop JAR release from GitHub and installs it into the
configured installation directory. The module creates a `kafdrop` executable
wrapper that runs the JAR using Java.

### Supported ENV

- `KAFDROP_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/kafdrop`
    - Must be writable by the current user; the resolved path is recorded in
      the module registry after installation.

### Configuration

The `kafdrop` executable supports:

- `-b, --broker [host]:[port]` to configure Kafka brokers.
- Multiple broker options can be specified.
- Missing broker host defaults to `localhost`.
- Missing broker port defaults to `9092`.
- `-p, --port` to configure the Kafdrop listener port.
- The listener port defaults to `9000`.
- `--gui` always prompts for the bootstrap server (several brokers
  separated by spaces or commas, with examples shown first) and the port; `--broker`/`--port` values become the prompt defaults.

When no broker is specified, `localhost:9092` is used.

### Desktop Integration

The module installs a `kafdrop` desktop entry (`Terminal=true`, `Exec=kafdrop --gui`).
Launching it opens a terminal, prompts for the bootstrap server and port, and runs
Kafdrop there; closing the terminal stops it, and Ctrl+C stops it and waits for Enter before closing.
The launcher uses the official Kafdrop logo (`kafdrop-logo.svg` from the upstream repository, Apache-2.0),
bundled in the module and installed to `/usr/share/icons/hicolor/scalable/apps/kafdrop.svg`.

### Official Website

https://github.com/obsidiandynamics/kafdrop

---

## Mise (`mise`)

Mise is a development tool for managing programming language runtimes, SDKs, and other development tools. It can
install and switch between multiple tool versions, automatically activate environment variables, and manage
project-specific tool configurations.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Linux x86_64 MUSL TAR.XZ archive from the official GitHub release page, extracts the `mise`
binary into the configured installation directory, makes it executable, and creates a symbolic link.

### Supported ENV

* `MISE_INSTALL_DIR`

  * Installation directory.
  * Default:
    `${INSTALL_DIR}/mise`

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

Without System Toolkit, follow the **Activate mise** section in the
[official mise installation guide](https://mise.jdx.dev/installing-mise.html).

### Official Website

https://mise.jdx.dev/

---

## Postman (`postman`)

Postman is a desktop API platform for designing, sending, testing, and documenting API requests.

### Installation Method

**Official Linux archive**

Resolves the latest version from Postman's version API (`latest.sh`), downloads that version's Linux x64 archive,
extracts it into the configured installation directory, creates the global `postman` command, and installs a
system-wide desktop entry using the icon included in the archive.

### Supported ENV

- `POSTMAN_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/postman`
    - Must be writable by the current user; the resolved path is recorded in the module registry after installation.

### Desktop Integration

- Installs `postman.desktop` into `/usr/share/applications`.
- Links the bundled executable as `/usr/local/bin/postman`.
- Uses Postman's bundled application icon.
- Refreshes the desktop application database when the required utility is available.

### Official Website

https://www.postman.com/downloads/

### Documentation

https://learning.postman.com/docs/getting-started/installation/install-app/

---

## SDKMAN! (`sdkman`)

SDKMAN! is a Software Development Kit manager for the JVM ecosystem. It simplifies installing, updating, and switching
between multiple versions of Java, Maven, Gradle, Kotlin, Scala, Groovy, Spring Boot, and many other SDKs.

### Installation Method

**Official installation script**

Queries the SDKMAN! broker API for the current stable script and native versions, then downloads and installs the
standard and native Linux x86_64 (`linuxx64`) archives in a non-interactive manner. Other SDKMAN! platforms are not
currently supported by this module. The bundled SDKMAN! configuration is installed into
`${SDKMAN_INSTALL_DIR}/etc/config`.

### Supported ENV

- `SDKMAN_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/sdkman`

### Installation Detection and Registry

SDKMAN! is detected from `bin/sdkman-init.sh`, because `sdk` is a shell function that exists only after SDKMAN! shell
integration has been loaded. After installation, Mint Provisioner records the installation directory and discovered
standard and native component versions in the module registry. The detector verifies the registered path rather than
treating the registry itself as proof of installation.

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

Run the interactive configuration module and provide the SDKMAN! installation directory when prompted:

```bash
syskit-cfg install dev/sdkman
```

### Manual Shell Integration

Without System Toolkit, add the following to your shell configuration and replace the placeholder with the SDKMAN!
installation directory:

```bash
# Enabling SDKMAN!
export SDKMAN_DIR="/path/to/installed/sdkman"
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
# End of SDKMAN!
```

### Official Website

https://sdkman.io/

---

## Yaak (`yaak`)

Yaak is a privacy-first desktop API client for REST, GraphQL, WebSockets, Server-Sent Events, and gRPC.

### Installation Method

**GitHub latest release (`.deb`)**

Locates and downloads the latest stable AMD64 Debian package from the official Yaak GitHub releases, then installs it
using APT.

### Official Website

https://yaak.app/

### GitHub Repository

https://github.com/mountain-loop/yaak
