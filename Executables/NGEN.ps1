# NGEN.ps1 - .NET Native Image Generator
# Compiles all pending .NET assemblies into native images for faster startup.
# This process can take several minutes but significantly improves .NET app
# launch times and reduces JIT compilation overhead at runtime.

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Apex OS: Starting .NET Native Image Generation..." -ForegroundColor Cyan

# Find all installed .NET Framework directories
$frameworkDirs = @(
    "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319",
    "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319",
    "$env:SystemRoot\Microsoft.NET\Framework\v2.0.50727",
    "$env:SystemRoot\Microsoft.NET\Framework64\v2.0.50727"
)

foreach ($dir in $frameworkDirs) {
    $ngenPath = Join-Path $dir "ngen.exe"
    if (Test-Path $ngenPath) {
        Write-Host "Processing: $dir" -ForegroundColor Yellow
        
        # Update queued items - compiles all assemblies waiting in the queue
        & $ngenPath executeQueuedItems 2>$null
        
        # Update installed native images
        & $ngenPath update /force 2>$null
        
        Write-Host "  Completed: $dir" -ForegroundColor Green
    }
}

# Process .NET Core / .NET 5+ installations via crossgen if available
$dotnetRoot = "$env:ProgramFiles\dotnet\shared"
if (Test-Path $dotnetRoot) {
    $runtimes = Get-ChildItem -Path $dotnetRoot -Directory -ErrorAction SilentlyContinue
    foreach ($runtime in $runtimes) {
        $versions = Get-ChildItem -Path $runtime.FullName -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
        foreach ($version in $versions) {
            $crossgen = Join-Path $version.FullName "crossgen2.exe"
            if (Test-Path $crossgen) {
                Write-Host "Found crossgen2 in: $($version.FullName)" -ForegroundColor Yellow
                # crossgen2 is typically invoked during build, not post-install
                # Just log its presence for diagnostics
            }
        }
    }
}

# Run ReadyBoost optimization pass
$readyBoostService = Get-Service -Name "EMDMgmt" -ErrorAction SilentlyContinue
if ($readyBoostService -and $readyBoostService.Status -eq 'Running') {
    Write-Host "ReadyBoost service detected - no action needed." -ForegroundColor Gray
}

# Optimize .NET assemblies in the GAC
$gacPath = "$env:SystemRoot\assembly"
if (Test-Path $gacPath) {
    Write-Host "Optimizing Global Assembly Cache..." -ForegroundColor Yellow
    $ngen64 = "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\ngen.exe"
    $ngen32 = "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\ngen.exe"
    
    if (Test-Path $ngen64) {
        & $ngen64 executeQueuedItems 2>$null
    }
    if (Test-Path $ngen32) {
        & $ngen32 executeQueuedItems 2>$null
    }
    Write-Host "  GAC optimization complete." -ForegroundColor Green
}

Write-Host ""
Write-Host "Apex OS: .NET Native Image Generation complete." -ForegroundColor Cyan
