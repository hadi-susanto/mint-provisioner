# 🛠️ Development (`dev`)

Software development tools, SDK managers, build systems, and programming environments. Modules in this category help set
up and maintain a productive development environment.

## Contents

- [Apache Maven](#apache-maven-apache-maven-alias-maven-alias-mvn)
- [Bruno](#bruno-bruno)
- [Consul](#consul-consul)
- [Docker](#docker-docker)
- [Google Cloud CLI](#google-cloud-cli-gcloud)
- [HTTP Toolkit](#http-toolkit-httptoolkit)
- [Kafdrop](#kafdrop-kafdrop)
- [Mise](#mise-mise)
- [Postman](#postman-postman)
- [SDKMAN!](#sdkman-sdkman)
- [Vault](#vault-vault)
- [Yaak](#yaak-yaak)

---

## Apache Maven (`apache-maven`) [alias: `maven`] [alias: `mvn`]

Apache Maven is one of the most widely used Java build automation tools. It manages project dependencies, builds,
testing, packaging, and plugin execution using the standard Maven project structure.

### Installation Method

**Official website (precompiled archive)**

Automatically downloads the latest binary TAR.GZ release from the Apache Maven project.

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

## Consul (`consul`)

Consul is HashiCorp's tool for service discovery, service mesh, and distributed key-value storage.

### Installation Method

**Official website (precompiled archive)**

Resolves the latest release through HashiCorp's version API, downloads `consul_<version>_linux_amd64.zip` from
`releases.hashicorp.com`, and installs it for on-demand use. No service, APT repository, or system configuration is
created. Only AMD64 is supported.

### Supported ENV

- `CONSUL_INSTALL_DIR`
    - Directory holding the binary, configuration, and wrapper scripts.
    - Default: `${INSTALL_DIR}/consul`
- `CONSUL_DATA_DIR`
    - Directory used to store Consul data.
    - Default: `${CONSUL_INSTALL_DIR}/data`

Both must be absolute paths containing only letters, digits, and `. _ / @ + -` because they are written into the
generated scripts and configuration.

### Installation Layout

```
${CONSUL_INSTALL_DIR}/
├── bin/consul   # real binary, not on PATH
├── agent.json   # configuration, regenerated on every install
├── consul       # wrapper, symlinked into /usr/local/bin
└── data         # data directory (default location)
```

The `consul` wrapper runs the real binary and adds `-config-file=<dir>/agent.json` automatically for the `agent` subcommand unless
you pass your own; every other subcommand is passed through unchanged.

Start a single-node server with `consul agent`. The UI is available at http://127.0.0.1:8500.

Install and reinstall overwrite the binary, configuration, and wrappers, so local edits to `agent.json` / `server.json` are lost on reinstall; pass your own `-config-file` / `-config`
instead.
`mp remove` deletes everything except the data directory; `mp purge` deletes that too.

### Official Website

https://developer.hashicorp.com/consul

---

## Docker (`docker`)

Docker Engine is a container runtime and development platform for building, running, and managing containerized
applications. The module also installs Docker Compose and Docker Buildx.

### Installation Method

**Official Docker APT repository**

Adds Docker's vendor-managed Ubuntu repository and signing key, then installs:

- `docker-ce`
- `docker-ce-cli`
- `containerd.io`
- `docker-buildx-plugin`
- `docker-compose-plugin`

The module requires `rsync` before installation because existing Docker data is migrated to the configured library
directory. The pre-installation phase fails when `rsync` is unavailable.

### Supported ENV

- `DOCKER_LIB_INSTALL_DIR`
    - Directory used to store Docker images, containers, volumes, and other daemon data.
    - Must be an absolute path.
    - Must be writable by the current user before installation begins.
    - Must not be `/`, `/var/lib/docker`, a parent of `/var/lib/docker`, or a directory inside it.
    - Default: `${INSTALL_DIR}/docker-lib`

### Installation Configuration

During installation, the module:

- Installs Docker Engine, Docker Compose, and Docker Buildx.
- Checks whether `/var/lib/docker` was created by Docker.
- Skips data migration and displays a warning when `/var/lib/docker` does not exist.
- Stops the Docker service and socket before migrating existing data.
- Copies `/var/lib/docker` into `DOCKER_LIB_INSTALL_DIR` using `rsync`.
- Preserves numeric user and group IDs during migration.
- Records the resolved data destination in the module registry after a successful migration.
- Configures Docker's `data-root` in `/etc/docker/daemon.json`.
- Preserves an existing `daemon.json` and asks the user to verify it manually.
- Restarts Docker after migration.
- Adds the current non-root user to the `docker` group when the group exists.
- Displays manual instructions when the `docker` group does not exist.
- Preserves the original `/var/lib/docker` contents for manual verification and removal.

The saved installation state is removed by `cleanup.sh` after installation completes.

After being added to the `docker` group, log out and sign in again before running Docker commands without `sudo`.

### Official Website

https://www.docker.com/

### Documentation

https://docs.docker.com/engine/

---

## Google Cloud CLI (`gcloud`)

Google Cloud CLI (`gcloud`) is Google's official command-line interface for managing Google Cloud
resources and services. It provides commands for authentication, project and configuration
management, resource administration, application deployment, and interaction with Google Cloud APIs.

### Installation Method

**Official APT repository**

Installs the Google Cloud CLI from Google's official APT package repository.

### Official Website

https://cloud.google.com/sdk

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

When no broker is specified, `localhost:9092` is used.

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

Downloads the latest Linux x64 archive from Postman, extracts it into the configured installation directory, creates
the global `postman` command, and installs a system-wide desktop entry using the icon included in the archive.

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

Reads the official SDKMAN! bootstrap script to discover the current component versions, then downloads and installs the
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

## Vault (`vault`)

Vault is HashiCorp's tool for secrets management, encryption as a service, and privileged access management.

### Installation Method

**Official website (precompiled archive)**

Resolves the latest release through HashiCorp's version API, downloads `vault_<version>_linux_amd64.zip` from
`releases.hashicorp.com`, and installs it for on-demand use. No service, APT repository, or system configuration is
created. Only AMD64 is supported.

### Supported ENV

- `VAULT_INSTALL_DIR`
    - Directory holding the binary, configuration, and wrapper scripts.
    - Default: `${INSTALL_DIR}/vault`
- `VAULT_DATA_DIR`
    - Directory used to store Vault data.
    - Default: `${VAULT_INSTALL_DIR}/data`

Both must be absolute paths containing only letters, digits, and `. _ / @ + -` because they are written into the
generated scripts and configuration.

### Installation Layout

```
${VAULT_INSTALL_DIR}/
├── bin/vault    # real binary, not on PATH
├── server.json  # configuration, regenerated on every install
├── vault        # wrapper, symlinked into /usr/local/bin
├── vault-init   # `vault operator init` with one key share, symlinked into /usr/local/bin
├── vault-unseal # `vault operator unseal`, uses VAULT_UNSEAL_TOKEN if set, symlinked into /usr/local/bin
└── data         # data directory (default location)
```

The `vault` wrapper runs the real binary and adds `-config=<dir>/server.json` automatically for the `server` subcommand unless you
pass your own; every other subcommand is passed through unchanged.

Start the server with `vault server` (UI at http://127.0.0.1:8200; `VAULT_ADDR` defaults to it in the wrapper).
Initialize once with `vault-init`, which runs `vault operator init -key-shares=1 -key-threshold=1`, so a single unseal key
is required. The key count is fixed at initialization, so it cannot be set in `server.json`. Unseal with
`vault-unseal`, a wrapper for `vault operator unseal`: with no arguments and `VAULT_UNSEAL_TOKEN` set it unseals with that
key (convenient for local development; the key is visible in the process list while the command runs). Otherwise
arguments are passed through, or the key is typed at Vault's hidden prompt. The listener binds to `127.0.0.1` only. Vault locks its memory, which an unprivileged process may only do with
`CAP_IPC_LOCK`, so the installer runs `sudo setcap cap_ipc_lock=+ep` on `bin/vault` (requires `setcap` from
`libcap2-bin`). The capability is lost when the binary is replaced, so it is granted on every install.

Install and reinstall overwrite the binary, configuration, and wrappers, so local edits to `agent.json` / `server.json` are lost on reinstall; pass your own `-config-file` / `-config`
instead.
`mp remove` deletes everything except the data directory; `mp purge` deletes that too.

### Official Website

https://developer.hashicorp.com/vault

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
