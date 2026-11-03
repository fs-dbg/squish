param (
    [Parameter(Mandatory=$true)]
    [string]$InputFile
)

$InputFile = Resolve-Path $InputFile
$OutputDir = Split-Path $InputFile
$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$OutputFile = Join-Path $OutputDir "${BaseName}_squished.mp4"

Write-Host "[+] Analyzing video..." -ForegroundColor Cyan

$DurationStr = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $InputFile
$Duration = [double]$DurationStr

# target size config here. uses discords current 20mb limit (11/3/2026)
$TargetSizeBits = 19.5 * 1024 * 1024 * 8
$TargetTotalBitrate = $TargetSizeBits / $Duration

$AudioBitrate = 128000
$VideoBitrate = $TargetTotalBitrate - $AudioBitrate

if ($VideoBitrate -lt 150000) { $VideoBitrate = 150000 }

$VideoBitrateK = [Math]::Round($VideoBitrate / 1000)
Write-Host "[+] Calculated Target Bitrate: ${VideoBitrateK}k" -ForegroundColor Green

$PresetSetting = "veryfast" 

Write-Host "[+] Squishing Video (Pass 1/2 - High Quality Compression)..." -ForegroundColor Yellow
& ffmpeg -y -i $InputFile -c:v libx264 -preset $PresetSetting -b:v "${VideoBitrateK}k" -pass 1 -an -f mp4 NUL

Write-Host "[+] Squishing Video (Pass 2/2 - Finalizing)..." -ForegroundColor Yellow
& ffmpeg -y -i $InputFile -c:v libx264 -preset $PresetSetting -b:v "${VideoBitrateK}k" -pass 2 -c:a aac -b:a 128k $OutputFile

if (Test-Path "ffmpeg2pass-0.log") { Remove-Item "ffmpeg2pass-0.log" }
if (Test-Path "ffmpeg2pass-0.log.mbtree") { Remove-Item "ffmpeg2pass-0.log.mbtree" }

Write-Host "`n[!] Done! Saved to: $OutputFile" -ForegroundColor Green
