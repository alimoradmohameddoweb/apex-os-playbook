# =====================================================================
# APEX OS - Desktop Wallpaper Deployment
# Sets custom wallpaper for current user, all existing users, and
# default profile. Uses SystemParametersInfo P/Invoke for immediate
# application without logoff.
# =====================================================================

param(
    [string]$ImagePath = "$env:SystemRoot\Web\Wallpaper\ApexOS\Apex-background.jpg"
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
