# CLEANUP.ps1 - Advanced System Cleanup
# Optimized for Apex OS 3.2.5
# Removes temporary files, caches, logs, and leftover installation artifacts.
# Replaced slow cleanmgr with surgical file deletion for speed and reliability.

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Apex OS: Starting advanced cleanup..." -ForegroundColor Cyan

# =========================================================================
# WINDOWS UPDATE & SERVICES
# =========================================================================

Write-Host "[1/6] Cleaning Windows Update cache..." -ForegroundColor Yellow
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
# TEMPORARY FILES & CACHES
# =========================================================================

Write-Host "[2/6] Cleaning temporary files and system caches..." -ForegroundColor Yellow
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
    "$env:SystemRoot\Panther",
    "$env:SystemRoot\Prefetch",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
    "$env:SystemRoot\System32\winevt\Logs\*"
)

foreach ($path in $tempPaths) {
    try {
        if (Test-Path $path) {
            # Avoid deleting the 'AME' folder if present (used by some tools)
            Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'AME' } | Remove-Item -Recurse -Force 2>$null
        }
    } catch {}
}

# Clean setup api logs
Remove-Item -Path "$env:SystemRoot\inf\setupapi*.log" -Force 2>$null

# =========================================================================
# EVENT LOGS (FAST METHOD)
# =========================================================================

Write-Host "[3/6] Clearing all Windows Event Logs..." -ForegroundColor Yellow
# wevtutil is much faster than Get-WinEvent
$logs = wevtutil el
foreach ($log in $logs) {
    wevtutil cl "$log" 2>$null
}

# =========================================================================
# VSS & CRASH DUMPS
# =========================================================================

Write-Host "[4/6] Cleaning VSS shadows and crash dumps..." -ForegroundColor Yellow
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

Write-Host "[5/6] Emptying Recycle Bin..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue 2>$null

# =========================================================================
# WINSXS COMPONENT STORE CLEANUP
# =========================================================================

Write-Host "[6/6] Cleaning WinSxS component store (this may take a few minutes)..." -ForegroundColor Yellow
# Using StartComponentCleanup without /ResetBase is faster and safer for playbooks
& DISM.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1 | Out-Null

# =========================================================================
# FINAL STATS
# =========================================================================

$freeSpace = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
Write-Host ""
Write-Host "Apex OS: Advanced cleanup complete." -ForegroundColor Cyan
Write-Host "  Free space on C: ${freeSpace} GB" -ForegroundColor Green
