# Kaspersky Container Security PoC Tool (kcspoc)

**Version:** 0.5.3 (Stable Milestone)

`kcspoc` is a robust CLI tool designed for Pre-Sales Engineers to streamline the **Proof of Concept (PoC)** deployment of Kaspersky Container Security (KCS). It automates environment verification, infrastructure provisioning, and resilient lifecycle management.

## 🚀 Key Features

### 🛡️ High-Resiliency Lifecycle
- **Anti-Cipher Protection**: Automatically recovers and preserves `APP_SECRET` during updates/upgrades to prevent data corruption.
- **Self-Healing Execution**: Detects StatefulSet immutability errors and automatically resolves them with `cascade=orphan` retries.
- **Deep Safe Destruction**: Guaranteed total teardown including mandatory PVC purging for clean project restarts.

### 📊 Advanced Monitoring & Onboarding
- **Animated Stability Watcher**: Real-time pod convergence tracking with ASCII progress bars and animated status.
- **K8s Metadata Sync**: Real-time synchronization of deployment progress to namespace labels (`kcspoc.io/status-progress`).
- **"Chave de Ouro" Summary**: Dynamic post-install guidance including console URLs and automated onboarding instructions.

### ⚙️ Automation & Diagnostics
- **Pre-flight Diagnostics**: Automated resource compliance auditing (CPU, RAM, Disk) per node.
- **Infrastructure Provisioning**: One-touch setup of Ingress-Nginx, Cert-Manager, MetalLB, and Local Storage.
- **Modular Architecture**: Secure credential management and modular command structure.

## 🛠️ Quick Start

### 1. Installation
Install the tool safely on your system:
```bash
curl -sSL https://raw.githubusercontent.com/arturscheiner/kcspoc/main/install.sh | bash
```

### 2. Configuration
Initialize your environment variables:
```bash
kcspoc config
```

### 3. Deployment Flow
```bash
kcspoc check     # Verify environment
kcspoc pull      # Download KCS charts
kcspoc prepare   # Provision infra dependencies
kcspoc deploy    # Launch KCS Management Console
kcspoc bootstrap # Configure API integration
```

## 📋 Commands

| Command | Description |
| :--- | :--- |
| `config` | Initialize or update local configuration settings |
| `pull` | Download and cache KCS Helm charts |
| `check` | Execute environment diagnostics and compliance audit |
| `prepare` | Provision infrastructure (Ingress, Certs, Storage) |
| `deploy` | Orchestrate KCS deployment (Console or Agents) |
| `bootstrap` | Configure API authentication & initialize environment |
| `destroy` | Safe and deep removal of KCS resources |
| `logs` | Audit tool execution and debug logs |

## 📐 Architecture
`kcspoc` follows the **Kubernetes State Management Protocol**. All deployment metadata is stored directly in the cluster namespace labels under the `kcspoc.io/` prefix, ensuring a single source of truth for both the tool and the operator.

## ✍️ Message from the Author

This project, `kcspoc`, was created by **Artur Scheiner** to facilitate my daily work as a **Presales Manager** at Kaspersky, specifically focused on **Kaspersky Container Security (KCS)**.

The primary motivation was to streamline the KCS PoC process, making it more efficient, repeatable, and resilient for my peers and the technical community I support. By automating the boilerplate environment checks and lifecycle operations, I can focus on the strategic value that KCS provides to our customers.

> [!NOTE]
> This is a **personal/hobby project** maintained independently to improve my own work efficiency. While I am a proud member of the Kaspersky team, please be aware that this project is **not** developed, officially maintained, or supported by Kaspersky. It is provided "as-is" for the benefit of the community.

---
**Author:** [Artur Scheiner](https://www.linkedin.com/in/arturscheiner/)
**License:** Internal Use Only - Personal Hobby Project
