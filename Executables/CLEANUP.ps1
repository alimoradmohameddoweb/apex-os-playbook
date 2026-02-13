# CLEANUP.ps1 - Ultimate System Cleanup
# Optimized for Apex OS 3.2.7
# Synthesized from Atlas OS, ReviOS, and RapidOS best practices.
# High-speed surgical deletion with hung process protection.

$ErrorActionPreference = 'SilentlyContinue'
$systemDrive = ($env:SystemDrive).TrimEnd('\') + '\'

Write-Host "Apex OS: Starting ultimate cleanup engine..." -ForegroundColor Cyan

# =========================================================================
# MULTI-DRIVE PROTECTION (Atlas-inspired)
# =========================================================================
$noCleanmgr = $false
$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select -Expand DeviceID | ForEach-Object { ($_ + '\') } | Where-Object { $_ -ne $systemDrive }

foreach ($drive in $drives) {
    $systemHive = Join-Path $drive 'Windows\System32\config\SYSTEM'
    if (Test-Path -Path $systemHive -PathType Leaf) {
        Write-Host "  Secondary Windows drive detected ($drive). Skipping Disk Cleanup to protect data." -ForegroundColor Yellow
        $noCleanmgr = $true
        break
    }
}

# =========================================================================
# DISK CLEANUP (RapidOS-inspired hung protection)
# =========================================================================
if (!$noCleanmgr) {
    Write-Host "[1/8] Configuring and running Disk Cleanup..." -ForegroundColor Yellow
    Get-Process -Name cleanmgr -EA 0 | Stop-Process -Force -EA 0

    $baseKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $regValues = @{
        "Active Setup Temp Folders"             = 2; "BranchCache"                           = 2
        "D3D Shader Cache"                      = 0; "Delivery Optimization Files"           = 2
        "Diagnostic Data Viewer database files" = 2; "Downloaded Program Files"              = 2
        "Internet Cache Files"                  = 2; "Language Pack"                         = 0
        "Old ChkDsk Files"                      = 2; "Recycle Bin"                           = 0
        "RetailDemo Offline Content"            = 2; "Setup Log Files"                       = 2
        "System error memory dump files"        = 2; "System error minidump files"           = 2
        "Temporary Files"                       = 2; "Thumbnail Cache"                       = 2
        "Update Cleanup"                        = 2; "User file versions"                    = 2
        "Windows Error Reporting Files"         = 2; "Windows Defender"                      = 2
        "Temporary Sync Files"                  = 2; "Device Driver Packages"                = 2
    }

    foreach ($entry in $regValues.GetEnumerator()) {
        $key = "$baseKey\$($entry.Key)"
        if (Test-Path $key) { Set-ItemProperty -Path $key -Name 'StateFlags0064' -Value $entry.Value -Type DWORD }
    }

    $cleanupProcess = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:64" -PassThru
    $timeout = 300 # 5 minutes max for cleanmgr
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $lastCpu = 0

    while ($cleanupProcess -and !$cleanupProcess.HasExited -and $stopwatch.Elapsed.TotalSeconds -lt $timeout) {
        Start-Sleep -Seconds 10
        $proc = Get-Process -Id $cleanupProcess.Id -EA 0
        if ($proc) {
            if ($proc.CPU -eq $lastCpu) { # No CPU change in 10s = likely stuck on a dialog or large file
                Write-Host "  Disk cleanup appears inactive. Moving to manual phase." -ForegroundColor DarkGray
                $cleanupProcess | Stop-Process -Force -EA 0
                break
            }
            $lastCpu = $proc.CPU
        }
    }
    if ($cleanupProcess -and !$cleanupProcess.HasExited) { $cleanupProcess | Stop-Process -Force -EA 0 }
}

# =========================================================================
# SURGICAL SERVICE CLEANUP
# =========================================================================
Write-Host "[2/8] Stopping services for deep cleanup..." -ForegroundColor Yellow
$services = @("wuauserv", "bits", "DoSvc", "cryptsvc", "dps", "appidsvc")
foreach ($svc in $services) { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue }

# =========================================================================
# DEEP CACHE & LOG REMOVAL (RapidOS & ReviOS inspired)
# =========================================================================
Write-Host "[3/8] Removing deep system clutter and logs..." -ForegroundColor Yellow
$targetPaths = @(
    "$env:SystemRoot\SoftwareDistribution\Download\*",
    "$env:SystemRoot\SoftwareDistribution\DataStore\Logs\*",
    "$env:SystemRoot\Temp\*",
    "$env:TEMP\*",
    "$env:LOCALAPPDATA\Temp\*",
    "$env:SystemRoot\Logs\*",
    "$env:SystemRoot\Panther\*",
    "$env:SystemRoot\Prefetch\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
    "$env:LOCALAPPDATA\IconCache.db",
    "$env:SystemRoot\inf\setupapi*.log",
    "$env:SystemRoot\debug\*.log",
    "$env:SystemRoot\Performance\WinSAT\winsat.log",
    "$env:LOCALAPPDATA\Microsoft\CLR_v4.0*\UsageTraces\*"
)

foreach ($path in $targetPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'AME' } | Remove-Item -Recurse -Force 2>$null
    }
}

# =========================================================================
# EVENT LOGS (FAST METHOD)
# =========================================================================
Write-Host "[4/8] Clearing all Windows Event Logs..." -ForegroundColor Yellow
wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null

# =========================================================================
# BLOATWARE INSTALLER REMOVAL (ReviOS-inspired)
# =========================================================================
Write-Host "[5/8] Removing residual health tools and upgraders..." -ForegroundColor Yellow
# Update Health Tools
msiexec /X{43D501A5-E5E3-46EC-8F33-9E15D2A2CBD5} /qn /norestart 2>$null
# PC Health Check
msiexec /X{804A0628-543B-4984-896C-F58BF6A54832} /qn /norestart 2>$null
# Installation Assistant cleanup
$instAssistant = Join-Path ${env:ProgramFiles(x86)} "WindowsInstallationAssistant"
if (Test-Path $instAssistant) { Remove-Item -Path $instAssistant -Recurse -Force 2>$null }

# =========================================================================
# VSS & RECYCLE BIN
# =========================================================================
Write-Host "[6/8] Cleaning VSS shadows and emptying Recycle Bin..." -ForegroundColor Yellow
vssadmin delete shadows /all /quiet 2>$null
Clear-RecycleBin -Force 2>$null

# =========================================================================
# WINSXS COMPONENT STORE CLEANUP
# =========================================================================
Write-Host "[7/8] Cleaning WinSxS component store (Dism)..." -ForegroundColor Yellow
& DISM.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1 | Out-Null

# =========================================================================
# RESTARTING SERVICES
# =========================================================================
Write-Host "[8/8] Restarting essential services..." -ForegroundColor Yellow
foreach ($svc in $services) { Start-Service -Name $svc -ErrorAction SilentlyContinue }

$freeSpace = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
Write-Host ""
Write-Host "Apex OS: Ultimate cleanup phase complete." -ForegroundColor Cyan
Write-Host "  Free space on C: ${freeSpace} GB" -ForegroundColor Green
