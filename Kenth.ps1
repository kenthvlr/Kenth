# ==============================================================================
#  Kenth.ps1  —  Console / CLI entry point
#  Run: powershell -NoProfile -ExecutionPolicy Bypass -File Kenth.ps1
# ==============================================================================

#Requires -Version 5.1
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ── Load all function modules ─────────────────────────────────────────────────
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$modules = @(
    "functions\core.ps1",
    "functions\installer.ps1",
    "functions\tweaks.ps1",
    "functions\gaming.ps1",
    "functions\privacy.ps1",
    "functions\debloat.ps1",
    "functions\network.ps1",
    "functions\services.ps1",
    "functions\cache.ps1",
    "functions\hardware.ps1",
    "functions\sysinfo.ps1",
    "functions\edge.ps1",
    "functions\onedrive.ps1",
    "functions\menu.ps1"
)
foreach ($m in $modules) {
    $path = Join-Path $root $m
    if (Test-Path $path) {
        . $path
    } else {
        Write-Warning "Missing module: $m"
    }
}

# ── Setup ─────────────────────────────────────────────────────────────────────
Enable-VT
Confirm-Admin

# ── Launch ────────────────────────────────────────────────────────────────────
Invoke-MainMenu
