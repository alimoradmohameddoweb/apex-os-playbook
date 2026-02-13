# CLEANUP.ps1 - Ultimate System Cleanup Engine v5
# Optimized for Apex OS 3.2.8
# Features: Multi-drive safety, Cleanmgr hang protection, Deep log cleaning, Integrated Hive Logic.

$ErrorActionPreference = 'SilentlyContinue'
$systemDrive = ($env:SystemDrive).TrimEnd('\') + '\'

Write-Host "Apex OS: Starting ultimate cleanup engine..." -ForegroundColor Cyan

# =========================================================================
# 1. MULTI-DRIVE SAFETY CHECK
# =========================================================================
$noCleanmgr = $false
$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select -Expand DeviceID | ForEach-Object { ($_ + '\') } | Where-Object { $_ -ne $systemDrive }

foreach ($drive in $drives) {
    if (Test-Path -Path (Join-Path $drive 'Windows\System32\config\SYSTEM')) {
        Write-Host "  Secondary Windows drive detected ($drive). Skipping Disk Cleanup." -ForegroundColor Yellow
        $noCleanmgr = $true
        break
    }
}

# =========================================================================
# 2. DISK CLEANUP WITH TIMEOUT (Fixed logic)
# =========================================================================
if (!$noCleanmgr) {
    Write-Host "[1/7] Running Disk Cleanup (Timeout: 7m)..." -ForegroundColor Yellow
    Get-Process -Name cleanmgr -EA 0 | Stop-Process -Force -EA 0

    $baseKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $regValues = @{
        "Active Setup Temp Folders" = 2; "BranchCache" = 2; "Downloaded Program Files" = 2;
        "Internet Cache Files" = 2; "Old ChkDsk Files" = 2; "RetailDemo Offline Content" = 2;
        "Setup Log Files" = 2; "System error memory dump files" = 2; "System error minidump files" = 2;
        "Thumbnail Cache" = 2; "Update Cleanup" = 2; "Windows Error Reporting Files" = 2;
        "Windows Defender" = 2; "Device Driver Packages" = 2
    }

    foreach ($entry in $regValues.GetEnumerator()) {
        $key = "$baseKey\$($entry.Key)"
        if (Test-Path $key) { Set-ItemProperty -Path $key -Name 'StateFlags0064' -Value $entry.Value -Type DWORD }
    }

    $cleanupProcess = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:64" -PassThru
    $timeout = 420 
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($cleanupProcess -and !$cleanupProcess.HasExited -and $stopwatch.Elapsed.TotalSeconds -lt $timeout) {
        Start-Sleep -Seconds 15
    }
    
    if ($cleanupProcess -and !$cleanupProcess.HasExited) { 
        Write-Warning "Disk Cleanup timed out. Terminating..."
        $cleanupProcess | Stop-Process -Force -EA 0 
    }
}

# =========================================================================
# 3. SURGICAL CLEANUP
# =========================================================================
Write-Host "[2/7] Removing deep system logs and temporary data..." -ForegroundColor Yellow
$services = @("wuauserv", "bits", "DoSvc", "cryptsvc", "dps", "appidsvc")
foreach ($svc in $services) { Stop-Service -Name $svc -Force -EA 0 }

$targetPaths = @(
    "$env:SystemRoot\SoftwareDistribution\Download\*",
    "$env:SystemRoot\Temp\*",
    "$env:TEMP\*",
    "$env:LOCALAPPDATA\Temp\*",
    "$env:SystemRoot\Logs\*",
    "$env:SystemRoot\Panther\*",
    "$env:SystemRoot\Prefetch\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",
    "$env:SystemRoot\inf\setupapi*.log"
)

foreach ($path in $targetPaths) {
    if (Test-Path $path) { Get-ChildItem -Path $path -EA 0 | Where-Object { $_.Name -ne 'AME' } | Remove-Item -Recurse -Force -EA 0 }
}

# =========================================================================
# 4. ROBUST DEFAULT HIVE CONFIG (No external file)
# =========================================================================
Write-Host "[3/7] Configuring Default User Profile Registry..." -ForegroundColor Yellow

$hivePath = "Registry::HKEY_USERS\AME_UserHive_Default"
$regTasks = @(
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"; Name = "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND"; Value = 0 },
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"; Name = "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK"; Value = 0 },
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\PushNotifications"; Name = "ToastEnabled"; Value = 0 },
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Explorer"; Name = "ShowFrequent"; Value = 0 },
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Explorer"; Name = "ShowRecent"; Value = 0 },
    @{ Path = "Control Panel\Desktop"; Name = "WallPaper"; Value = "$env:SystemRoot\Web\Wallpaper\ApexOS\Apex-background.jpg"; Type = "String" },
    @{ Path = "Control Panel\Desktop"; Name = "WallpaperStyle"; Value = "10"; Type = "String" },
    @{ Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"; Name = "LockScreenImagePath"; Value = "$env:SystemRoot\Web\Wallpaper\ApexOS\Apex-OS-lockscreen.jpg"; Type = "String" }
)

foreach ($task in $regTasks) {
    $fullPath = Join-Path $hivePath $task.Path
    if (-not (Test-Path $fullPath)) { New-Item -Path $fullPath -Force | Out-Null }
    $type = if ($task.Type) { $task.Type } else { "DWORD" }
    Set-ItemProperty -Path $fullPath -Name $task.Name -Value $task.Value -Type $type -Force -EA 0
}

# =========================================================================
# 5. EVENT LOGS & SYSTEM RESTORE
# =========================================================================
Write-Host "[4/7] Clearing Event Logs and VSS..." -ForegroundColor Yellow
wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null
vssadmin delete shadows /all /quiet 2>$null

# =========================================================================
# 6. RESIDUAL TOOL REMOVAL (Fixed GUID Quoting)
# =========================================================================
Write-Host "[5/7] Uninstalling residual components..." -ForegroundColor Yellow
# Update Health Tools
Start-Process "msiexec.exe" -ArgumentList "/X{43D501A5-E5E3-46EC-8F33-9E15D2A2CBD5} /qn /norestart" -Wait -EA 0
# PC Health Check
Start-Process "msiexec.exe" -ArgumentList "/X{804A0628-543B-4984-896C-F58BF6A54832} /qn /norestart" -Wait -EA 0

# =========================================================================
# 7. WINSXS & RECYCLE BIN
# =========================================================================
Write-Host "[6/7] Finalizing disk optimization..." -ForegroundColor Yellow
Clear-RecycleBin -Force -EA 0
& DISM.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1 | Out-Null

# =========================================================================
# FINAL SERVICE RESTART
# =========================================================================
Write-Host "[7/7] Restarting services..." -ForegroundColor Yellow
foreach ($svc in $services) { Start-Service -Name $svc -EA 0 }

Write-Host "`nApex OS: Cleanup Complete." -ForegroundColor Cyan

