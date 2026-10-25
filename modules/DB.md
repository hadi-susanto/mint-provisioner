# 🛢️ Database (`db`)

Tools for managing, developing, and working with databases from the command line. This category includes database
servers, database clients, management utilities, and other tools for working with relational and NoSQL databases.

## Content

- [DBeaver Community](#dbeaver-community-dbeaver-community-alias-dbeaver)
- [DbGate Community](#dbgate-community-dbgate-community-alias-dbgate)
- [Memcached](#memcached-memcached)
- [MongoDB Compass](#mongodb-compass-mongodb-compass-alias-compass)
- [MongoDB Community](#mongodb-server-mongodb-community-alias-mongodb)
- [MySQL Connectors](#mysql-connectors-mysql-tools)
- [MySQL Server](#mysql-server-mysql)
- [pgAdmin 4](#pgadmin-4-pg-admin-alias-pgadmin)
- [PostgreSQL Server](#postgresql-server-postgresql)
- [Redis](#redis-redis)

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

## Memcached

Memcached is a high-performance, distributed in-memory caching system designed to reduce database
load and improve application responsiveness. It stores frequently accessed data in memory for
fast retrieval.

### Installation Method

**APT package (Linux Mint / Ubuntu repository)**


Installs Memcached using the configured APT package repository.

### Official Website

https://memcached.org/

---

## MongoDB Compass (`mongodb-compass`) [alias: `compass`]

MongoDB Compass is the official graphical database management and development application for MongoDB. It provides
document exploration and editing, schema analysis, query construction, aggregation pipeline development, index
management, and database performance information.

### Installation Method

**GitHub latest release (`.deb`)**

Locates and downloads the latest AMD64 Debian package from the official MongoDB Compass GitHub releases, then installs
it using APT.

### Official Website

https://www.mongodb.com/products/tools/compass/

### GitHub Repository

https://github.com/mongodb-js/compass

---

## MongoDB Community (`mongodb-community`) [alias: `mongodb`]

MongoDB is a document-oriented NoSQL database designed for flexibility, scalability, and high
performance. It stores data in flexible JSON-like documents and provides powerful querying,
indexing, aggregation, replication, and transaction capabilities.

### Installation Method

**Official MongoDB APT repository**

Installs MongoDB from the official MongoDB APT repository, providing access to supported MongoDB
server versions independently of the default Ubuntu package repositories.

### Official Website

https://www.mongodb.com/

---

## MySQL Connectors (`mysql-tools`)

The official MySQL connectors for Java (Connector/J), Python (Connector/Python), ODBC (Connector/ODBC), and C++
(Connector/C++).

### Installation Method

**Official MySQL APT repository (`mysql-tools` component)**

Adds the `mysql-tools` component to the shared MySQL APT repository (see [MySQL Server](#mysql-server-mysql)), then
installs **one** connector per run, chosen interactively (connectors already installed are marked `(installed)`):

| Choice   | Package                      |
|----------|------------------------------|
| `java`   | `mysql-connector-j`          |
| `python` | `mysql-connector-python-py3` |
| `odbc`   | `mysql-connector-odbc`       |
| `cpp`    | `libmysqlcppconn-dev`        |

Run `mp install mysql-tools` again to add another connector.

Components enabled by `mysql` are kept. Removing this module drops only the `mysql-tools` component on `mp purge`.

### Installation Detection

The module counts as installed only when all four connector packages are installed, so a single distribution package
(for example Ubuntu's `libmysqlcppconn-dev`) does not skip the installation. Until all four are present, the module
stays "not installed" and can be run again to add more connectors without `--force`.

### Supported ENV

- `MYSQL_TOOLS_CONNECTOR`
    - Connector to install: `java`, `python`, `odbc`, or `cpp`.
    - Skips the interactive prompt when set to a valid value.
    - Required for `mp install --non-interactive`; there is no default.

### Official Website

https://dev.mysql.com/downloads/connector/

---

## MySQL Server (`mysql`)

MySQL is a widely used open-source relational database server. This module installs MySQL Community Server from
Oracle's official APT repository instead of the Ubuntu-packaged MySQL.

### Installation Method

**Official MySQL APT repository**

Replaces Oracle's `mysql-apt-config` package. Adds the MySQL signing key and the repository
`https://repo.mysql.com/apt/ubuntu` for the Ubuntu base codename (Linux Mint resolves to its Ubuntu base), then
installs `mysql-community-server`. The repository URL is fixed and cannot be changed.

The installation stops before asking anything when an Ubuntu-packaged MySQL or MariaDB server
(`mysql-server-core-8.0`, `mysql-server-core-8.4`, or `mariadb-server-core`) is installed. Replacing it would attempt
an unsupported in-place upgrade of its data directory; remove it first.

The interactive session asks which server series (repository component) to install:

| Series             | Notes             |
|--------------------|-------------------|
| `mysql-9.7-lts`    | Default (LTS)     |
| `mysql-8.4-lts`    | Long-term support |
| `mysql-innovation` | Innovation series |

The non-interactive session installs `MYSQL_SERIES` (default `mysql-9.7-lts`) with an empty root password, so root logs
in through `auth_socket` (`sudo mysql`). The interactive session also asks for the root password (masked, entered
twice); leaving it empty selects `auth_socket`. The password must be printable ASCII without backslashes. A non-empty
password is preseeded into debconf right away and is never written to the module state file; the server package clears
it from debconf after use. The run summary shows how to log in: `sudo mysql` when root has no password, `mysql -u root -p` otherwise.

When `/var/lib/mysql` already exists (for example after `mp remove`, which keeps it), the password is not asked: the
server package keeps the root credentials stored in that data directory, and the run summary says so.

The `mysql` and `mysql-tools` modules share one APT source (`/etc/apt/sources.list.d/mysql.sources`) and keyring,
because apt rejects two sources for the same repository with different signing keys. Each module adds or removes only
its own component. Re-installing with another series replaces the server component; MySQL does not support
downgrading an existing data directory to an older series.

### Supported ENV

- `MYSQL_SERIES`
    - Selects the server series during a non-interactive installation.
    - Supported values: `mysql-9.7-lts`, `mysql-8.4-lts`, and `mysql-innovation`.
    - Any other value is rejected.
    - Ignored during an interactive installation, which always asks.
    - Default: `mysql-9.7-lts`

### Removal

`mp remove` removes the server packages and keeps the repository and `/var/lib/mysql`. `mp purge` also removes the
series component (and the whole repository when `mysql-tools` is not enabled), and answers the package's own
"remove data directories" question with yes, so `/var/lib/mysql`, `/var/lib/mysql-files`, `/var/lib/mysql-keyring`,
and `/var/log/mysql` are removed without a second prompt.

Changing repository components only rewrites the `Components:` line of the shared source file; the signing key is
downloaded only when the repository is first created.

### Official Website

https://www.mysql.com/

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

## PostgreSQL Server (`postgresql`)

PostgreSQL is a powerful open-source object-relational database system known for its reliability,
feature robustness, and standards compliance. It supports advanced SQL features, extensibility,
and a wide range of data types and workloads.

### Installation Method

**Official PostgreSQL APT repository**

Installs PostgreSQL from the official PostgreSQL APT repository, providing access to supported
PostgreSQL versions independently of the default Ubuntu package repositories.

### Official Website

https://www.postgresql.org/

---

## Redis (`redis`)

Redis is an in-memory data store commonly used for caching, session management, messaging,
and real-time applications. It supports multiple data structures, persistence, replication,
and high-performance operations.

### Installation Method

**Official APT repository**

Installs Redis from the configured APT package repository.

### Official Website

https://redis.io/
