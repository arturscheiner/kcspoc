# Kaspersky Container Security PoC Tool (kcspoc)

**Version:** 0.4.72

`kcspoc` is a CLI tool designed to streamline the Proof of Concept (PoC) deployment of Kaspersky Container Security (KCS). It helps with environment verification, configuration management, chart downloading, and preparation for installation.

## Features

*   **Interactive Configuration:** Wizard-style setup to generate `~/.kcspoc/config`.
*   **Environment Validation:** Checks Kubernetes version, node architecture (amd64), container runtimes, CNI plugins, and cluster resources.
*   **Deep Node Inspection:** Optionally runs privileged pods to verify kernel headers and disk space on each node.
*   **eBPF Check:** Verifies eBPF/BTF support (`/sys/kernel/btf/vmlinux`).
*   **Streamlined Workflow:** Modular commands for pulling charts and preparing the cluster.
*   **Localization (i18n):** Supports multiple languages (Default: English/en_US, Available: Portuguese/pt_BR). Auto-detects based on system locale.

## Prerequisites

*   **OS:** Linux (Ubuntu/Debian recommended)
*   **Shell:** Bash
*   **Tools:**
    *   `kubectl` (configured with cluster admin access)
    *   `helm`
    *   `curl`

## Installation

The easiest way to install `kcspoc` is using the remote installer:

```bash
bash <(curl -s https://raw.githubusercontent.com/arturscheiner/kcspoc/main/install.sh)
```

This will automatically create the necessary directories (`~/.kcspoc`), clone the repository, and set up a global symlink.

### Manual Installation Options

You can also run `kcspoc` directly from the source directory or install it system-wide manually.

#### Option 1: Run from Source

1.  Clone the repository or download the source files.
2.  Navigate to the directory:
    ```bash
    cd /path/to/kcspoc
    ```
3.  Make the script executable:
    ```bash
    chmod +x kcspoc
    ```
4.  Deploy KCS:
    ```bash
    ./kcspoc deploy --core
    ```

#### Option 2: Manual System-wide Installation

To use `kcspoc` from anywhere, create a symlink in your binary path (e.g., `/usr/local/bin`).

1.  Navigate to the directory containing the script:
    ```bash
    cd /path/to/kcspoc
    ```
2.  Make the script executable:
    ```bash
    chmod +x kcspoc
    ```
3.  Create a symbolic link (requires sudo). **Ensure you link the main script AND keep the lib/locales folders in place relative to the real path.**
    ```bash
    sudo ln -s "$(pwd)/kcspoc" /usr/local/bin/kcspoc
    ```
4.  Verify installation:
    ```bash
    kcspoc help
    ```

## Usage

The general workflow is: `config` -> `pull` -> `check` -> `prepare`.

### Localization
The tool automatically detects your language via `LC_ALL`, `LC_MESSAGES`, or `LANG`.
To force a specific language (e.g., Portuguese):
```bash
LANG=pt_BR.UTF-8 kcspoc help
```

### 1. Configuration
Run the interactive wizard to set up your environment variables (Namespace, Domain, Registry Credentials, etc.).
```bash
kcspoc config
```

### 2. Download KCS Chart
Authenticate to the Kaspersky registry and download the KCS Helm chart.
```bash
kcspoc pull
# Or force a specific version:
kcspoc pull --version 1.2.0
```

### 3. Verify Environment
Run a comprehensive check of your Kubernetes cluster to ensure it meets KCS requirements.
```bash
kcspoc check
```

### 4. Prepare Cluster
Apply necessary configurations, create namespaces/secrets, and install dependencies (Cert-Manager, MetalLB, Ingress-Nginx, etc.).
```bash
kcspoc prepare
```

## Directory Structure
The tool uses a modular structure:

*   `kcspoc`: Main entrypoint script.
*   `lib/`: Contains command logic (`cmd_*.sh`) and helpers (`common.sh`).
*   `locales/`: Localization files (`en_US.sh`, `pt_BR.sh`, etc.).
*   `~/.kcspoc/`: User configuration and downloaded artifacts.
