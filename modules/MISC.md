# 📦 Miscellaneous (`misc`)

Modules that do not fit into any specific category. This section is reserved for utilities with unique purposes or tools that do not naturally belong elsewhere.

## Contents

- [AnyDesk](#anydesk-any-desk-alias-anydesk)
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
