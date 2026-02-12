@echo off
:: FINALIZE.cmd - Final system optimization commands
:: Runs after all other tasks to ensure a pristine, optimized state
title Apex OS 3.2.1 - Final Optimization

echo =============================================
echo  Apex OS 3.2.1 - Final System Optimization
echo =============================================
echo.

:: =====================================================================
:: REBUILD PERFORMANCE COUNTERS
:: =====================================================================

echo [1/8] Rebuilding performance counters...
lodctr /R >nul 2>&1
winmgmt /resyncperf >nul 2>&1

:: =====================================================================
:: REBUILD WMI REPOSITORY
:: =====================================================================

echo [2/8] Rebuilding WMI repository...
winmgmt /salvagerepository >nul 2>&1

:: =====================================================================
:: REBUILD FONT CACHE
:: =====================================================================

echo [3/8] Rebuilding font cache...
:: Robust service stop
taskkill /f /im "FontCache.exe" >nul 2>&1
net stop FontCache /y >nul 2>&1
del /f /s /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
del /f /s /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache-System\*" >nul 2>&1
net start FontCache >nul 2>&1

:: =====================================================================
:: FLUSH DNS CACHE
:: =====================================================================

echo [4/8] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

:: =====================================================================
:: RESET WINSOCK CATALOG
:: =====================================================================

echo [5/8] Resetting Winsock catalog...
netsh winsock reset >nul 2>&1

:: =====================================================================
:: RESET ARP CACHE
:: =====================================================================

echo [6/8] Resetting ARP cache...
arp -d * >nul 2>&1

:: =====================================================================
:: MSI MODE (MESSAGE SIGNALED INTERRUPTS)
:: =====================================================================

echo [7/11] Enabling MSI mode for high-performance devices...
:: Enable MSI mode on GPU, USB, Audio, SATA controllers to reduce latency
for %%a in ("CIM_NetworkAdapter", "CIM_USBController", "CIM_VideoController", "Win32_IDEController", "Win32_SoundDevice") do (
    for /f %%b in ('wmic path %%a get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f > nul 2>&1
        reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%b\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>&1
    )
)

:: =====================================================================
:: NETWORK ADAPTER DEEP TUNING
:: =====================================================================

echo [8/11] Disabling network adapter power-saving features...
:: Set network adapter driver registry key
for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID^| findstr /L "PCI\VEN_"') do (
	for /f "tokens=3" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%a" /v "Driver" 2^>nul') do (
        set "netKey=HKLM\SYSTEM\CurrentControlSet\Control\Class\%%b"
    )
)
:: Disable EEE, WoL, and other performance-draining features
for %%a in ("AdvancedEEE" "ARPOffloadEnable" "AutoDisableGigabit" "AutoPowerSaveModeEnabled" "DeviceSleepOnDisconnect" "DMACoalescing" "EEE" "EEELinkAdvertisement" "EeePhyEnable" "EnableConnectedPowerGating" "EnableDynamicPowerGating" "EnableGreenEthernet" "EnableModernStandby" "EnablePME" "EnablePowerManagement" "EnableSavePowerNow" "EnableWakeOnLan" "GigaLite" "ModernStandbyWoLMagicPacket" "NSOffloadEnable" "PacketCoalescing" "PowerSaveMode" "PowerSavingMode" "ReduceSpeedOnPowerDown" "S5WakeOnLan" "SelectiveSuspend" "WakeOnDisconnect" "WakeOnLink" "WakeOnMagicPacket" "WakeOnPattern" "WakeUpModeCap") do (
    reg add "%netKey%" /v "%%~a" /t REG_SZ /d "0" /f > nul 2>&1
    reg add "%netKey%" /v "*%%~a" /t REG_SZ /d "0" /f > nul 2>&1
)

:: =====================================================================
:: DMA REMAPPING & BCDEDIT OPTIMIZATIONS
:: =====================================================================

echo [9/11] Applying boot configuration and DMA optimizations...
:: Disable Direct Memory Access remapping for lower latency
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
    reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f > nul 2>&1
)
:: Standard bcdedit optimizations
bcdedit /set bootlog no >nul 2>&1
bcdedit /set bootstatuspolicy DisplayAllFailures >nul 2>&1
bcdedit /set bootmenupolicy Legacy >nul 2>&1
bcdedit /set {current} hypervisorlaunchtype off >nul 2>&1

:: =====================================================================
:: GPU SHADER CACHE REBUILD & MISC
:: =====================================================================

echo [10/11] Clearing GPU shader caches...
rd /s /q "%LOCALAPPDATA%\D3DSCache" 2>nul
rd /s /q "%LOCALAPPDATA%\NVIDIA\DXCache" 2>nul
rd /s /q "%LOCALAPPDATA%\NVIDIA\GLCache" 2>nul
rd /s /q "%LOCALAPPDATA%\AMD\DXCache" 2>nul
rd /s /q "%LOCALAPPDATA%\AMD\GLCache" 2>nul
rd /s /q "%LOCALAPPDATA%\Intel\ShaderCache" 2>nul

:: =====================================================================
:: AUDIO OPTIMIZATION
:: =====================================================================

echo [11/11] Disabling audio exclusive mode and enhancements...
for %%a in ("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture", "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render") do (
    for /f "delims=" %%b in ('reg query "%%a" 2^>nul') do (
        :: Disable Exclusive Mode
        reg add "%%b\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f > nul 2>&1
        reg add "%%b\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f > nul 2>&1
        :: Disable Enhancements
        reg add "%%b\FxProperties" /v "{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5" /t REG_DWORD /d "1" /f > nul 2>&1
    )
)

echo.
echo =============================================
echo  Apex OS 3.2.1: All optimizations applied.
echo  A reboot is required for full effect.
echo =============================================


