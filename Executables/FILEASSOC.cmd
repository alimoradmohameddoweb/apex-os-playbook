@echo off
:: FILEASSOC.cmd - Set default file associations for common formats
:: Maps archive formats to 7-Zip (if installed)
title Apex OS - File Associations

:: =====================================================================
:: ARCHIVE FORMATS - 7-ZIP (only if installed)
:: =====================================================================

if exist "C:\Program Files\7-Zip\7zFM.exe" (
    ftype 7-Zip.Archive="C:\Program Files\7-Zip\7zFM.exe" "%%1"

    assoc .7z=7-Zip.Archive
    assoc .zip=7-Zip.Archive
    assoc .rar=7-Zip.Archive
    assoc .tar=7-Zip.Archive
    assoc .gz=7-Zip.Archive
    assoc .bz2=7-Zip.Archive
    assoc .xz=7-Zip.Archive
    assoc .zst=7-Zip.Archive
    assoc .lz=7-Zip.Archive
    assoc .cab=7-Zip.Archive
    assoc .iso=7-Zip.Archive
    assoc .001=7-Zip.Archive
)

echo.
echo Apex OS: File associations configured.
