@echo off
setlocal
set "RIOT_CHECKER_FILE=%~f0"
set "RIOT_REPORT_FILE=%~dp0Riot_Leftover_Size_Report.txt"
title Riot Leftover Size Checker - Stays Open

echo ============================================================
echo    VALORANT / RIOT LEFTOVER SIZE CHECKER [READ ONLY SCAN]
echo ============================================================
echo Checking standard locations. No game files will be changed.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$raw = Get-Content -LiteralPath $env:RIOT_CHECKER_FILE -Raw; $sections = [regex]::Split($raw, '(?m)^# POWERSHELL_START\r?$'); if ($sections.Count -lt 2) { throw 'Embedded scan section missing' }; Invoke-Expression $sections[1]"

echo.
if errorlevel 1 echo [WARNING] The scan ended with an error. You can send me a screenshot.
echo Results are also saved to:
echo "%RIOT_REPORT_FILE%"
echo.
echo PRESS ANY KEY TO CLOSE THIS WINDOW.
pause >nul
exit /b
# POWERSHELL_START
$ErrorActionPreference = 'Stop'
$entries = @(
    @{ Title = 'Game files';          Path = 'C:\Riot Games\VALORANT';         Separate = $false },
    @{ Title = 'Riot Client';         Path = 'C:\Riot Games\Riot Client';      Separate = $false },
    @{ Title = 'VALORANT local data'; Path = "$env:LOCALAPPDATA\VALORANT";     Separate = $false },
    @{ Title = 'Riot local data';     Path = "$env:LOCALAPPDATA\Riot Games";  Separate = $false },
    @{ Title = 'Riot program data';   Path = "$env:ProgramData\Riot Games";   Separate = $false },
    @{ Title = 'Riot Vanguard';       Path = "$env:ProgramFiles\Riot Vanguard"; Separate = $true }
)
$lines = New-Object System.Collections.Generic.List[string]
function Show-Line([string] $line) {
    Write-Host $line
    [void]$lines.Add($line)
}
$total = [double]0
$vgTotal = [double]0
Show-Line 'FOLDER SIZES (MB)'
Show-Line '------------------------------------------------------------'
foreach ($entry in $entries) {
    $folder = $entry.Path
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        Show-Line ("NOT FOUND  | {0}" -f $folder)
        continue
    }
    $issues = @()
    $fileList = @(Get-ChildItem -LiteralPath $folder -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +issues)
    $bytes = ($fileList | Measure-Object -Property Length -Sum).Sum
    if ($null -eq $bytes) { $bytes = 0 }
    $bytes = [double]$bytes
    if ($entry.Separate) { $vgTotal += $bytes } else { $total += $bytes }
    $status = if ($bytes -ge 100MB) { '100 MB or more' } else { 'under 100 MB' }
    $warning = if ($issues.Count -gt 0) { ' [some files inaccessible]' } else { '' }
    Show-Line ("{0,10:N2} MB | {1,-14} | {2}{3}" -f ($bytes / 1MB), $status, $folder, $warning)
}
Show-Line '------------------------------------------------------------'
Show-Line ("TOTAL (excluding Vanguard): {0:N2} MB / {1:N2} GB" -f ($total / 1MB), ($total / 1GB))
Show-Line ("VANGUARD (separate):      {0:N2} MB / {1:N2} GB" -f ($vgTotal / 1MB), ($vgTotal / 1GB))
Show-Line ''
Show-Line 'No Riot or VALORANT files were changed or deleted.'
Show-Line 'Sizes are approximate logical file sizes, not exact allocated disk usage.'
try {
    $lines | Set-Content -LiteralPath $env:RIOT_REPORT_FILE -Encoding UTF8 -ErrorAction Stop
    Write-Host ("Report saved: {0}" -f $env:RIOT_REPORT_FILE)
} catch {
    Write-Host ("Could not save report: {0}" -f $_.Exception.Message)
}
