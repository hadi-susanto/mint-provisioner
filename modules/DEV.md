# 🛠️ Development (`dev`)

Software development tools, SDK managers, build systems, and programming environments. Modules in this category help set
up and maintain a productive development environment, including tools such as **Apache Maven** and **SDKMAN!**.

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

## DBeaver Community (`dbeaver-community`)

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

## DbGate Community (`dbgate-community`)

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

## MongoDB Compass (`mongodb-compass`)

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

## pgAdmin 4 (`pg-admin`)

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
