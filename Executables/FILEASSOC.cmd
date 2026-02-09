@echo off
:: FILEASSOC.cmd — Set default file associations for common formats
:: Maps media, archive, and document formats to installed applications
:: (7-Zip for archives, VLC for media)
title Apex OS — File Associations

:: =====================================================================
:: ARCHIVE FORMATS → 7-ZIP
:: =====================================================================

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

:: =====================================================================
:: VIDEO FORMATS → VLC
:: =====================================================================

ftype VLC.MediaFile="C:\Program Files\VideoLAN\VLC\vlc.exe" --started-from-file "%%1"

assoc .mp4=VLC.MediaFile
assoc .mkv=VLC.MediaFile
assoc .avi=VLC.MediaFile
assoc .mov=VLC.MediaFile
assoc .wmv=VLC.MediaFile
assoc .flv=VLC.MediaFile
assoc .webm=VLC.MediaFile
assoc .m4v=VLC.MediaFile
assoc .mpg=VLC.MediaFile
assoc .mpeg=VLC.MediaFile
assoc .3gp=VLC.MediaFile
assoc .ts=VLC.MediaFile
assoc .vob=VLC.MediaFile

:: =====================================================================
:: AUDIO FORMATS → VLC
:: =====================================================================

assoc .mp3=VLC.MediaFile
assoc .flac=VLC.MediaFile
assoc .wav=VLC.MediaFile
assoc .aac=VLC.MediaFile
assoc .ogg=VLC.MediaFile
assoc .wma=VLC.MediaFile
assoc .m4a=VLC.MediaFile
assoc .opus=VLC.MediaFile
assoc .alac=VLC.MediaFile
assoc .aiff=VLC.MediaFile

:: =====================================================================
:: PLAYLIST FORMATS → VLC
:: =====================================================================

assoc .m3u=VLC.MediaFile
assoc .m3u8=VLC.MediaFile
assoc .pls=VLC.MediaFile
assoc .xspf=VLC.MediaFile

echo.
echo Apex OS: File associations configured.
