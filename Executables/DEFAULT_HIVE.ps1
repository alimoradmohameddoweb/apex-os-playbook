# DEFAULT_HIVE.ps1 - Robust Default User Hive Configuration
# Handles registry changes for HKLM\AME_UserHive_Default with better error handling.

$ErrorActionPreference = 'SilentlyContinue'

function Set-ApexRegistry {
    param($Path, $ValueName, $Value, $Type = "DWORD")
    
    # Ensure the path starts with the correct hive prefix if passed as HKU\AME_UserHive_Default
    $cleanPath = $Path -replace 'HKU\\AME_UserHive_Default', 'Registry::HKEY_USERS\AME_UserHive_Default'
    
    # Create the directory if it doesn't exist (this is where AME's action likely fails)
    if (-not (Test-Path $cleanPath)) {
        New-Item -Path $cleanPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $cleanPath -Name $ValueName -Value $Value -Type $Type -Force
}

Write-Host "Apex OS: Configuring Default User Hive..." -ForegroundColor Cyan

# Wallpaper & Visuals
Set-ApexRegistry "HKU\AME_UserHive_Default\Control Panel\Desktop" "WallPaper" "%SystemRoot%\Web\Wallpaper\ApexOS\Apex-background.jpg" "String"
Set-ApexRegistry "HKU\AME_UserHive_Default\Control Panel\Desktop" "WallpaperStyle" "10" "String"
Set-ApexRegistry "HKU\AME_UserHive_Default\Control Panel\Desktop" "TileWallpaper" "0" "String"
Set-ApexRegistry "HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen" "LockScreenImagePath" "%SystemRoot%\Web\Wallpaper\ApexOS\Apex-OS-lockscreen.jpg" "String"

# Notifications (Failing in cleanup.yml)
Set-ApexRegistry "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" 0
Set-ApexRegistry "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" 0
Set-ApexRegistry "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0

# Explorer (Failing in cleanup.yml)
Set-ApexRegistry "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0
Set-ApexRegistry "HKU\AME_UserHive_Default\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0

Write-Host "  Default user hive configured." -ForegroundColor Gray
