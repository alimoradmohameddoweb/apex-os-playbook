# SOFTWARE.ps1 - Professional Software Installation
# Optimized for Apex OS 3.2.8
# Synthesized from Professional Playbook standards.

param (
    [switch]$InstallFirefox,
    [switch]$InstallBrave,
    [switch]$InstallChrome,
    [switch]$InstallNanaZip,
    [switch]$InstallVCRedist,
    [switch]$InstallDirectX,
    [switch]$EnableDirectPlay
)

$ErrorActionPreference = 'SilentlyContinue'
$timeouts = @("--connect-timeout", "15", "--retry", "5", "--retry-delay", "2", "--retry-all-errors")
$arm = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$msiArgs = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"

# Create a isolated temporary directory for downloads
$tempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Push-Location $tempDir

function Remove-Temp {
    Pop-Location
    Remove-Item -Path $tempDir -Force -Recurse -EA 0
}

# =========================================================================
# LEGACY GAME SUPPORT (DirectPlay)
# =========================================================================
if ($EnableDirectPlay) {
    Write-Host "Apex OS: Enabling Legacy Game Support (DirectPlay)..." -ForegroundColor Cyan
    & DISM.exe /Online /Enable-Feature /FeatureName:"DirectPlay" /NoRestart /All 2>&1 | Out-Null
}

# =========================================================================
# BROWSERS
# =========================================================================

if ($InstallFirefox) {
    Write-Host "Apex OS: Installing Firefox..." -ForegroundColor Cyan
    $arch = if ($arm) { "win64-aarch64" } else { "win64" }
    $url = "https://download.mozilla.org/?product=firefox-latest-ssl&os=$arch&lang=en-US"
    $file = "$tempDir\firefox_setup.exe"
    & curl.exe -LSs "$url" -o "$file" $timeouts
    if (Test-Path $file) { Start-Process -FilePath $file -ArgumentList "/S /ALLUSERS=1" -Wait -WindowStyle Hidden }
}

if ($InstallBrave) {
    Write-Host "Apex OS: Installing Brave..." -ForegroundColor Cyan
    $url = "https://laptop-updates.brave.com/latest/winx64"
    $file = "$tempDir\brave_setup.exe"
    & curl.exe -LSs "$url" -o "$file" $timeouts
    if (Test-Path $file) {
        Get-Process "Brave*" -EA 0 | Stop-Process -Force
        Start-Process -FilePath $file -ArgumentList "/silent /install" -WindowStyle Hidden
        $timeout = 0
        do { Start-Sleep -Seconds 2; $timeout++; $proc = Get-Process -Name "BraveSetup", "BraveUpdate" -EA 0 } while ($proc -and $timeout -lt 180)
        Stop-Process -Name "BraveUpdate" -Force -EA 0
    }
}

if ($InstallChrome) {
    Write-Host "Apex OS: Installing Google Chrome..." -ForegroundColor Cyan
    $arch = if ($arm) { "_Arm64" } else { "64" }
    $url = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$arch.msi"
    $file = "$tempDir\chrome.msi"
    & curl.exe -LSs "$url" -o "$file" $timeouts
    if (Test-Path $file) { Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$file`" $msiArgs" -Wait -WindowStyle Hidden }
}

# =========================================================================
# TOOLS
# =========================================================================

if ($InstallNanaZip) {
    Write-Host "Apex OS: Installing NanaZip..." -ForegroundColor Cyan
    try {
        $githubApi = Invoke-RestMethod "https://api.github.com/repos/M2Team/NanaZip/releases/latest"
        $assets = $githubApi.Assets.browser_download_url | Select-String ".xml", ".msixbundle" | Select-Object -Unique -First 2
        if ($assets.Count -eq 2) {
            $path = New-Item "$tempDir\nanazip" -ItemType Directory -Force
            foreach ($assetUrl in $assets) { 
                $filename = $assetUrl -split '/' | Select-Object -Last 1
                & curl.exe -LSs $assetUrl -o "$path\$filename" $timeouts 
            }
            $packagePath = (Get-ChildItem $path -Filter "*.msixbundle" | Select-Object -First 1).FullName
            $licensePath = (Get-ChildItem $path -Filter "*.xml" | Select-Object -First 1).FullName
            Add-AppxProvisionedPackage -Online -PackagePath $packagePath -LicensePath $licensePath -ErrorAction Stop | Out-Null
        }
    } catch { Write-Host "  NanaZip installation failed." -ForegroundColor Red }
}

# =========================================================================
# VISUAL C++ RUNTIMES (AIO)
# =========================================================================
if ($InstallVCRedist) {
    Write-Host "Apex OS: Installing Visual C++ Runtimes (AIO)..." -ForegroundColor Cyan
    $url = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"
    $file = "$tempDir\vcredist_aio.exe"
    & curl.exe -LSs "$url" -o "$file" $timeouts
    if (Test-Path $file) { Start-Process -FilePath $file -ArgumentList "/ai /gm2" -Wait -WindowStyle Hidden }
}

# =========================================================================
# LEGACY DIRECTX RUNTIMES
# =========================================================================
if ($InstallDirectX) {
    Write-Host "Apex OS: Installing Legacy DirectX Runtimes..." -ForegroundColor Cyan
    $dxUrl = "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
    $dxFile = "$tempDir\directx_redist.exe"
    & curl.exe -LSs "$dxUrl" -o "$dxFile" $timeouts
    if (Test-Path $dxFile) {
        $dxExtract = "$tempDir\dxextract"
        New-Item -ItemType Directory -Path $dxExtract -Force | Out-Null
        Start-Process -FilePath $dxFile -ArgumentList "/q /c /t:`"$dxExtract`"" -Wait -WindowStyle Hidden
        if (Test-Path "$dxExtract\dxsetup.exe") { 
            Start-Process -FilePath "$dxExtract\dxsetup.exe" -ArgumentList "/silent" -Wait -WindowStyle Hidden 
        }
    }
}

Remove-Temp
Write-Host "Apex OS: Software installation phase complete." -ForegroundColor Green
