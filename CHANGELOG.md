# Changelog

All notable changes to this project will be documented in this file.

## [3.2.5] - 2026-02-13

### Added
- **Software Expansion**: Added official Google Chrome (Enterprise MSI) and NanaZip (Modern 7-Zip fork) as installation options.
- **Improved VCRedist Installation**: Implemented high-reliability MSI extraction for VCRedist 2005 and 2008, ensuring better compatibility for legacy components.
- **New Icons**: Added professional icons for Chrome and NanaZip in the AME Wizard UI.

### Changed
- **Enhanced SOFTWARE.ps1**: Refactored the main software script with better error handling, download retries, and modular installation logic.
- **Refined software.yml**: Updated task flow to accommodate new software selections and conditional logic.

## [3.2.4] - 2026-02-12

### Added
- **Advanced Process Mitigations**: Implemented global mitigation disabling (CFG, etc.) via binary mask, matching Atlas OS optimization depth.
- **Anti-Cheat Fix**: Added specific compatibility fix for Valorant (vgc.exe) to prevent crashes when mitigations are disabled.

### Changed
- **UI Refinement**: Cleaned up Feature Page gate names in AME Wizard. Removed tall percentage text for a more professional look.
- **Mandatory Gates**: Hardened the requirement for users to select options before proceeding.

## [3.2.3] - 2026-02-12




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
