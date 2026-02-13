# CLEANUP.ps1 - Ultimate System Cleanup Engine v4
# Optimized for Apex OS 3.2.7
# Synthesized from RapidOS, Atmosphere, EudynOS, and Privacy+.
# Features: Multi-drive safety, Cleanmgr hang protection, Deep log cleaning, Default Hive fix.

$ErrorActionPreference = 'SilentlyContinue'
$systemDrive = ($env:SystemDrive).TrimEnd('\') + '\'

Write-Host "Apex OS: Starting ultimate cleanup engine..." -ForegroundColor Cyan

# =========================================================================
# 1. MULTI-DRIVE SAFETY CHECK (Atmosphere/Atlas)
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
# 2. DISK CLEANUP WITH TIMEOUT (RapidOS Style)
# =========================================================================
if (!$noCleanmgr) {
    Write-Host "[1/7] Configuring and running Disk Cleanup (Timeout: 7m)..." -ForegroundColor Yellow
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
    $timeout = 420 # 7 minutes max (RapidOS logic)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $lastCpu = 0

    while ($cleanupProcess -and !$cleanupProcess.HasExited -and $stopwatch.Elapsed.TotalSeconds -lt $timeout) {
        Start-Sleep -Seconds 10
        $proc = Get-Process -Id $cleanupProcess.Id -EA 0
        if ($proc) {
            # Check if process is idle (stuck)
            if ($proc.CPU -eq $lastCpu) { 
                # Give it a bit more leniency than RapidOS, but warn
                Write-Host "  Disk cleanup appears inactive..." -ForegroundColor DarkGray
            }
            $lastCpu = $proc.CPU
        }
    }
    
    if ($cleanupProcess -and !$cleanupProcess.HasExited) { 
        Write-Warning "Disk Cleanup timed out (7m). Terminating..."
        $cleanupProcess | Stop-Process -Force -EA 0 
    }
}

# =========================================================================
# 3. SURGICAL CLEANUP (EudynOS/Privacy+)
# =========================================================================
Write-Host "[2/7] Removing deep system clutter and logs..." -ForegroundColor Yellow
$services = @("wuauserv", "bits", "DoSvc", "cryptsvc", "dps", "appidsvc")
foreach ($svc in $services) { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue }

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
# 4. DEFAULT USER HIVE FIX (Integrated)
# =========================================================================
Write-Host "[3/7] Configuring Default User Hive (Robust Method)..." -ForegroundColor Yellow

function Set-HiveReg {
    param($Path, $ValueName, $Value, $Type = "DWORD")
    # AME loads Default User to HKU\AME_UserHive_Default. We access it directly.
    $regPath = $Path -replace 'HKU\\AME_UserHive_Default', 'Registry::HKEY_USERS\AME_UserHive_Default'
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name $ValueName -Value $Value -Type $Type -Force
}

# Fix Registry entries that fail in standard AME actions
Set-HiveReg "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" 0
Set-HiveReg "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" 0
Set-HiveReg "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0
Set-HiveReg "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0
Set-HiveReg "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0

# Wallpaper default for new users
Set-HiveReg "HKU\AME_UserHive_Default\Control Panel\Desktop" "WallPaper" "$env:SystemRoot\Web\Wallpaper\ApexOS\Apex-background.jpg" "String"
Set-HiveReg "HKU\AME_UserHive_Default\Control Panel\Desktop" "WallpaperStyle" "10" "String"
Set-HiveReg "HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen" "LockScreenImagePath" "$env:SystemRoot\Web\Wallpaper\ApexOS\Apex-OS-lockscreen.jpg" "String"

# =========================================================================
# 5. EVENT LOGS & VSS
# =========================================================================
Write-Host "[4/7] Clearing Event Logs and VSS..." -ForegroundColor Yellow
wevtutil el | ForEach-Object { wevtutil cl "$_" } 2>$null
vssadmin delete shadows /all /quiet 2>$null

# =========================================================================
# 6. BLOATWARE LEFTOVERS
# =========================================================================
Write-Host "[5/7] Removing residual tools..." -ForegroundColor Yellow
msiexec /X{43D501A5-E5E3-46EC-8F33-9E15D2A2CBD5} /qn /norestart 2>$null # Update Health Tools
msiexec /X{804A0628-543B-4984-896C-F58BF6A54832} /qn /norestart 2>$null # PC Health Check
$ia = Join-Path ${env:ProgramFiles(x86)} "WindowsInstallationAssistant"
if (Test-Path $ia) { Remove-Item -Path $ia -Recurse -Force 2>$null }

# =========================================================================
# 7. WINSXS & RECYCLE BIN
# =========================================================================
Write-Host "[6/7] Cleaning WinSxS and Recycle Bin..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue 2>$null
& DISM.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart 2>&1 | Out-Null

# =========================================================================
# FINAL SERVICE RESTART
# =========================================================================
Write-Host "[7/7] Restarting services..." -ForegroundColor Yellow
foreach ($svc in $services) { Start-Service -Name $svc -ErrorAction SilentlyContinue }

$freeSpace = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
Write-Host ""
Write-Host "Apex OS: Ultimate Cleanup Complete." -ForegroundColor Cyan
Write-Host "  Free Space: ${freeSpace} GB" -ForegroundColor Green
