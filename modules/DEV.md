# 🛠️ Development (`dev`)

Software development tools, SDK managers, build systems, and programming environments. Modules in this category help set up and maintain a productive development environment, including tools such as **Apache Maven** and **SDKMAN!**.

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

### Official Website

https://dbeaver.io/

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
