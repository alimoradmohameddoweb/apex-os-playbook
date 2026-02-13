# SOFTWARE.ps1 - Automated Software & Dependency Installation
# Optimized for Apex OS 3.2.1
# Handles Browsers, VCREDISTs, DirectX, and Legacy Components with resilient downloads.
# Replaces Chocolatey/Winget dependency for maximum portability.

param (
    [switch]$InstallFirefox,
    [switch]$InstallBrave,
    [switch]$InstallChrome,
    [switch]$Install7Zip,
    [switch]$InstallNanaZip,
    [switch]$InstallVCRedist,
    [switch]$InstallDirectX,
    [switch]$EnableDirectPlay
)

$ErrorActionPreference = 'SilentlyContinue'
$timeouts = @("--connect-timeout", "15", "--retry", "5", "--retry-delay", "2", "--retry-all-errors")
$arm = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$msiArgs = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"

# =========================================================================
# LEGACY GAME SUPPORT (DirectPlay) - No download needed
# =========================================================================

if ($EnableDirectPlay) {
    Write-Host "Apex OS: Enabling Legacy Game Support (DirectPlay)..." -ForegroundColor Cyan
    & DISM.exe /Online /Enable-Feature /FeatureName:"DirectPlay" /NoRestart /All 2>&1 | Out-Null
}

# Create a isolated temporary directory for downloads
$tempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Push-Location $tempDir

function Remove-Temp {
    Pop-Location
    Remove-Item -Path $tempDir -Force -Recurse -EA 0
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
    if (Test-Path $file) {
        Start-Process -FilePath $file -ArgumentList "/S /ALLUSERS=1" -Wait -WindowStyle Hidden
    }
}

if ($InstallBrave) {
    Write-Host "Apex OS: Installing Brave..." -ForegroundColor Cyan
    $url = "https://laptop-updates.brave.com/latest/winx64"
    $file = "$tempDir\brave_setup.exe"
    
    & curl.exe -LSs "$url" -o "$file" $timeouts
    if (Test-Path $file) {
        Start-Process -FilePath $file -ArgumentList "/silent /install" -WindowStyle Hidden
        $timeout = 0
        do {
            Start-Sleep -Seconds 2
            $timeout++
            $proc = Get-Process -Name "BraveSetup", "BraveUpdate" -ErrorAction SilentlyContinue
        } while ($proc -and $timeout -lt 180)
        Stop-Process -Name "BraveUpdate" -Force -ErrorAction SilentlyContinue
    }
}

if ($InstallChrome) {
    Write-Host "Apex OS: Installing Google Chrome..." -ForegroundColor Cyan
    $arch = if ($arm) { "_Arm64" } else { "64" }
    $url = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$arch.msi"
    $file = "$tempDir\chrome.msi"

    & curl.exe -LSs "$url" -o "$file" $timeouts
    if (Test-Path $file) {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$file`" $msiArgs" -Wait -WindowStyle Hidden
    }
}

# =========================================================================
# TOOLS
# =========================================================================

if ($Install7Zip) {
    Write-Host "Apex OS: Installing 7-Zip..." -ForegroundColor Cyan
    $arch = if ($arm) { "arm64" } else { "x64" }
    $url = "https://www.7-zip.org/a/7z2408-$arch.exe" 
    $file = "$tempDir\7zip.exe"
    
    & curl.exe -LSs "$url" -o "$file" $timeouts
    if (Test-Path $file) {
        Start-Process -FilePath $file -ArgumentList "/S" -Wait -WindowStyle Hidden
    }
}

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
            Write-Host "  NanaZip installed successfully." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  NanaZip installation failed. Falling back to 7-Zip..." -ForegroundColor Yellow
        $Install7Zip = $true
    }
}

# =========================================================================
# VISUAL C++ RUNTIMES (2005 - 2022)
# =========================================================================

if ($InstallVCRedist) {
    Write-Host "Apex OS: Installing Visual C++ Runtimes (High Reliability)..." -ForegroundColor Cyan
    
    $legacyArgs = "/q /norestart"
    $modernArgs = "/install /quiet /norestart"

    $vcredists = [ordered] @{
        "2005-x64"   = @("https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe", "/c /q /t:")
        "2005-x86"   = @("https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe", "/c /q /t:")
        "2008-x64"   = @("https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe", "/q /extract:")
        "2008-x86"   = @("https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe", "/q /extract:")
        "2010-x64"   = @("https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe", $legacyArgs)
        "2010-x86"   = @("https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe", $legacyArgs)
        "2012-x64"   = @("https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe", $modernArgs)
        "2012-x86"   = @("https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe", $modernArgs)
        "2013-x64"   = @("https://aka.ms/highdpimfc2013x64enu", $modernArgs)
        "2013-x86"   = @("https://aka.ms/highdpimfc2013x86enu", $modernArgs)
        "2015+-x64"  = @("https://aka.ms/vs/17/release/vc_redist.x64.exe", $modernArgs)
        "2015+-x86"  = @("https://aka.ms/vs/17/release/vc_redist.x86.exe", $modernArgs)
    }

    foreach ($vc in $vcredists.GetEnumerator()) {
        $name = $vc.Key
        $url  = $vc.Value[0]
        $args = $vc.Value[1]
        $file = "$tempDir\vc_$name.exe"
        
        Write-Host "  Downloading $name..." -ForegroundColor Gray
        & curl.exe -LSs "$url" -o "$file" $timeouts

        if (Test-Path $file) {
            Write-Host "  Installing $name..." -ForegroundColor Gray
            if ($args -match ":") {
                $extractDir = "$tempDir\vc_extract_$name"
                New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
                Start-Process -FilePath $file -ArgumentList "$args`"$extractDir`"" -Wait -WindowStyle Hidden
                
                $msis = Get-ChildItem -Path $extractDir -Filter "*.msi" -Recurse
                foreach ($msi in $msis) {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$($msi.FullName)`" $msiArgs" -Wait -WindowStyle Hidden
                }
            } else {
                Start-Process -FilePath $file -ArgumentList $args -Wait -WindowStyle Hidden
            }
        }
    }
}

# =========================================================================
# LEGACY DIRECTX RUNTIMES (JUNE 2010)
# =========================================================================

if ($InstallDirectX) {
    Write-Host "Apex OS: Installing Legacy DirectX Runtimes..." -ForegroundColor Cyan
    $dxUrl = "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe"
    $dxFile = "$tempDir\directx_redist.exe"
    
    & curl.exe -LSs "$dxUrl" -o "$dxFile" $timeouts
    
    if (Test-Path $dxFile) {
        Write-Host "  Extracting DirectX..." -ForegroundColor Gray
        $dxExtract = "$tempDir\dxextract"
        New-Item -ItemType Directory -Path $dxExtract -Force | Out-Null
        Start-Process -FilePath $dxFile -ArgumentList "/q /c /t:`"$dxExtract`"" -Wait -WindowStyle Hidden
        
        if (Test-Path "$dxExtract\dxsetup.exe") {
            Write-Host "  Running DXSetup..." -ForegroundColor Gray
            Start-Process -FilePath "$dxExtract\dxsetup.exe" -ArgumentList "/silent" -Wait -WindowStyle Hidden
        }
    }
}

Remove-Temp
Write-Host "Apex OS: Software installation phase complete." -ForegroundColor Green
