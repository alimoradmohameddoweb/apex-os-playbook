# Changelog

All notable changes to this project will be documented in this file.

## [3.2.2] - 2026-02-12

### Added
- Advanced Audio Latency optimization (disables enhancements/exclusive mode globally).
- Advanced Network driver tuning (disables power-saving/interrupt moderation).

### Changed
- **Comprehensive Codebase Audit & Consolidation.**
- Centralized all `bcdedit` boot configurations in `FINALIZE.cmd`.
- Centralized MSI Mode interrupt handling in `FINALIZE.cmd`.
- Eliminated redundant manual file/log deletions across multiple YAML files.
- Optimized task execution order for faster application.

## [3.2.1] - 2026-02-12


### Added
- Automated Visual C++ Runtimes (2005-2022) installation option.
- Legacy DirectX (June 2010) runtime installation option.
- **Legacy Game Support (DirectPlay) optional feature.**
- New User Profile cleanup for `AME_UserHive_Default` (Start pins, notifications).
- VSS shadow copy cleanup.

### Changed
- **Enhanced UI option names in AME Wizard for better clarity.**
- Refactored `CLEANUP.ps1` to use `cleanmgr /sagerun:64` for safer and more thorough cleaning.
- Improved log clearing speed by switching to `wevtutil`.
- Hardened `FINALIZE.cmd` with advanced MSI Mode, Network Tuning, and Audio optimizations from EudynOS.
- Software downloads now use `curl.exe` with retries for higher reliability.


### Fixed
- Potential hangs in `CLEANUP.ps1` caused by slow event log queries.
- Inconsistent Start menu pins on new user profiles in Windows 11.

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
