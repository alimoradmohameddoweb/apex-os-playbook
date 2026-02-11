# =====================================================================
# APEX OS - Desktop Wallpaper & Lock Screen Deployment
# Sets custom wallpaper and lock screen for current user, all existing
# users, and default profile. Uses SystemParametersInfo P/Invoke for
# immediate wallpaper application without logoff.
# =====================================================================

param(
    [string]$ImagePath = "$env:SystemRoot\Web\Wallpaper\ApexOS\Apex-background.jpg",
    [string]$LockScreenPath = "$env:SystemRoot\Web\Wallpaper\ApexOS\Apex-OS-lockscreen.jpg"
)

$ErrorActionPreference = 'SilentlyContinue'

# --- Deploy wallpaper to system location ---
$destDir = "$env:SystemRoot\Web\Wallpaper\ApexOS"
if (-not (Test-Path $destDir)) {
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
}
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcFile = Join-Path $scriptDir 'Apex-background.jpg'
if (Test-Path $srcFile) {
    Copy-Item -Path $srcFile -Destination $destDir -Force
    Write-Host "[Apex OS] Wallpaper deployed to $destDir"
} else {
    Write-Warning "[Apex OS] Source wallpaper not found: $srcFile"
}

# --- Deploy lock screen image ---
$srcLockScreen = Join-Path $scriptDir 'Apex-OS-lockscreen.jpg'
if (Test-Path $srcLockScreen) {
    Copy-Item -Path $srcLockScreen -Destination $destDir -Force
    Write-Host "[Apex OS] Lock screen image deployed to $destDir"
} else {
    Write-Warning "[Apex OS] Source lock screen image not found: $srcLockScreen"
}

# --- Set wallpaper for ALL user hives in HKU ---
Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue | ForEach-Object {
    $userKey = $_.Name
    try {
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", 'WallPaper', $ImagePath, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", 'WallpaperStyle', '10', [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", 'TileWallpaper', '0', [Microsoft.Win32.RegistryValueKind]::String)
    } catch { }
}

# --- Set wallpaper history for current user ---
try {
    [Microsoft.Win32.Registry]::SetValue(
        'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers',
        'BackgroundHistoryPath0', $ImagePath, [Microsoft.Win32.RegistryValueKind]::String)
    [Microsoft.Win32.Registry]::SetValue(
        'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers',
        'BackgroundType', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
} catch { }

# --- Delete TranscodedImageCache to force refresh ---
try {
    Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'TranscodedImageCache' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'TranscodedImageCache_000' -ErrorAction SilentlyContinue
} catch { }

# --- Apply immediately via SystemParametersInfo P/Invoke ---
$wallpaperSrc = @"
using System.Runtime.InteropServices;

public class ApexWallpaper
{
    public const int SPI_SETDESKWALLPAPER = 20;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDWININICHANGE = 0x02;

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    public static void SetWallpaper(string path)
    {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE);
    }
}
"@
if (-not ([System.Management.Automation.PSTypeName]'ApexWallpaper').Type) {
    Add-Type -TypeDefinition $wallpaperSrc
}

[ApexWallpaper]::SetWallpaper($ImagePath)
Write-Host "[Apex OS] Wallpaper applied: $ImagePath"

# --- Set lock screen image for all user hives ---
# PersonalizationCSP LockScreenImagePath sets the lock screen for the current machine
try {
    $lockKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    if (-not (Test-Path $lockKey)) {
        New-Item -Path $lockKey -Force | Out-Null
    }
    Set-ItemProperty -Path $lockKey -Name 'LockScreenImagePath' -Value $LockScreenPath -Type String -Force
    Set-ItemProperty -Path $lockKey -Name 'LockScreenImageUrl'  -Value $LockScreenPath -Type String -Force
    Set-ItemProperty -Path $lockKey -Name 'LockScreenImageStatus' -Value 1 -Type DWord -Force
    Write-Host "[Apex OS] Lock screen applied: $LockScreenPath"
} catch {
    Write-Warning "[Apex OS] Failed to set lock screen: $_"
}

# --- Set lock screen via Group Policy path (defense-in-depth) ---
try {
    $gpKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
    if (-not (Test-Path $gpKey)) {
        New-Item -Path $gpKey -Force | Out-Null
    }
    Set-ItemProperty -Path $gpKey -Name 'LockScreenImage' -Value $LockScreenPath -Type String -Force
    Write-Host "[Apex OS] Lock screen policy applied: $LockScreenPath"
} catch {
    Write-Warning "[Apex OS] Failed to set lock screen policy: $_"
}

# --- Set lock screen for default user profile (new accounts) ---
Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue | ForEach-Object {
    $userKey = $_.Name
    try {
        $cdmKey = "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        [Microsoft.Win32.Registry]::SetValue($cdmKey, 'RotatingLockScreenEnabled', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        [Microsoft.Win32.Registry]::SetValue($cdmKey, 'RotatingLockScreenOverlayEnabled', 0, [Microsoft.Win32.RegistryValueKind]::DWord)
    } catch { }
}
