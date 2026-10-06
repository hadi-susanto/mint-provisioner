# 🛢️ Database (`db`)

Tools for managing, developing, and working with databases from the command line. This category includes database
servers, database clients, management utilities, and other tools for working with relational and NoSQL databases.

## Content

- [DBeaver Community](#dbeaver-community-dbeaver-community-alias-dbeaver)
- [DbGate Community](#dbgate-community-dbgate-community-alias-dbgate)
- [Memcached](#memcached-memcached)
- [MongoDB Compass](#mongodb-compass-mongodb-compass-alias-compass)
- [MongoDB Community](#mongodb-server-mongodb-community-alias-mongodb)
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
