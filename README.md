# VALORANT & Riot Games Leftover Cleaner (Windows)

**Find out how much space VALORANT leaves behind after uninstalling, then optionally remove leftover Riot Client and cache folders.** Two standalone Windows `.bat` files: a read-only size scanner and an interactive, opt-in cleanup tool.

Searching for **"VALORANT still taking up space after uninstall"**, **"Riot Client 800 MB after uninstall"**, **"how to completely uninstall VALORANT"**, **"Riot Games AppData cleanup"**, or **"move VALORANT from C drive to D/P drive"**? This repository helps with the **leftover-files** part. It is *not* an installer, game mover, registry cleaner, or Vanguard removal tool.

> [!IMPORTANT]
> **Unofficial community utility. Not affiliated with Riot Games or VALORANT.** Uninstall VALORANT in **Windows Settings > Apps > Installed apps** first. **Do not run the cleaner after reinstalling VALORANT**, even if the game files are now on another drive: the Riot Client and caches on C: may still be needed.

## Download and use

1. Download the repository as a ZIP using **Code > Download ZIP** on GitHub, or download the `.bat` files individually.
2. Extract them into a normal writable folder, such as `Downloads`.
3. Double-click **[`Check_Riot_Leftovers.bat`](Check_Riot_Leftovers.bat)** to inspect disk usage. It is **read-only**: nothing is removed.
4. After you have uninstalled VALORANT, closed Riot Client, and decided you want the cleanup, double-click **[`Delete_Riot_Leftovers.bat`](Delete_Riot_Leftovers.bat)**.
5. Choose a comma-separated set of folders (`1,2,3,4`), `ALL` (same four), or `Q` to exit. The advanced ProgramData folder (`5`) must be selected explicitly.
6. Review the selected folders and sizes. Type `DELETE` (all caps) to confirm permanent removal. Any other input cancels.
7. Re-run the scanner to confirm what remains.

Both batch files keep the Command Prompt window open until you press a key. They use built-in **Windows PowerShell 5.1** and do not require installing Python or third-party software.

## Included scripts

| File | Purpose | Changes files? |
| --- | --- | --- |
| [`Check_Riot_Leftovers.bat`](Check_Riot_Leftovers.bat) | Scans known locations and saves `Riot_Leftover_Size_Report.txt` alongside the script | **No**, except the report text file |
| [`Delete_Riot_Leftovers.bat`](Delete_Riot_Leftovers.bat) | Shows a menu and size preview, then optionally permanently removes exactly the selected allowlisted directories | **Yes**, only after you type `DELETE`; saves `Riot_Cleanup_Report.txt` |

The deletion script has no custom-drive discovery, edits no registry keys, stops or deletes no services, removes no Vanguard drivers, and does not automatically elevate to Administrator. It refuses symbolic links or junctions on the target path (including its parent folders) or inside the target, and stops if common Riot game/client processes are detected. If access is denied, it reports the failure rather than forcing permissions.

## Which folders are checked?

| # | Default location | Cleanup availability | Notes |
| --- | --- | --- | --- |
| 1 | `C:\Riot Games\VALORANT` | Yes | Old game files, if they still exist |
| 2 | `C:\Riot Games\Riot Client` | Yes | Shared launcher; may be needed by another Riot game |
| 3 | `%LOCALAPPDATA%\VALORANT` | Yes | Cache, logs, and **local game configuration** |
| 4 | `%LOCALAPPDATA%\Riot Games` | Yes | Shared local Riot Client/game data |
| 5 | `%PROGRAMDATA%\Riot Games` | **Advanced, manual opt-in** | Shared data; not part of Riot's VALORANT-specific clean-uninstall steps |
| — | `%PROGRAMFILES%\Riot Vanguard` | **Scanner only** | Use the **official Vanguard uninstaller**, not this cleaner |

If you have League of Legends, TFT, 2XKO, or any other Riot game, don't clean shared folders (`2`, `4`, `5`) without knowing their impact. This script is intended for the standard C: layout and current Windows user; it does not discover custom installation paths.

### What about Riot Vanguard?

**Uninstall Riot Vanguard separately** using **Windows Settings > Apps > Installed apps > Riot Vanguard > Uninstall**, then **restart Windows** and run the scanner again. Normally the Vanguard folder disappears after uninstalling. Seeing around 200–300 MB in the scanner before that step is not a cleaner failure.

The cleanup script deliberately **does not delete Vanguard files, drivers, or services**. If Vanguard's normal uninstaller fails, use Riot's official instructions instead of forcibly deleting a running anti-cheat driver: [Official Riot Vanguard uninstall guide](https://support.riotgames.com/en-us/riot/performance/uninstall-and-disable-vanguard).

### Do I lose crosshairs or skins?

Your **account-owned skins** are tied to your Riot account, not these local folders. However, **local configuration and logs can be permanently lost**, particularly files under `%LOCALAPPDATA%\VALORANT\Saved\Config`. Cloud synchronization is not a substitute for a known-good backup. Export or back up settings and crosshair/profile configurations before cleanup if you care about preserving them.

### Example scan output

```text
NOT FOUND  | C:\Riot Games\VALORANT
    881.35 MB | 100 MB or more | C:\Riot Games\Riot Client
    275.49 MB | 100 MB or more | C:\Users\YOU\AppData\Local\VALORANT
     30.06 MB | under 100 MB  | C:\Users\YOU\AppData\Local\Riot Games
      3.53 MB | under 100 MB  | C:\ProgramData\Riot Games
    289.99 MB | 100 MB or more | C:\Program Files\Riot Vanguard
TOTAL (excluding Vanguard): 1,190.43 MB / 1.16 GB
VANGUARD (separate):      289.99 MB / 0.28 GB
```

These are example figures from one machine, **not typical or guaranteed sizes**. Logical file size is not the same as Windows disk space actually reclaimed.

## Safety notes

- **Delete is permanent:** `Remove-Item -Recurse -Force` does not use the Recycle Bin. Cancel at any point before typing `DELETE`.
- **Run cleanup after uninstall, before reinstall.** The app may still be installed on a different drive and depend on C: data. Do not delete a working Riot Client just to free storage.
- **No automated registry/driver manipulation.** Running as Administrator is not required for the scanner. Deletion of protected shared directories may fail without permissions; do not grant blanket elevated permissions merely to force deletion.
- **No telemetry or network calls.** You can review both standalone batch files as plain text before running them.
- **Windows only.** PowerShell must be present and enabled. The `.bat` files are text wrappers containing their own PowerShell code.
- **Testing:** Both utilities have been exercised in one Windows 11 cleanup workflow, and the scanner confirmed the expected Riot folders were gone afterward. Automated safety checks verify key guardrails, but this is **not** a comprehensive Windows compatibility/security audit. Always review selected paths before deleting.

## Frequently asked questions

**Does VALORANT still use C: after I reinstall the game on D: or P:?** Often yes. The launcher, anti-cheat, and local data may be stored on the Windows drive even if the main game installation is elsewhere. **Do not run the cleaner on an active/reinstalled installation.**

**Why does Riot Vanguard still show 289 MB?** It is deliberately outside the cleaner's deletion allowlist. Uninstall Riot Vanguard in Windows Installed apps and restart. Re-run the scanner to verify.

**Does `ALL` delete ProgramData or Vanguard?** No. `ALL` selects only folders 1–4. The extra shared ProgramData directory is option 5 and requires explicit selection. Vanguard is never a selectable cleanup target.

**How much disk space will I save?** The scanner shows the approximate logical sizes of the known folders. Results depend on your machine; the scanner does not promise actual NTFS allocation or full-disk coverage.

**Can I use it to move VALORANT to another drive?** No. It only deals with leftovers **after uninstalling**, before reinstalling elsewhere. Move/reinstall through Riot's official installer, not this utility.

## Official references

- [Riot Support: Uninstall and Reinstall Games](https://support.riotgames.com/en-us/riot/performance/uninstall-and-reinstall-games) - game uninstall and VALORANT-specific cache cleanup paths.
- [Riot Support: Uninstall and Disable Vanguard](https://support.riotgames.com/en-us/riot/performance/uninstall-and-disable-vanguard) - correct procedure for removing the anti-cheat.
- [Riot Support: Network, System and Logs](https://support.riotgames.com/en-us/riot/performance/network-system-and-logs-windows) - confirms location of VALORANT local config files.

## License

MIT licensed. See [LICENSE](LICENSE). Contributions, fixes, and Windows test reports are welcome.

Made by [sha6a6](https://github.com/latenitekode).
