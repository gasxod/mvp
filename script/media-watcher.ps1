param(
    [string]$MediaDir = "C:\mpv\media",
    [string]$MpvPath = "C:\mpv\mpv.exe",
    [int]$ImageDuration = 10
)

$Playlist = Join-Path $MediaDir "playlist.m3u"
$MpvArgs = "--fs --loop-playlist=inf --image-display-duration=$ImageDuration --no-osd-bar --really-quiet"

function Build-Playlist {
    $files = Get-ChildItem $MediaDir -File |
        Where-Object { $_.Extension -match 'mp4|avi|mkv|mov|jpg|jpeg|png' } |
        Sort-Object Name

    $list = @("#EXTM3U")
    foreach ($f in $files) {
        $list += $f.FullName
    }

    $list | Set-Content -Encoding UTF8 $Playlist
}

function Restart-Mpv {
    Get-Process mpv -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process $MpvPath -ArgumentList "`"$Playlist`" $MpvArgs"
}

# ---- hide window ----
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
[Win32]::ShowWindow([Win32]::GetConsoleWindow(), 0)

# ---- initial ----
Build-Playlist
Restart-Mpv

# ---- watcher ----
$fsw = New-Object System.IO.FileSystemWatcher $MediaDir
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

Register-ObjectEvent $fsw Created -Action { Build-Playlist; Restart-Mpv }
Register-ObjectEvent $fsw Deleted -Action { Build-Playlist; Restart-Mpv }
Register-ObjectEvent $fsw Renamed -Action { Build-Playlist; Restart-Mpv }

while ($true) { Start-Sleep 1 }
