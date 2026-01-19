# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> [!NOTE]
> Version v0.5.0 predates the formal changelog and GitHub Releases process. This document has been created retroactively to capture the early development history.

## [0.5.5] - YYYY-MM-DD
### Changed
- Introduced stable bootstrap installer with explicit stable, dev, and version modes.

### Added
- **Bootstrap**: Introduced `bootstrap.sh` to install the tool safely on your system.

## [0.5.4] - 2026-01-19
### Added
- **Governance**: Introduced `TODO.md` to track short-term technical debt and planned improvements.

### Changed
- **Release Hygiene**: Refined the GitHub Release workflow to automatically extract and format release notes from the CHANGELOG.
- **Maintainer Tooling**: Finalized and hardened development helper scripts under `.scripts/` with explicit branch and consistency checks.

## [0.5.3] - 2026-01-19
### Added
- **Maintainer Tools**: Introduced `.scripts/` directory for internal development and release automation.
- **Install State Tracking**: `install.sh` now tracks installation state in `~/.kcspoc/bin/.install-state` to distinguish between fresh installs and upgrades.

### Changed
- **Installer Hardening**: Transitioned to a whitelist-based installation process in `install.sh`, ensuring only runtime files are deployed to the user system.
- **Workflow Hygiene**: Excluded development-only files (.agent, .github, .scripts, etc.) from standard installations.

## [0.5.2] - 2026-01-19
### Fixed
- Fixed inconsistent version references across documentation and CLI output.

## [0.5.1] - 2026-01-19
### Changed
- **Release-Based Installation**: `install.sh` now fetches the latest stable release via GitHub API instead of downloading from the `main` branch.
- **Dynamic Extraction**: Improved source extraction logic to automatically identify versioned directories in GitHub release archives.

## [0.5.0] - 2026-01-18
### Added
- Official **v0.5.0 Stable Milestone** transition.
- **Pre-Installation Safety Audit**: Added OS validation and dependency checks (git, unzip, curl/wget) to `install.sh`.
- **Author's Message**: Added personal project background and independent maintainer disclaimer to README.
- **Professional Polish**: Standardized and refined all CLI help messages and command descriptions.

## [0.4.96] - 2026-01-17
### Added
- **Bootstrap Command**: New `kcspoc bootstrap` command for interactive KCS API integration and token storage.

## [0.4.95] - 2026-01-17
### Changed
- **Credential Security**: Refined post-deploy summary to show `admin` password only on fresh installs; masked with `*******` for updates/upgrades.

## [0.4.94] - 2026-01-17
### Added
- **Visual Feedback**: Integrated an animated dynamic spinner into the deployment stability watcher.
- **High-Frequency Loop**: Refactored watch logic to 0.1s cycles for smooth terminal UI updates.

## [0.4.93] - 2026-01-14
### Added
- **High-Resiliency Suite**: 
    - **Anti-Cipher**: Automatic `APP_SECRET` recovery from cluster secrets during updates.
    - **Self-Healing**: Automated detection and resolution of StatefulSet immutability errors.
    - **Deep Destruction**: Mandatory PVC purging during `destroy` operations.

## [0.4.92] - 2026-01-13
### Added
- **Post-Install Guidance**: Dynamic discovery of console URL and structured "Chave de Ouro" summary block.

## [0.4.91] - 2026-01-12
### Added
- **Stability Watcher**: Initial implementation of real-time pod convergence monitoring.

## [0.4.90] - 2026-01-11
### Changed
- **Labeling Immediacy**: Modified deployment lifecycle to apply state labels as early as possible for maximum auditability.

## [0.4.89] - 2026-01-10
### Added
- **Strict Protocol Enforcement**: Migration to standardized `kcspoc.io/` labels for all managed resources.

## [0.4.88] - 2026-01-09
### Changed
- **Explicit Deployment Modes**: Enhanced `deploy --core` to support explicit `install`, `update`, and `upgrade` arguments.

## [0.4.87] - 2026-01-08
### Added
- **K8s State Management Protocol**: Introduction of global signals and cluster-wide instance guard.

## [0.4.86] - 2026-01-07
### Fixed
- **Integrity Bugfix**: Resolved `[: : integer expression expected` error in configuration validation logic.

## [0.4.85] - 2026-01-06
### Added
- **UI UX**: Visual pre-flight diagnostics using spinners to prevent perceived hangs during environment discovery.

## [0.4.84] - 2026-01-05
### Added
- **Precise Instance Guard**: Smarter KCS instance detection using ConfigMap and Middleware labels to prevent resource collisions.

## [0.4.79] - 2026-01-02
### Changed
- **Destroy Optimization**: Refactored removal logic for faster, non-blocking uninstallation.

---
[0.5.4]: https://github.com/arturscheiner/kcspoc/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/arturscheiner/kcspoc/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/arturscheiner/kcspoc/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/arturscheiner/kcspoc/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/arturscheiner/kcspoc/compare/v0.4.96...v0.5.0
[0.4.96]: https://github.com/arturscheiner/kcspoc/compare/v0.4.95...v0.4.96
[0.4.95]: https://github.com/arturscheiner/kcspoc/compare/v0.4.94...v0.4.95
[0.4.94]: https://github.com/arturscheiner/kcspoc/compare/v0.4.93...v0.4.94
[0.4.93]: https://github.com/arturscheiner/kcspoc/compare/v0.4.92...v0.4.93
[0.4.92]: https://github.com/arturscheiner/kcspoc/compare/v0.4.91...v0.4.92
[0.4.91]: https://github.com/arturscheiner/kcspoc/compare/v0.4.90...v0.4.91
[0.4.90]: https://github.com/arturscheiner/kcspoc/compare/v0.4.89...v0.4.90
[0.4.89]: https://github.com/arturscheiner/kcspoc/compare/v0.4.88...v0.4.89
[0.4.88]: https://github.com/arturscheiner/kcspoc/compare/v0.4.87...v0.4.88
[0.4.87]: https://github.com/arturscheiner/kcspoc/compare/v0.4.86...v0.4.87
[0.4.86]: https://github.com/arturscheiner/kcspoc/compare/v0.4.85...v0.4.86
[0.4.85]: https://github.com/arturscheiner/kcspoc/compare/v0.4.84...v0.4.85
[0.4.84]: https://github.com/arturscheiner/kcspoc/compare/v0.4.79...v0.4.84
