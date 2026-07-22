# Kenth — Troubleshooting Guide

## GUI won't open / window is blank
**Cause:** PowerShell execution policy blocking the script.
**Fix:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
powershell -NoProfile -ExecutionPolicy Bypass -File KenthUI.ps1
```

## "??? " appearing before buttons / checkboxes
**Cause:** PowerShell script saved with wrong encoding (ANSI instead of UTF-8).
**Fix:** Open `KenthUI.ps1` in VS Code → bottom-right → change encoding to **UTF-8** → Save.

## App installation crashes
**Cause:** winget not installed, or running without full path.
**Fix:**
1. Install winget: open Microsoft Store → search **App Installer** → install it
2. Restart PowerShell
3. Test: `winget --version` in a terminal

## "Access denied" or tweaks not applying
**Cause:** Not running as Administrator.
**Fix:** Right-click `KenthUI.ps1` → **Run with PowerShell as Administrator**
Or: `Start-Process powershell -Verb RunAs -ArgumentList "-File KenthUI.ps1"`

## winget is installed but the installer still says "not found"
**Cause:** winget binary not in PATH in the current PowerShell session.
**Fix:** Close PowerShell and reopen it. Or restart the PC after installing App Installer.

## Service won't disable ("Access is denied")
**Cause:** Some protected services (Defender, etc.) can't be disabled from user level.
**Fix:** Run as Administrator. Some services are protected by PPL and require third-party tools.

## "Get-WmiObject is deprecated" warnings on PowerShell 7+
**Cause:** WMI calls using the old cmdlet name.
**Fix:** This is a warning, not an error — the script still works. The warning is cosmetic.

## Running via `iwr ... | iex` — functions not loading
**Cause:** When piped via `iex`, the `functions/` folder doesn't exist on disk.
**Fix:** The GUI (`KenthUI.ps1`) is fully standalone and works via `iex`.
For console mode, download the full zip and run `Kenth.ps1` locally.

## Dark window / no GUI elements visible
**Cause:** GPU driver issue with WPF rendering.
**Fix:** Try: `$env:DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1=1; powershell -File KenthUI.ps1`

## "The term 'Invoke-DisableTips' is not recognized" (console mode)
**Cause:** Running `KenthUI.ps1` or `Kenth.ps1` without the `functions/` folder.
**Fix:** Make sure the `functions/` folder is in the same directory as `KenthUI.ps1`.

## Restart required notice
Many tweaks (HAGS, dynamic tick, power plan, hibernation) require a **restart** to take full effect. 
After Full Auto Mode, always restart your PC.
