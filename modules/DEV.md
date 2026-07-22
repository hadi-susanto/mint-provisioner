# 🛠️ Development (`dev`)

Software development tools, SDK managers, build systems, and programming environments. Modules in this category help set
up and maintain a productive development environment, including tools such as **Apache Maven** and **SDKMAN!**.

## Contents

- [Apache Maven](#apache-maven-apache-maven-alias-maven-alias-mvn)
- [Bruno](#bruno-bruno)
- [DBeaver Community](#dbeaver-community-dbeaver-community-alias-dbeaver)
- [DbGate Community](#dbgate-community-dbgate-community-alias-dbgate)
- [Docker](#docker-docker)
- [MongoDB Compass](#mongodb-compass-mongodb-compass-alias-compass)
- [pgAdmin 4](#pgadmin-4-pg-admin-alias-pgadmin)
- [Postman](#postman-postman)
- [SDKMAN!](#sdkman-sdkman)
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

## DBeaver Community (`dbeaver-community`) [alias: `dbeaver`]

DBeaver Community is a free and open-source database management tool. It supports many database engines, including
PostgreSQL, MySQL, MariaDB, SQLite, SQL Server, and Oracle.

### Installation Method

**Official DBeaver Community PPA**

Adds the DBeaver Community PPA and installs the `dbeaver-ce` package using APT.

Installing from the PPA allows DBeaver to receive updates through the standard system package upgrade process.

### Supported ENV

- `DBEAVER_COMMUNITY_USE_APT_ADD_REPOSITORY`
    - Controls whether the Launchpad repository is added using `add-apt-repository`.
    - Default:
      `${USE_APT_ADD_REPOSITORY}`

### Official Website

https://dbeaver.io/

---

## DbGate Community (`dbgate-community`) [alias: `dbgate`]

DbGate Community is a cross-platform database management application supporting relational databases, NoSQL databases,
and Redis. It provides database browsing, data editing, SQL development, import and export, and database administration
tools.

### Installation Method

**GitHub latest release (`.deb`)**

Downloads the latest Debian package from the DbGate GitHub releases page using its permanent latest-release URL, then
installs it using APT.

Because DbGate publishes a stable `latest/download` URL, the module does not need to query the GitHub API or use a
release
asset regular expression.

### Official Website

https://www.dbgate.org/

### GitHub Repository

https://github.com/dbgate/dbgate

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
    - Must not be `/`, `/var/lib/docker`, a parent of `/var/lib/docker`, or a directory inside it.
    - Default: `${INSTALL_DIR}/docker-lib`

- `DOCKER_NON_INTERACTIVE`
    - Disables the Docker-specific installation prompt.
    - Falls back to `${NON_INTERACTIVE}`.
    - Default: `${NON_INTERACTIVE}`

### Installation Configuration

During installation, the module:

- Installs Docker Engine, Docker Compose, and Docker Buildx.
- Checks whether `/var/lib/docker` was created by Docker.
- Skips data migration and displays a warning when `/var/lib/docker` does not exist.
- Stops the Docker service and socket before migrating existing data.
- Copies `/var/lib/docker` into `DOCKER_LIB_INSTALL_DIR` using `rsync`.
- Preserves numeric user and group IDs during migration.
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

## MongoDB Compass (`mongodb-compass`) [alias: `compass`]

MongoDB Compass is the official graphical database management and development application for MongoDB. It provides
document exploration and editing, schema analysis, query construction, aggregation pipeline development, index
management, and database performance information.

### Installation Method

**GitHub latest release (`.deb`)**

Locates and downloads the latest AMD64 Debian package from the official MongoDB Compass GitHub releases, then installs
it using APT.

### Supported ENV

- `MONGODB_COMPASS_REGEX`
    - Regular expression used to locate the Debian package in the latest GitHub release.
    - Default:

      ```text
      mongodb-compass_.*_amd64\.deb$
      ```

### Official Website

https://www.mongodb.com/products/tools/compass/

### GitHub Repository

https://github.com/mongodb-js/compass



---

## pgAdmin 4 (`pg-admin`) [alias: `pgadmin`]

pgAdmin 4 is an open-source graphical administration and development platform for PostgreSQL. It provides tools for
managing database servers, executing SQL queries, inspecting database objects, monitoring activity, performing
maintenance, and backing up or restoring databases.

### Installation Method

**Official pgAdmin APT repository**

Adds the official pgAdmin signing key and an Ubuntu-codename-specific APT repository, then installs the selected
pgAdmin package.

The available installation modes are:

| `PGADMIN_UI` | Package installed  | Mode            |
|--------------|--------------------|-----------------|
| `desktop`    | `pgadmin4-desktop` | Desktop only    |
| `web`        | `pgadmin4-web`     | Web only        |
| `both`       | `pgadmin4`         | Desktop and web |

When `PGADMIN_UI` is unset during an interactive installation, the module asks which package should be installed.
Desktop mode is the first/default choice.

During a non-interactive installation, an unset `PGADMIN_UI` defaults to desktop mode.

### Supported ENV

- `PGADMIN_UI`
    - Selects the pgAdmin installation mode.
    - Supported values: `desktop`, `web`, and `both`.
    - `desktop` installs `pgadmin4-desktop`.
    - `web` installs `pgadmin4-web`.
    - `both` installs `pgadmin4`, providing desktop and web modes.
    - Any other value is rejected.
    - When unset during an interactive installation, the module asks which mode should be installed.
    - Default: `desktop`

- `PGADMIN_NON_INTERACTIVE`
    - Disables the pgAdmin package-selection prompt.
    - Falls back to `${NON_INTERACTIVE}`.
    - When enabled without `PGADMIN_UI`, installs `pgadmin4-desktop`.
    - Default: `${NON_INTERACTIVE}`

### Installation Detection

Installation detection follows `PGADMIN_UI`:

- `desktop` requires `pgadmin4-desktop`.
- `web` requires `pgadmin4-web`.
- `both` requires either the `pgadmin4` meta-package or both desktop and web packages.
- Any other value is rejected as a module configuration error.
- When `PGADMIN_UI` is unset, detection defaults to `pgadmin4-desktop`.

### Desktop Integration

Desktop mode provides:

- A pgAdmin 4 application-menu entry.
- Icons in the system hicolor icon theme.
- The standalone pgAdmin desktop runtime.

### Web Configuration

Installing `pgadmin4-web` or `pgadmin4` installs the web application package, but the web server must still be
configured manually:

```bash
sudo /usr/pgadmin4/bin/setup-web.sh
```

### Official Website

https://www.pgadmin.org/

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
currently supported by this module.

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
- Fails the post-install phase if a required configuration file or shell integration cannot be installed.

#### Shell Integration

- Registers SDKMAN! initialization for **Bash**.
- Registers SDKMAN! initialization for **Zsh**.

### Official Website

https://sdkman.io/

---

## Yaak (`yaak`)

Yaak is a privacy-first desktop API client for REST, GraphQL, WebSockets, Server-Sent Events, and gRPC.

### Installation Method

**GitHub latest release (`.deb`)**

Locates and downloads the latest stable AMD64 Debian package from the official Yaak GitHub releases, then installs it
using APT.

### Supported ENV

- `YAAK_REGEX`
    - Regular expression used to locate the Debian package in the latest GitHub release.
    - Default:

      ```text
      yaak_.*_amd64\.deb$
      ```

### Official Website

https://yaak.app/

### GitHub Repository

https://github.com/mountain-loop/yaak
