# CLEANUP.ps1 - Advanced System Cleanup
# Removes temporary files, caches, logs, and leftover installation artifacts
# that the YAML-based cleanup cannot handle (requires PowerShell logic).

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Apex OS: Starting advanced cleanup..." -ForegroundColor Cyan

# =========================================================================
# WINDOWS UPDATE CLEANUP
# =========================================================================

Write-Host "Cleaning Windows Update cache..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force 2>$null
Stop-Service -Name bits -Force 2>$null

$wuPaths = @(
    "$env:SystemRoot\SoftwareDistribution\Download",
    "$env:SystemRoot\SoftwareDistribution\DataStore\Logs",
    "$env:SystemRoot\SoftwareDistribution\PostRebootEventCache.V2"
)
foreach ($path in $wuPaths) {
    if (Test-Path $path) {
        Remove-Item -Path "$path\*" -Recurse -Force 2>$null
    }
}

Start-Service -Name wuauserv 2>$null
Start-Service -Name bits 2>$null

# =========================================================================
# TEMPORARY FILES
# =========================================================================

Write-Host "Cleaning temporary files..." -ForegroundColor Yellow
$tempPaths = @(
    "$env:SystemRoot\Temp",
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "$env:SystemRoot\Logs\CBS",
    "$env:SystemRoot\Logs\DISM",
    "$env:SystemRoot\Logs\MoSetup",
    "$env:SystemRoot\Logs\SetupDiag",
    "$env:SystemRoot\Logs\SIH",
    "$env:SystemRoot\Logs\WindowsUpdate",
    "$env:SystemRoot\Panther"
)
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        Remove-Item -Path "$path\*" -Recurse -Force 2>$null
    }
}
# Clean setup API logs separately (file glob, not directory)
Remove-Item -Path "$env:SystemRoot\inf\setupapi*.log" -Force 2>$null

# =========================================================================
# INSTALLER CACHE
# =========================================================================

Write-Host "Cleaning installer caches..." -ForegroundColor Yellow
$installerPaths = @(
    "$env:SystemRoot\Installer\`$PatchCache`$",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\ThumbCacheToDelete"
)
foreach ($path in $installerPaths) {
    if (Test-Path $path) {
        Remove-Item -Path "$path\*" -Recurse -Force 2>$null
    }
}

# =========================================================================
# EVENT LOGS
# =========================================================================

Write-Host "Clearing event logs..." -ForegroundColor Yellow
$logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Where-Object { $_.RecordCount -gt 0 }
foreach ($log in $logs) {
    try {
        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($log.LogName)
    } catch { }
}

# =========================================================================
# CRASH DUMPS
# =========================================================================

Write-Host "Cleaning crash dumps..." -ForegroundColor Yellow
$dumpPaths = @(
    "$env:LOCALAPPDATA\CrashDumps",
    "$env:SystemRoot\LiveKernelReports",
    "$env:SystemRoot\Minidump",
    "$env:SystemRoot\MEMORY.DMP"
)
foreach ($path in $dumpPaths) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force 2>$null
    }
}

# =========================================================================
# DELIVERY OPTIMIZATION CACHE
# =========================================================================

Write-Host "Cleaning Delivery Optimization cache..." -ForegroundColor Yellow
Stop-Service -Name DoSvc -Force 2>$null
$doPath = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization"
if (Test-Path $doPath) {
    Remove-Item -Path "$doPath\Cache\*" -Recurse -Force 2>$null
    Remove-Item -Path "$doPath\Logs\*" -Recurse -Force 2>$null
}

# =========================================================================
# WINDOWS DEFENDER LEFTOVERS
# =========================================================================

Write-Host "Cleaning Defender scan history..." -ForegroundColor Yellow
$defenderPaths = @(
    "$env:ProgramData\Microsoft\Windows Defender\Scans\History",
    "$env:ProgramData\Microsoft\Windows Defender\Support"
)
foreach ($path in $defenderPaths) {
    if (Test-Path $path) {
        Remove-Item -Path "$path\*" -Recurse -Force 2>$null
    }
}

# =========================================================================
# RECYCLE BIN
# =========================================================================

Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
$shell = New-Object -ComObject Shell.Application
$recycleBin = $shell.NameSpace(0x0a)
if ($recycleBin.Items().Count -gt 0) {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue 2>$null
}

# =========================================================================
# DISK CLEANUP EQUIVALENT - CLEANMGR STATEFLAGS
# =========================================================================

Write-Host "Running Disk Cleanup automation..." -ForegroundColor Yellow
$cleanupKeys = @(
    "Active Setup Temp Folders",
    "BranchCache",
    "Content Indexer Cleaner",
    "D3D Shader Cache",
    "Delivery Optimization Files",
    "Device Driver Packages",
    "Diagnostic Data Viewer database files",
    "Downloaded Program Files",
    "Internet Cache Files",
    "Language Pack",
    "Old ChkDsk Files",
    "Previous Installations",
    "Recycle Bin",
    "RetailDemo Offline Content",
    "Service Pack Cleanup",
    "Setup Log Files",
    "System error memory dump files",
    "System error minidump files",
    "Temporary Files",
    "Temporary Setup Files",
    "Thumbnail Cache",
    "Update Cleanup",
    "Upgrade Discarded Files",
    "User file versions",
    "Windows Defender",
    "Windows Error Reporting Files",
    "Windows ESD installation files",
    "Windows Upgrade Log Files"
)

$regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
foreach ($key in $cleanupKeys) {
    $regPath = Join-Path $regBase $key
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "StateFlags0100" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    }
}

# Run cleanmgr with our custom flags
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:100" -Wait -NoNewWindow -ErrorAction SilentlyContinue

# =========================================================================
# FINAL STATS
# =========================================================================

$freeSpace = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
Write-Host ""
Write-Host "Apex OS: Advanced cleanup complete." -ForegroundColor Cyan
Write-Host "  Free space on C: ${freeSpace} GB" -ForegroundColor Green
