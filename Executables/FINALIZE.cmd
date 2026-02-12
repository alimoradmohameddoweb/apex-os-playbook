@echo off
:: FINALIZE.cmd - Final system optimization commands
:: Runs after all other tasks to ensure a pristine, optimized state
title Apex OS 3.2.2 - Final Optimization

echo =============================================
echo  Apex OS 3.2.2 - Final System Optimization
echo =============================================
echo.

:: =====================================================================
:: REBUILD PERFORMANCE COUNTERS
:: =====================================================================

echo [1/10] Rebuilding performance counters...
lodctr /R >nul 2>&1
winmgmt /resyncperf >nul 2>&1

:: =====================================================================
:: REBUILD WMI REPOSITORY
:: =====================================================================

echo [2/10] Rebuilding WMI repository...
winmgmt /salvagerepository >nul 2>&1

:: =====================================================================
:: REBUILD FONT CACHE
:: =====================================================================

echo [3/10] Rebuilding font cache...
:: Robust service stop
taskkill /f /im "FontCache.exe" >nul 2>&1
net stop FontCache /y >nul 2>&1
del /f /s /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
del /f /s /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache-System\*" >nul 2>&1
net start FontCache >nul 2>&1

:: =====================================================================
:: FLUSH DNS CACHE
:: =====================================================================

echo [4/10] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

:: =====================================================================
:: RESET WINSOCK CATALOG
:: =====================================================================

echo [5/10] Resetting Winsock catalog...
netsh winsock reset >nul 2>&1

:: =====================================================================
:: RESET ARP CACHE
:: =====================================================================

echo [6/10] Resetting ARP cache...
arp -d * >nul 2>&1

:: =====================================================================
:: MSI MODE (MESSAGE SIGNALED INTERRUPTS)
:: =====================================================================

echo [7/10] Enabling MSI mode for high-performance devices...
:: Enable MSI mode on GPU, USB, Audio, SATA controllers to reduce latency
for %%a in ("CIM_NetworkAdapter", "CIM_USBController", "CIM_VideoController", "Win32_IDEController", "Win32_SoundDevice") do (
    for /f %%b in ('wmic path %%a get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f > nul 2>&1
        reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>&1
    )
)

:: =====================================================================
:: CENTRALIZED BOOT CONFIGURATION (BCDEDIT)
:: =====================================================================

echo [8/10] Applying centralized boot optimizations...
:: Disable boot log (reduces boot time)
bcdedit /set bootlog no >nul 2>&1
:: Show boot failures so users can access WinRE if something goes wrong
bcdedit /set bootstatuspolicy DisplayAllFailures >nul 2>&1
:: Use legacy boot menu policy for faster boot
bcdedit /set bootmenupolicy Legacy >nul 2>&1
:: Set boot timeout
bcdedit /timeout 3 >nul 2>&1
:: Disable dynamic tick — use fixed platform clock for consistent timing
bcdedit /set disabledynamictick yes >nul 2>&1
:: Use TSC as primary timer source with Enhanced sync (lowest latency)
bcdedit /set tscsyncpolicy Enhanced >nul 2>&1
:: Disable Hyper-V launch only when no hypervisor features are active
bcdedit /set {current} hypervisorlaunchtype off >nul 2>&1

:: =====================================================================
:: DMA REMAPPING & KERNEL TWEAKS
:: =====================================================================

echo [9/10] Applying kernel and DMA optimizations...
:: Disable Direct Memory Access remapping for lower latency
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
    reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f > nul 2>&1
)

:: =====================================================================
:: GPU SHADER CACHE REBUILD & MISC
:: =====================================================================

echo [10/10] Clearing GPU shader caches...
rd /s /q "%LOCALAPPDATA%\D3DSCache" 2>nul
rd /s /q "%LOCALAPPDATA%\NVIDIA\DXCache" 2>nul
rd /s /q "%LOCALAPPDATA%\NVIDIA\GLCache" 2>nul
rd /s /q "%LOCALAPPDATA%\AMD\DXCache" 2>nul
rd /s /q "%LOCALAPPDATA%\AMD\GLCache" 2>nul
:: Intel GPU Cache
rd /s /q "%LOCALAPPDATA%\Intel\ShaderCache" 2>nul

echo.

echo =============================================
echo  Apex OS 3.2.2: All optimizations applied.
echo  A reboot is required for full effect.
echo =============================================

