<p align="center">
  <img src="Images/playbook.png" width="128" alt="Apex OS Logo"/>
</p>

<h1 align="center">Apex OS</h1>

<p align="center">
  <strong>The most comprehensive performance, privacy, and stability playbook for Windows 10 & 11</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#options">Options</a> •
  <a href="#compatibility">Compatibility</a> •
  <a href="#faq">FAQ</a> •
  <a href="#credits">Credits</a>
</p>

---

## What is Apex OS?

Apex OS is an [AME Wizard](https://ameliorated.io) playbook that transforms a stock Windows installation into the fastest, most private, and most stable operating system possible — without reinstalling Windows or breaking core functionality.

This is not a simple debloater. Apex OS is a **complete system re-engineering** with over **1,100 precisely targeted actions** across 11 phases:

- Every telemetry endpoint is severed
- Every unnecessary service is eliminated
- Every timer and scheduler is tuned for maximum FPS
- Every network stack parameter is optimized
- Every bloatware package is surgically removed
- Every AI/Copilot/Recall component is eliminated
- Windows Defender is toggleable — disable for max FPS or keep enabled for security

> ⚠️ **WARNING**: This playbook makes deep, irreversible changes. Use only on a **fresh Windows installation**. Always create a system image backup before applying.

---

## Features

### 🔒 Privacy & Telemetry Elimination
- **Zero telemetry** — all data collection, diagnostics, and feedback disabled
- **185+ registry values** blocking every known telemetry vector
- **Hosts file blocking** — 35+ Microsoft telemetry domains null-routed
- **DiagTrack service deleted** with firewall rules blocking outbound
- **WMI autologger sessions** disabled (DiagTrack, SQM, CloudExperience)
- **IFEO process blocking** — CompatTelRunner, DeviceCensus, AggregatorHost killed on launch
- **CLI telemetry opt-out** — PowerShell, .NET CLI, .NET Upgrade Assistant
- **Office telemetry** disabled across all versions
- **NVIDIA telemetry** disabled at machine and user level

### 🤖 AI / Copilot / Recall Elimination
- Windows Copilot completely disabled (policy + runtime + shell)
- Windows Recall (AI screenshot surveillance) blocked at every level
- AI in Paint, Notepad, and Edge disabled
- Copilot protocol handlers removed (`ms-copilot`, `ms-clicktodo`, `ms-office-ai`)
- Generative AI capability access denied
- BingChat/BGAUpsell/BCILauncher processes blocked via IFEO

### ⚡ Maximum Performance
- **CPU**: Win32PrioritySeparation=38, core parking disabled, CSRSS elevated priority
- **GPU**: Hardware-accelerated scheduling, preemption disabled, DWM frame limiting off
- **MMCSS**: SystemResponsiveness=0, Games profile at max priority, latency-sensitive
- **Memory**: Paging executive disabled, page combining off, prefetch/superfetch off
- **Disk I/O**: Last access timestamp off, 8.3 names off, NTFS compression off
- **Timer**: High-resolution timer enabled, dynamic tick disabled, TSC Enhanced sync
- **Power**: Ultimate Performance plan, core parking off, power throttling disabled
- **Boot**: 3s timeout, legacy boot menu, first logon animation off, hibernate off
- **Visual**: Best performance mode, instant menus (0ms delay), ClearType preserved

### 🌐 Network Optimization
- TCP auto-tuning with Cubic congestion provider
- Nagle's algorithm disabled globally (TcpNoDelay + TcpAckFrequency)
- DNS over HTTPS (DoH) enabled with reduced cache TTL
- IPv6 disabled, NetBIOS disabled, LMHOSTS disabled
- RSS enabled, DCA enabled, interrupt moderation disabled
- QoS reserved bandwidth set to 0%
- Network adapter power management disabled
- Telemetry IP firewall blocking (defense-in-depth)

### 🛡️ Security Hardening
- **TLS**: SSL 2.0/3.0 and TLS 1.0/1.1 disabled; TLS 1.2/1.3 enforced
- **Ciphers**: RC4, DES, 3DES, RC2, NULL disabled; 2048-bit minimum DH
- **SMB**: v1 disabled, signing required, encryption enabled
- **NTLM**: NTLMv2 enforced, LM hash storage disabled, outbound NTLM denied
- **.NET**: Strong cryptography enforced across v2.0 and v4.0 (32/64-bit)
- **UAC**: Secure desktop, admin consent, installer detection, code signing validation
- **DEP**: Always on via bcdedit
- **SEHOP**: Exception chain validation enabled
- **DLL**: Safe search order + CWD illegal in DLL search
- **Spectre/Meltdown**: Mitigations enabled
- **Vulnerable Driver Blocklist**: Enabled
- **Office**: VBA macros, DDE, ActiveX blocked across Office 2007-365
- **Adobe Reader**: JavaScript off, protected mode/view enforced (DC + XI)
- **PowerShell**: Script block logging enabled, RemoteSigned execution policy
- **Windows 11 bypass**: TPM, Secure Boot, CPU, RAM, storage checks bypassed

### 🧹 Bloatware Removal
- **40+ AppX packages** removed (including Cortana, Teams, Xbox, Copilot, Widgets)
- **OneDrive** fully uninstalled with folder cleanup and reinstall prevention
- **Edge** update services deleted, AI features disabled, telemetry blocked
- **Windows capabilities** removed (IE mode, Quick Assist, Hello Face, Steps Recorder, WordPad, PowerShell ISE, Math Recognizer)
- **Dynamic deprovisioning** — automatically prevents removed packages from returning after Windows Update
- **30+ third-party bloat** removed (Spotify, Disney+, TikTok, Netflix, CandyCrush, etc.)

### 🎨 Clean Interface
- Classic context menu (Win10 style on Win11)
- Useful "New" file types added (Batch, PowerShell, Registry)
- Dark mode enabled (apps + system + Explorer)
- Taskbar: left-aligned, no search/widgets/chat/copilot/cortana buttons
- Explorer: This PC default, file extensions shown, hidden files visible, compact mode
- All notification centers, toast notifications, and balloon tips disabled
- Sticky keys, toggle keys, filter keys popups disabled
- Mouse acceleration disabled for gaming accuracy
- Shortcut arrow overlay removed, "- Shortcut" suffix removed

### 🔄 Windows Update Control
Three user-selectable policies:
1. **Security Updates Only** (recommended) — quality patches only, feature updates deferred 365 days, pinned to current release
2. **Disable All Updates** — complete update lockdown with service/task removal
3. **Keep Default** — leave Windows Update as-is

### 📦 Software Installation
- **Browser choice**: Firefox, Brave, or Ungoogled Chromium (with privacy policies pre-configured)
- **7-Zip**: Universal file archiver
- **VLC**: Universal media player
- File associations auto-configured for installed software

---

## Installation

### Requirements
- Fresh Windows 10 21H2/22H2 or Windows 11 22H2/23H2/24H2/25H2 installation
- Internet connection
- No pending Windows Updates
- Windows Defender disabled (AME Wizard will guide you to temporarily disable it)
- No third-party antivirus
- Plugged into power (laptops)
- Password set on user account

### Steps

1. **Download** [AME Wizard](https://ameliorated.io) (latest version)
2. **Download** the latest `Apex-OS-v*.apbx` from [Releases](https://github.com/apex-os/apex-playbook/releases)
3. **Open** AME Wizard and drag the `.apbx` file into it
4. **Enter password**: `malte`
5. **Select** your preferred options (browser, features, update policy)
6. **Click** "Run" and wait ~35 minutes for completion
7. **Reboot** when prompted

### Supported Windows Builds
| Build | Version | OS |
|-------|---------|-----|
| 19044 | 21H2 | Windows 10 |
| 19045 | 22H2 | Windows 10 |
| 22621 | 22H2 | Windows 11 |
| 22631 | 23H2 | Windows 11 |
| 26100 | 24H2 | Windows 11 |
| 26120 | 24H2 | Windows 11 |
| 26200 | 25H2 | Windows 11 |

---

## Options

### Windows Defender (RadioPage)
| Option | Description |
|--------|-------------|
| **Disable Defender** (default) | Fully disables Windows Defender via Group Policy, services, drivers, and scheduled tasks for maximum performance |
| **Keep Defender Enabled** | Leave Windows Defender active — recommended if you don't use a third-party antivirus |

### Browser Selection (RadioImagePage)
| Option | Description |
|--------|-------------|
| **Firefox** (default) | Privacy-focused, with telemetry/Pocket/studies disabled via policy |
| **Brave** | Chromium-based with built-in ad blocking; rewards/VPN/wallet/AI disabled |
| **Ungoogled Chromium** | De-Googled Chromium fork for maximum privacy |
| **None** | Skip browser installation |

### System Features (CheckboxPage)
| Option | Default | Description |
|--------|---------|-------------|
| Remove Bloatware | ✅ | Remove 40+ AppX packages + OneDrive + capabilities |
| Disable Telemetry | ✅ | Eliminate all data collection, diagnostics, feedback |
| Max Performance | ✅ | CPU/GPU/memory/timer/boot/visual optimizations |
| Network Optimization | ✅ | TCP/IP stack, DNS, Nagle, adapter tuning |
| Clean Interface | ✅ | Taskbar, Explorer, context menu, dark mode, notifications |
| Security Hardening | ✅ | TLS/SSL, SMB, NTLM, ciphers, UAC, Office, Adobe |
| Apply Wallpaper | ✅ | Set Apex OS branded desktop wallpaper |

### Windows Update Policy (RadioPage)
| Option | Description |
|--------|-------------|
| **Security Only** (default) | Quality patches only, feature updates blocked |
| Disable All | Completely disable Windows Update |
| Keep Default | Leave update behavior unchanged |

---

## Architecture

```
apex-os/
├── playbook.conf              # AME Wizard configuration (XML)
├── Configuration/
│   ├── main.yml               # Entry point — 11 phases
│   └── Tasks/
│       ├── privacy.yml        # ~237 actions — telemetry elimination
│       ├── debloat.yml        # ~115 actions — AppX/capability removal
│       ├── services.yml       # ~81 actions — service optimization
│       ├── performance.yml    # ~120 actions — CPU/GPU/memory/timer tuning
│       ├── network.yml        # ~41 actions — TCP/IP/DNS optimization
│       ├── security.yml       # ~149 actions — TLS/SMB/cipher hardening
│       ├── updates.yml        # ~48 actions — Windows Update policy
│       ├── interface.yml      # ~195 actions — shell/taskbar/explorer cleanup
│       ├── cleanup.yml        # ~62 actions — scheduled tasks/file cleanup
│       ├── software.yml       # ~41 actions — browser/tools installation
│       └── finalize.yml       # ~27 actions — NGEN, SFC, branding, wallpaper
├── Executables/
│   ├── CLEANUP.ps1            # Advanced system cleanup (caches/logs/dumps)
│   ├── FINALIZE.cmd           # Final optimizations (DNS/Winsock/fonts/GPU)
│   ├── FILEASSOC.cmd          # File association configuration
│   ├── NGEN.ps1               # .NET native image compilation
│   ├── WALLPAPER.ps1          # Desktop wallpaper deployment (P/Invoke)
│   └── Apex-background.jpg    # Apex OS desktop wallpaper
└── Images/
    ├── playbook.png           # Playbook icon (512x512)
    ├── firefox.png            # Firefox browser icon
    ├── brave.png              # Brave browser icon
    └── chromium.png           # Chromium browser icon
```

### Execution Order
1. **Privacy & Telemetry** → Sever all data collection first
2. **Bloatware Removal** → Remove packages while no telemetry reports it
3. **Service Optimization** → Reduce running services baseline
4. **Performance** → CPU/GPU/memory/timer/boot tuning
5. **Network** → TCP/IP stack and adapter optimization
6. **Security** → TLS/SMB/cipher/credential hardening
7. **Windows Update** → Apply user-selected update policy
8. **Interface** → Shell, taskbar, explorer, dark mode cleanup
9. **Cleanup** → Delete 70+ scheduled tasks and caches
10. **Software** → Install browser + 7-Zip + VLC
11. **Finalize** → NGEN, DISM cleanup, SFC, Compact OS, wallpaper, branding

---

## FAQ

**Q: Can I undo this?**
A: Not easily. This playbook makes deep system changes. Always install on a fresh Windows and create a system image backup before applying.

**Q: Will my games still work?**
A: Yes. Game Mode is enabled, Xbox gaming services are removed (games don't need them), and GPU/CPU/timer optimizations specifically target gaming performance.

**Q: Will Windows Update still work?**
A: Depends on your selection. "Security Only" keeps critical patches flowing. "Disable All" completely stops updates. "Keep Default" leaves it unchanged.

**Q: Can I re-enable Bluetooth/printing/etc.?**
A: Yes. Services like Bluetooth and Print Spooler are disabled but not deleted. Re-enable them in Services (services.msc) whenever needed.

**Q: Is this safe for daily use?**
A: Yes, when installed on a fresh Windows. The playbook disables unnecessary components but preserves all core OS functionality, networking, and driver support.

**Q: Does it work on Windows 10?**
A: Yes. Apex OS supports Windows 10 21H2 (build 19044) and 22H2 (build 19045). Win11-only features (like classic context menu, snap layouts) are automatically skipped on Win10.

---

## Cross-Reference Sources

Apex OS was built by analyzing and cross-referencing the best practices from:

- [Atlas OS](https://github.com/Atlas-OS/Atlas) — Service optimization, component removal
- [ReviOS](https://revi.cc) — Performance tuning, timer optimization
- [RapidOS](https://github.com/rapid-community/RapidOS) — NTLM hardening, LSA protection, .NET crypto
- [EudynOS](https://github.com/tifrfrfr/EudynOS) — Accessibility cleanup, boot optimization
- [AtmosphereOS](https://github.com/Jebarson/AtmosphereOS) — Office macro hardening, Adobe security
- [ArkanoidOS Lite](https://github.com/Flavor-Flavius/ArkanoidOS-Lite) — OOBE cleanup, internet restrictions
- [Privacy+ AME-11](https://github.com/aspect0x7a6/privacy-plus-ame-11) — Copilot elimination, voice activation
- [AME-10-0.8](https://git.ameliorated.info/Starter/AME-10) — Win10 legacy tweaks, NVIDIA tuning
- [Windows10Debloater](https://github.com/Sycnex/Windows10Debloater) — AppX removal, context menu cleanup
- [winutil](https://github.com/ChrisTitusTech/winutil) — Edge policies, crash display, notification control

Every entry was validated against the [official AME Wizard documentation](https://docs.amelabs.net).

---

## Building from Source

```powershell
# Requires 7-Zip installed
git clone https://github.com/apex-os/apex-playbook.git
cd apex-playbook
powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
# Output: Apex-OS-v3.0.0.apbx (password: malte)
```

---

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

---

<p align="center">
  <strong>Apex OS 3.0.0</strong> — Zero telemetry. Maximum FPS. Total control.
</p>
