# Kaspersky Container Security PoC Tool (kcspoc)

`kcspoc` is a Bash-based CLI tool designed for Pre-Sales Engineers and Technical Consultants to streamline technical Proof of Concept (PoC) deployments of **Kaspersky Container Security (KCS)** on Kubernetes or OpenShift.

It automates environment diagnostics, provides resilient lifecycle management (install, update, upgrade), and ensures consistent deployment standards across enterprise Linux systems and Kubernetes clusters.

## 🎯 Who is this for?

- 🛡️ **Pre-Sales / Presales Engineers**
- 🛠️ **Technical Consultants** working with KCS PoCs
- 🧪 **Kubernetes lab** and demo environments
- 🏗️ **Platform engineers** evaluating Kaspersky Container Security

## 🚀 Installation

The recommended way to install `kcspoc` is via the official bootstrap script. This script handles system verification and installs the tool into your home directory (`~/.kcspoc`).

> ℹ️ The bootstrap script installs `kcspoc` under `~/.kcspoc` and creates a symbolic link in `/usr/local/bin` when permitted.

### 1. ✅ Stable Installation (Recommended)
This installs the latest validated stable release:
```bash
curl -sSL https://raw.githubusercontent.com/arturscheiner/kcspoc/main/bootstrap.sh | bash
```

### 2. 🧪 Development Installation
To test upcoming features from the `main` branch:
```bash
curl -sSL https://raw.githubusercontent.com/arturscheiner/kcspoc/main/bootstrap.sh | bash -s -- --dev
```

### 3. 🔢 Install a Specific Version
To install a specific version from GitHub Releases:
```bash
curl -sSL https://raw.githubusercontent.com/arturscheiner/kcspoc/main/bootstrap.sh | bash -s -- --vX.Y.Z
```

## 🛠️ Usage & Documentation

Detailed documentation and help are provided directly through the CLI tool:

- 📖 **Command Reference**: Run `kcspoc help` or `kcspoc [command] --help`
- 🔢 **Installed Version**: Run `kcspoc --version`
- 📜 **Execution Logs**: Run `kcspoc logs`

For release notes, detailed changelogs, and "What's New" information, please visit the [GitHub Releases](https://github.com/arturscheiner/kcspoc/releases) page.

## 🐞 Issues & Support

Bugs, ideas, or questions — please open an issue on GitHub to keep discussions visible and documented.

👉 [github.com/arturscheiner/kcspoc/issues](https://github.com/arturscheiner/kcspoc/issues)

When opening an issue, please include:
- The installed `kcspoc` version (`kcspoc --version`)
- A short description of the problem
- Relevant command output or logs (if applicable)
- Your Kubernetes distribution and version

> [!WARNING]
> This project is maintained on a **best-effort basis**. There is no guaranteed response time, and support is provided as time permits.

## ⚖️ Disclaimer

**Personal/Hobby Project.**  
This project, `kcspoc`, is maintained independently by **Artur Scheiner** to facilitate the KCS deployment process. 

While I am a proud member of the Kaspersky team, please be aware that this project is **not** an official product of Kaspersky. It is **not** developed, maintained, supported, or endorsed by Kaspersky. Usage is subject to the License, and it is provided "as-is" without any warranties.

---
**Author:** [Artur Scheiner](https://www.linkedin.com/in/arturscheiner/)
