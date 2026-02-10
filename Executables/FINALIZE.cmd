@echo off
:: FINALIZE.cmd - Final system optimization commands
:: Runs after all other tasks to ensure a pristine, optimized state
title Apex OS 3.1.1 - Final Optimization

echo =============================================
echo  Apex OS 3.1.1 - Final System Optimization
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
net stop FontCache >nul 2>&1
del /f /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
del /f /q "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache-System\*" >nul 2>&1
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
:: SET BCDEDIT OPTIMIZATIONS
:: =====================================================================

echo [7/8] Applying boot configuration optimizations...
:: Disable boot log (reduces boot time)
bcdedit /set bootlog no >nul 2>&1
:: Show boot failures so users can access WinRE if something goes wrong
bcdedit /set bootstatuspolicy DisplayAllFailures >nul 2>&1
:: Use legacy boot menu policy for faster boot (matches performance.yml)
bcdedit /set bootmenupolicy Legacy >nul 2>&1
:: Disable Hyper-V launch only when no hypervisor features are active
:: (A12: gate check - preserves WSL2/Docker/Sandbox/DevDrive functionality)
for /f "tokens=3" %%a in ('bcdedit /enum {current} ^| findstr /i "hypervisorlaunchtype"') do (
    if /i "%%a"=="Auto" (
        echo   Hyper-V hypervisor detected active - skipping hypervisorlaunchtype change
    ) else (
        bcdedit /set hypervisorlaunchtype off >nul 2>&1
    )
)
:: NOTE: numproc intentionally omitted. Windows already uses all processors;
:: setting numproc can LIMIT cores in edge cases and interfere with park/unpark.

:: =====================================================================
:: GPU SHADER CACHE REBUILD & MISC
:: =====================================================================

echo [8/8] Clearing GPU shader cache...
rd /s /q "%LOCALAPPDATA%\D3DSCache" 2>nul
rd /s /q "%LOCALAPPDATA%\NVIDIA\DXCache" 2>nul
rd /s /q "%LOCALAPPDATA%\NVIDIA\GLCache" 2>nul
rd /s /q "%LOCALAPPDATA%\AMD\DXCache" 2>nul
rd /s /q "%LOCALAPPDATA%\AMD\GLCache" 2>nul

echo.
echo =============================================
echo  Apex OS 3.1.1: All optimizations applied.
echo  A reboot is required for full effect.
echo =============================================
