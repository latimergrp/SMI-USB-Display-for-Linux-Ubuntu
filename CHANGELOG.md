# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-17

### Added
- Initial release of SMI USB Display installer for Ubuntu 24.04 with kernel 6.14+
- Automated EVDI 1.14.11 installation from source
- Secure Boot MOK enrollment support
- Automatic SMI installer patching
- Systemd service configuration
- Comprehensive documentation:
  - README.md with installation instructions
  - TROUBLESHOOTING.md with detailed problem-solving guides
  - TECHNICAL.md with architecture and implementation details
  - LICENSE file (MIT)
- Installation verification steps
- Support for x86_64 architecture

### Fixed
- EVDI 1.14.7 build failure on kernel 6.14+
- Installer EVDI detection loop
- Secure Boot module signing issues
- Service auto-start configuration

### Known Issues
- Limited Wayland support (X.org recommended)
- Multi-monitor configurations may require manual X.org tuning
- USB bandwidth limitations affect performance

## [Unreleased]

### Planned
- Support for additional Ubuntu versions (22.04, 23.10)
- Debian compatibility
- Automated update script for EVDI
- Performance optimization guide
- Docker container for isolated testing
- CI/CD integration for testing

---

## Version History

### Version Numbering

- **Major (X.0.0)**: Incompatible changes, major feature additions
- **Minor (0.X.0)**: New features, backward compatible
- **Patch (0.0.X)**: Bug fixes, documentation updates

### Compatibility Matrix

| Version | Ubuntu | Kernel | EVDI | SMI Driver |
|---------|--------|--------|------|------------|
| 1.0.0   | 24.04  | 6.14+  | 1.14.11+ | 2.22.1.0 |

---

## Contributing

When adding entries:
1. Use present tense ("Add feature" not "Added feature")
2. Reference issue numbers when applicable
3. Group changes by type (Added, Changed, Deprecated, Removed, Fixed, Security)
4. Keep it user-focused (what changed for users, not implementation details)

---

[1.0.0]: https://github.com/YOUR_USERNAME/smi-usb-display-ubuntu/releases/tag/v1.0.0
