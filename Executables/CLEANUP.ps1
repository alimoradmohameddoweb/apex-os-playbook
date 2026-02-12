# CLEANUP.ps1 - Advanced System Cleanup
# Optimized for Apex OS 3.2.1
# Removes temporary files, caches, logs, and leftover installation artifacts
# Uses cleanmgr presets for safety and thoroughness.

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Apex OS: Starting advanced cleanup..." -ForegroundColor Cyan

# =========================================================================
# DISK CLEANUP (cleanmgr) PRESETS
# =========================================================================

Write-Host "Configuring Disk Cleanup presets..." -ForegroundColor Yellow
# Kill running cleanmgr instances to prevent blocking
Get-Process -Name cleanmgr -EA 0 | Stop-Process -Force -EA 0

$baseKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
$regValues = @{
    "Active Setup Temp Folders"             = 2
    "BranchCache"                           = 2
    "D3D Shader Cache"                      = 0 # Handled in FINALIZE.cmd
    "Delivery Optimization Files"           = 2
    "Diagnostic Data Viewer database files" = 2
    "Downloaded Program Files"              = 2
    "Internet Cache Files"                  = 2
    "Language Pack"                         = 0
    "Old ChkDsk Files"                      = 2
    "Recycle Bin"                           = 0
    "RetailDemo Offline Content"            = 2
    "Setup Log Files"                       = 2
    "System error memory dump files"        = 2
    "System error minidump files"           = 2
    "Temporary Files"                       = 2
    "Thumbnail Cache"                       = 2
    "Update Cleanup"                        = 2 # Crucial for space
    "User file versions"                    = 2
    "Windows Error Reporting Files"         = 2
    "Windows Defender"                      = 2
    "Temporary Sync Files"                  = 2
    "Device Driver Packages"                = 2
}

foreach ($entry in $regValues.GetEnumerator()) {
    $key = "$baseKey\$($entry.Key)"
    if (Test-Path $key) {
        Set-ItemProperty -Path $key -Name 'StateFlags0064' -Value $entry.Value -Type DWORD
    }
}

Write-Host "Running Disk Cleanup..." -ForegroundColor Yellow
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:64" -Wait

# =========================================================================
# WINDOWS UPDATE & SERVICES
# =========================================================================

Write-Host "Cleaning Windows Update cache..." -ForegroundColor Yellow
$services = @("wuauserv", "bits", "DoSvc")
foreach ($svc in $services) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
}

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
        # Avoid deleting the 'AME' folder if present (used by some tools)
        Get-ChildItem -Path $path | Where-Object { $_.Name -ne 'AME' } | Remove-Item -Recurse -Force 2>$null
    }
}
Remove-Item -Path "$env:SystemRoot\inf\setupapi*.log" -Force 2>$null

# =========================================================================
# EVENT LOGS (FAST METHOD)
# =========================================================================

Write-Host "Clearing event logs..." -ForegroundColor Yellow
# wevtutil is much faster than Get-WinEvent and doesn't hang
wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null

# =========================================================================
# VSS & CRASH DUMPS
# =========================================================================

Write-Host "Cleaning VSS shadows and crash dumps..." -ForegroundColor Yellow
vssadmin delete shadows /all /quiet 2>$null

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
# RECYCLE BIN
# =========================================================================

Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue 2>$null

# =========================================================================
# WINSXS COMPONENT STORE CLEANUP
# =========================================================================

Write-Host "Cleaning WinSxS component store..." -ForegroundColor Yellow
& DISM /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1 | Out-Null

# =========================================================================
# FINAL STATS
# =========================================================================

$freeSpace = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
Write-Host ""
Write-Host "Apex OS: Advanced cleanup complete." -ForegroundColor Cyan
Write-Host "  Free space on C: ${freeSpace} GB" -ForegroundColor Green

