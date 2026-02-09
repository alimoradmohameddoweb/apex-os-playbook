# Changelog

All notable changes to this project will be documented in this file.

## [3.0.0] - 2026-02-09

### Added
- Playbook icon and browser icons in [Images/](Images/).
- Wallpaper deployment script [Executables/WALLPAPER.ps1](Executables/WALLPAPER.ps1).
- Windows 10 21H2 (build 19044) and 22H2 (build 19045) support.

### Changed
- 1,100+ total actions across 11 phases for privacy, performance, security, and interface tuning.
- Build toolchain updated and validated in [build.ps1](build.ps1).

### Fixed
- Registry key operations that were missing `operation: add`.
- Finalization and cleanup scripts for stability and correctness.
- Playbook XML schema compliance for radio image pages.
