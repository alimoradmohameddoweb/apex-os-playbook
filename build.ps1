# =========================================================================
# Apex OS — Playbook Build Script
# Packages the playbook into a .apbx file for AME Wizard
# =========================================================================

param(
    [string]$Password = "malte",
    [string]$OutputDir = $PSScriptRoot,
    [switch]$ListContents
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# =========================================================================
# CONFIGURATION
# =========================================================================

$playbookRoot  = $PSScriptRoot
$playbookConf  = Join-Path $playbookRoot "playbook.conf"
$configDir     = Join-Path $playbookRoot "Configuration"
$execDir       = Join-Path $playbookRoot "Executables"
$imagesDir     = Join-Path $playbookRoot "Images"

# Files/folders to EXCLUDE from the .apbx archive
$excludePatterns = @(
    '.git',
    '.gitignore',
    '.gitattributes',
    '.github',
    'build.ps1',
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    '*.apbx',
    '.agents',
    '.session_state',
    '.vscode',
    'Thumbs.db',
    'Desktop.ini',
    '.DS_Store'
)

# Parse version from playbook.conf
[xml]$conf = Get-Content $playbookConf -Raw
$version   = $conf.Playbook.Version
$name      = $conf.Playbook.Name -replace '\s+', '-'
$outputFile = Join-Path $OutputDir "$name-v$version.apbx"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Apex OS Playbook Builder" -ForegroundColor Cyan
Write-Host " Version:  $version" -ForegroundColor Cyan
Write-Host " Output:   $outputFile" -ForegroundColor Cyan
Write-Host " Excludes: $($excludePatterns.Count) patterns" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# =========================================================================
# VALIDATE STRUCTURE
# =========================================================================

Write-Host "[1/6] Validating playbook structure..." -ForegroundColor Yellow

$requiredFiles = @(
    $playbookConf,
    (Join-Path $configDir "main.yml")
)

$missingFiles = @()
foreach ($f in $requiredFiles) {
    if (-not (Test-Path $f)) {
        $missingFiles += $f
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "ERROR: Missing required files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

# Validate all YAML task files referenced in main.yml exist
$mainYml = Get-Content (Join-Path $configDir "main.yml") -Raw
$taskFiles = [regex]::Matches($mainYml, "path:\s*'([^']+\.yml)'", [System.Text.RegularExpressions.RegexOptions]::Multiline)
foreach ($match in $taskFiles) {
    $taskFile = Join-Path $configDir $match.Groups[1].Value.Trim()
    if (-not (Test-Path $taskFile)) {
        Write-Host "WARNING: Referenced task file not found: $taskFile" -ForegroundColor DarkYellow
    }
}

# Count files
$yamlCount = (Get-ChildItem -Path $configDir -Filter "*.yml" -Recurse).Count
$exeCount  = if (Test-Path $execDir) { (Get-ChildItem -Path $execDir -Recurse -File).Count } else { 0 }

Write-Host "  playbook.conf: OK" -ForegroundColor Green
Write-Host "  YAML configs:  $yamlCount files" -ForegroundColor Green
Write-Host "  Executables:   $exeCount files" -ForegroundColor Green
Write-Host ""

# =========================================================================
# LOCATE 7-ZIP
# =========================================================================

Write-Host "[2/6] Locating 7-Zip..." -ForegroundColor Yellow

$7zPaths = @(
    "${env:ProgramFiles}\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
    (Get-Command 7z -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
)

$7z = $null
foreach ($p in $7zPaths) {
    if ($p -and (Test-Path $p)) {
        $7z = $p
        break
    }
}

if (-not $7z) {
    Write-Host "ERROR: 7-Zip not found. Install from https://7-zip.org or: choco install 7zip" -ForegroundColor Red
    Write-Host "Attempting to install via winget..." -ForegroundColor Yellow
    try {
        winget install --id 7zip.7zip --accept-source-agreements --accept-package-agreements 2>$null
        $7z = "${env:ProgramFiles}\7-Zip\7z.exe"
        if (-not (Test-Path $7z)) { throw "Still not found after install" }
        Write-Host "  7-Zip installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Could not install 7-Zip. Please install manually and re-run." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  Found: $7z" -ForegroundColor Green
}
Write-Host ""

# =========================================================================
# CLEAN PREVIOUS BUILD
# =========================================================================

Write-Host "[3/6] Cleaning previous builds..." -ForegroundColor Yellow

if (Test-Path $outputFile) {
    Remove-Item $outputFile -Force
    Write-Host "  Removed: $outputFile" -ForegroundColor DarkGray
}

# Clean any temp build artifacts
$tempBuild = Join-Path $env:TEMP "apex-os-build"
if (Test-Path $tempBuild) {
    Remove-Item $tempBuild -Recurse -Force
}
Write-Host "  Clean." -ForegroundColor Green
Write-Host ""

# =========================================================================
# BUILD .APBX ARCHIVE
# =========================================================================

Write-Host "[4/6] Building .apbx archive..." -ForegroundColor Yellow

# .apbx is a password-protected 7z archive containing:
#   playbook.conf    (root)
#   Configuration/   (YAML configs)
#   Executables/     (scripts & tools)
#   Images/          (optional branding)
#
# EXCLUDED: .git, build.ps1, README.md, CHANGELOG.md, LICENSE, *.apbx, etc.

$itemsToInclude = @($playbookConf, $configDir)

if (Test-Path $execDir) {
    $itemsToInclude += $execDir
}
if ((Test-Path $imagesDir) -and (Get-ChildItem $imagesDir -File -ErrorAction SilentlyContinue).Count -gt 0) {
    $itemsToInclude += $imagesDir
}

# Show what will be included
Write-Host "  Including:" -ForegroundColor DarkGray
foreach ($item in $itemsToInclude) {
    $rel = ($item -replace [regex]::Escape($playbookRoot + [IO.Path]::DirectorySeparatorChar), '')
    Write-Host "    + $rel" -ForegroundColor DarkGray
}
Write-Host "  Excluding:" -ForegroundColor DarkGray
foreach ($pattern in $excludePatterns) {
    Write-Host "    - $pattern" -ForegroundColor DarkRed
}
Write-Host ""

# Build the 7z command arguments
$7zArgs = @(
    "a",                        # Add to archive
    "-t7z",                     # 7z format
    "-mx=9",                    # Maximum compression
    "-mhe=on",                  # Encrypt headers
    "-ms=on",                   # Solid archive
    "-p$Password"               # Password
)

# Add exclusion patterns (defense-in-depth alongside whitelist)
foreach ($pattern in $excludePatterns) {
    $7zArgs += "-xr!$pattern"
}

# Output file
$7zArgs += "`"$outputFile`""

# Add each item
foreach ($item in $itemsToInclude) {
    $7zArgs += "`"$item`""
}

# Execute 7-Zip from the playbook root so paths are relative
Push-Location $playbookRoot
try {
    $process = Start-Process -FilePath $7z -ArgumentList $7zArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP "7z-stdout.txt") -RedirectStandardError (Join-Path $env:TEMP "7z-stderr.txt")

    if ($process.ExitCode -ne 0) {
        $stderr = Get-Content (Join-Path $env:TEMP "7z-stderr.txt") -Raw -ErrorAction SilentlyContinue
        Write-Host "ERROR: 7-Zip failed with exit code $($process.ExitCode)" -ForegroundColor Red
        if ($stderr) { Write-Host $stderr -ForegroundColor Red }
        exit 1
    }
} finally {
    Pop-Location
    Remove-Item (Join-Path $env:TEMP "7z-stdout.txt") -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:TEMP "7z-stderr.txt") -ErrorAction SilentlyContinue
}

$fileSize = [math]::Round((Get-Item $outputFile).Length / 1KB, 1)
Write-Host "  Archive created: $fileSize KB" -ForegroundColor Green
Write-Host ""

# =========================================================================
# VERIFY ARCHIVE
# =========================================================================

Write-Host "[5/6] Verifying archive integrity..." -ForegroundColor Yellow

$verifyArgs = @("t", "-p$Password", "`"$outputFile`"")
$verifyProc = Start-Process -FilePath $7z -ArgumentList $verifyArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP "7z-verify.txt")

if ($verifyProc.ExitCode -eq 0) {
    Write-Host "  Integrity check: PASSED" -ForegroundColor Green
} else {
    Write-Host "  Integrity check: FAILED" -ForegroundColor Red
    exit 1
}

Remove-Item (Join-Path $env:TEMP "7z-verify.txt") -ErrorAction SilentlyContinue
Write-Host ""

# =========================================================================
# LIST ARCHIVE CONTENTS
# =========================================================================

Write-Host "[6/6] Archive contents:" -ForegroundColor Yellow

$listOut = Join-Path $env:TEMP "7z-list.txt"
$listArgs = @("l", "-p$Password", "`"$outputFile`"")
$listProc = Start-Process -FilePath $7z -ArgumentList $listArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput $listOut

if ($listProc.ExitCode -eq 0) {
    $listing = Get-Content $listOut -Raw
    # Extract just the file listing lines (between the dashed separators)
    $lines = $listing -split "`n"
    $inFiles = $false
    $fileCount = 0
    $unwantedFound = @()
    foreach ($line in $lines) {
        if ($line -match '^---') {
            $inFiles = -not $inFiles
            continue
        }
        if ($inFiles -and $line.Trim().Length -gt 0) {
            $fileCount++
            # Extract filename (last column after the date/time/attr/size fields)
            $fileName = ($line -replace '^.{53}', '').Trim()
            if ($fileName) {
                Write-Host "    $fileName" -ForegroundColor DarkGray
                # Check for accidentally included files
                foreach ($pattern in $excludePatterns) {
                    $checkPattern = $pattern -replace '\*', '.*'
                    if ($fileName -match "(?i)^$checkPattern" -or $fileName -match "(?i)[/\\]$checkPattern") {
                        $unwantedFound += $fileName
                    }
                }
            }
        }
    }
    Write-Host "  Total files in archive: $fileCount" -ForegroundColor Green

    if ($unwantedFound.Count -gt 0) {
        Write-Host "" 
        Write-Host "  WARNING: Unwanted files detected in archive:" -ForegroundColor Red
        foreach ($uf in $unwantedFound) {
            Write-Host "    ! $uf" -ForegroundColor Red
        }
    }
}
Remove-Item $listOut -ErrorAction SilentlyContinue
Write-Host ""

# =========================================================================
# SUMMARY
# =========================================================================

Write-Host "=========================================" -ForegroundColor Green
Write-Host " BUILD SUCCESSFUL" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host " File:     $outputFile" -ForegroundColor White
Write-Host " Size:     $fileSize KB" -ForegroundColor White
Write-Host " Password: $Password" -ForegroundColor White
Write-Host " Version:  $version" -ForegroundColor White
Write-Host ""
Write-Host " Open this file with AME Wizard to apply." -ForegroundColor DarkGray
Write-Host "=========================================" -ForegroundColor Green
