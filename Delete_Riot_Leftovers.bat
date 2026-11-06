@echo off
setlocal
set "RIOT_CLEANER_FILE=%~f0"
set "RIOT_CLEANUP_REPORT=%~dp0Riot_Cleanup_Report.txt"
title Riot and VALORANT Leftover Cleaner - Confirm Before Delete

echo ============================================================
echo   VALORANT / RIOT LEFTOVER CLEANER [MANUAL CONFIRMATION]
echo ============================================================
echo This removes only the folders YOU select, after uninstall.
echo This is not a game uninstaller. Vanguard is NEVER deleted.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$raw = Get-Content -LiteralPath $env:RIOT_CLEANER_FILE -Raw; $sections = [regex]::Split($raw, '(?m)^# POWERSHELL_START\r?$'); if ($sections.Count -lt 2) { throw 'Embedded cleanup section missing' }; Invoke-Expression $sections[1]"
set "EXIT_CODE=%errorlevel%"
echo.
if not "%EXIT_CODE%"=="0" echo [WARNING] Script ended with an error. See the messages above.
echo Cleanup report location: "%RIOT_CLEANUP_REPORT%"
echo.
echo PRESS ANY KEY TO CLOSE THIS WINDOW.
pause >nul
exit /b %EXIT_CODE%
# POWERSHELL_START
$ErrorActionPreference = 'Stop'

# Allowlist only. These are deliberately exact, fixed Windows locations.
$entries = @(
    [pscustomobject]@{ Id = 1; Title = 'VALORANT game folder'; Path = 'C:\Riot Games\VALORANT'; Shared = $false },
    [pscustomobject]@{ Id = 2; Title = 'Riot Client'; Path = 'C:\Riot Games\Riot Client'; Shared = $true },
    [pscustomobject]@{ Id = 3; Title = 'VALORANT local settings/cache'; Path = (Join-Path $env:LOCALAPPDATA 'VALORANT'); Shared = $false },
    [pscustomobject]@{ Id = 4; Title = 'Riot local settings/cache'; Path = (Join-Path $env:LOCALAPPDATA 'Riot Games'); Shared = $true },
    [pscustomobject]@{ Id = 5; Title = 'Riot ProgramData (advanced)'; Path = (Join-Path $env:ProgramData 'Riot Games'); Shared = $true }
)
$lines = New-Object 'System.Collections.Generic.List[string]'
function Report([string] $s) {
    Write-Host $s
    [void]$script:lines.Add($s)
}
function Is-ReparsePoint($item) {
    return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}
function Is-SafeFolder([string] $path) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { return $false }
    # Also check every parent. For example, C:\Riot Games itself might be a
    # junction even when C:\Riot Games\VALORANT is an ordinary directory.
    $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
    $ancestor = $item
    while ($null -ne $ancestor) {
        if (Is-ReparsePoint $ancestor) {
            throw "REFUSING reparse point/junction on path: $($ancestor.FullName)"
        }
        $ancestor = $ancestor.Parent
    }
    # A nested junction or symlink could lead outside the selected folder.
    $link = Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction Stop |
        Where-Object { Is-ReparsePoint $_ } | Select-Object -First 1
    if ($null -ne $link) { throw "REFUSING folder containing a junction/symlink: $($link.FullName)" }
    return $true
}
function Size-InBytes([string] $path) {
    $sum = (Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction Stop |
        Measure-Object -Property Length -Sum).Sum
    if ($null -eq $sum) { return [double]0 }
    return [double]$sum
}
function Save-Report {
    try {
        $lines | Set-Content -LiteralPath $env:RIOT_CLEANUP_REPORT -Encoding UTF8 -ErrorAction Stop
        Write-Host "Report saved: $env:RIOT_CLEANUP_REPORT"
    } catch {
        Write-Host "[WARNING] Could not save report: $($_.Exception.Message)"
    }
}

try {
    Report 'WINDOWS VALORANT / RIOT LEFTOVER CLEANER'
    Report 'Uninstall VALORANT through Windows and exit Riot Client before using this script.'
    Report 'Never run this cleaner on an active Riot install, including one on another drive.'
    Report 'Other Riot games may depend on Riot Client, local data, or ProgramData.'
    Report 'Vanguard is NOT removed. Use Windows Installed apps to uninstall Vanguard.'
    Report ''

    $processNames = @('VALORANT-Win64-Shipping', 'RiotClientServices', 'RiotClientUx', 'RiotClientUxRender', 'LeagueClient', 'LeagueClientUx')
    $running = @(Get-Process -Name $processNames -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        Report ('[STOP] Riot or VALORANT processes are still running: ' + (($running.ProcessName | Sort-Object -Unique) -join ', '))
        Report 'Close the games and exit Riot Client from the system tray; retry.'
        Save-Report
        exit 1
    }

    Report 'AVAILABLE FOLDERS'
    Report '------------------------------------------------------------'
    foreach ($e in $entries) {
        $status = if (Test-Path -LiteralPath $e.Path -PathType Container) { 'FOUND' } else { 'NOT FOUND' }
        $suffix = if ($e.Shared) { ' [SHARED: caution]' } else { '' }
        Report ("[{0}] {1,-9} {2}{3}" -f $e.Id, $status, $e.Path, $suffix)
    }
    Report '------------------------------------------------------------'
    Report '[1-4] are Riot VALORANT clean-uninstall targets.'
    Report '[5] is an EXTRA shared ProgramData location; not required by Riot VALORANT steps.'
    Report 'Vanguard is excluded. Uninstall it via Windows Settings > Apps > Installed apps.'
    Report ''

    Write-Host 'Choose folder numbers separated by commas, e.g. 1,2,3,4'
    Write-Host 'Or enter ALL for 1,2,3,4 only; 5 must be selected explicitly.'
    Write-Host 'Enter Q to quit without deleting anything.'
    $selection = (Read-Host 'Selection').Trim()
    if ($selection -match '^(?i:q|quit|exit)$') {
        Report '[CANCELLED] Nothing was deleted.'
        Save-Report
        exit 0
    }
    if ($selection -ieq 'ALL') { $ids = @(1,2,3,4) }
    elseif ($selection -match '^[1-5](?:[ ,]+[1-5])*$') {
        $ids = @($selection -split '[ ,]+' | ForEach-Object { [int]$_ } | Select-Object -Unique)
    } else {
        Report '[CANCELLED] Invalid selection. Nothing was deleted.'
        Save-Report
        exit 1
    }

    $picked = @($entries | Where-Object { $ids -contains $_.Id })
    $existing = New-Object 'System.Collections.Generic.List[object]'
    Report ''
    Report 'SELECTED FOLDERS (pre-delete scan)'
    Report '------------------------------------------------------------'
    foreach ($e in $picked) {
        try {
            if (-not (Test-Path -LiteralPath $e.Path -PathType Container)) {
                Report ("[SKIP] Not found: {0}" -f $e.Path)
                continue
            }
            if (-not (Is-SafeFolder $e.Path)) { continue }
            $bytes = Size-InBytes $e.Path
            [void]$existing.Add([pscustomobject]@{ Entry = $e; Bytes = $bytes })
            Report ("[{0}] {1:N2} MB | {2}" -f $e.Id, ($bytes / 1MB), $e.Path)
        } catch {
            Report ("[SKIP] Unsafe or inaccessible: {0} - {1}" -f $e.Path, $_.Exception.Message)
        }
    }
    if ($existing.Count -eq 0) {
        Report 'Nothing eligible for deletion. No files were changed.'
        Save-Report
        exit 0
    }
    $total = [double]0
    foreach ($x in $existing) { $total += $x.Bytes }
    Report ('------------------------------------------------------------')
    Report ("APPROXIMATE SELECTED SIZE: {0:N2} MB / {1:N2} GB" -f ($total / 1MB), ($total / 1GB))
    Report ''
    Report 'WARNING: The folders above will be PERMANENTLY deleted (not sent to Recycle Bin).'
    Report 'This could remove settings, logs and Riot Client required by other games.'
    Report 'If VALORANT or another Riot game is installed, cancel now.'
    $confirmation = (Read-Host 'Type DELETE (uppercase) to permanently remove ONLY the selected folders').Trim()
    if ($confirmation -cne 'DELETE') {
        Report '[CANCELLED] Confirmation did not match. Nothing was deleted.'
        Save-Report
        exit 0
    }
    Report ''
    Report 'DELETION RESULTS'
    Report '------------------------------------------------------------'
    $success = [double]0
    foreach ($x in $existing) {
        $path = $x.Entry.Path
        try {
            # Repeat the safety check immediately before each removal.
            if (Is-SafeFolder $path) {
                Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
                if (Test-Path -LiteralPath $path) { throw 'Folder remains on disk' }
                $success += $x.Bytes
                Report ("[DELETED] {0} ({1:N2} MB measured before removal)" -f $path, ($x.Bytes / 1MB))
            } else { Report ("[SKIP] No longer found: {0}" -f $path) }
        } catch {
            Report ("[FAILED / POSSIBLY PARTIAL] {0} - {1}" -f $path, $_.Exception.Message)
        }
    }
    Report '------------------------------------------------------------'
    Report ("APPROXIMATE SUCCESSFUL REMOVALS: {0:N2} MB / {1:N2} GB" -f ($success / 1MB), ($success / 1GB))
    Report 'Exact freed disk space may differ. Re-run the scanner to verify.'
    Report 'Riot Vanguard, drivers, services and registry were NOT touched.'
    Report 'For Vanguard, uninstall through Windows Installed apps, then re-run the size checker.'
    Save-Report
} catch {
    Report ("[ERROR] {0}" -f $_.Exception.Message)
    Save-Report
    exit 1
}
