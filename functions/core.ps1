# ==============================================================================
#  core.ps1  —  Shared helpers, colors, admin elevation, registry utilities
# ==============================================================================

$ESC     = [char]27
function c($r,$g,$b)  { "${ESC}[38;2;${r};${g};${b}m" }
function cb($r,$g,$b) { "${ESC}[48;2;${r};${g};${b}m" }
$RESET   = "${ESC}[0m"
$BOLD    = "${ESC}[1m"
$PURPLE  = c 160 32  240
$LPURPLE = c 200 100 255
$DPURPLE = c 90  0   160
$MAGENTA = c 220 80  220
$WHITE   = c 240 240 240
$GRAY    = c 150 150 170
$DGRAY   = c 80  80  100
$GREEN   = c 80  220 120
$RED     = c 220 60  60
$YELLOW  = c 240 200 60
$CYAN    = c 80  200 220

function Write-Color {
    param([string]$Text, [switch]$NoNewLine)
    if ($NoNewLine) { Write-Host $Text -NoNewline } else { Write-Host $Text }
}

function Divider {
    param($char = "=", $width = 78, $color = $PURPLE)
    Write-Color "$color$($char * $width)$RESET"
}

function Header($title) {
    Write-Color ""
    Divider "=" 78 $PURPLE
    Write-Color "${PURPLE}  ${LPURPLE}${BOLD}  $title  ${RESET}"
    Divider "=" 78 $PURPLE
    Write-Color ""
}

function Done($msg = "Done!")  { Write-Color "  ${GREEN}${BOLD}[OK]${RESET}  ${WHITE}$msg${RESET}" }
function Step($msg)            { Write-Color "  ${LPURPLE}[>>]${RESET}  $msg" }
function Warn($msg)            { Write-Color "  ${YELLOW}${BOLD}[!]${RESET}   ${YELLOW}$msg${RESET}" }
function Fail($msg)            { Write-Color "  ${RED}${BOLD}[X]${RESET}   ${RED}$msg${RESET}" }
function Info($msg)            { Write-Color "  ${CYAN}[i]${RESET}   ${GRAY}$msg${RESET}" }

function Pause-Continue {
    Write-Color ""
    Divider "-" 78 $DPURPLE
    Write-Color "  ${GRAY}Press any key to continue...${RESET}"
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Read-MenuChoice {
    param($prompt = "Select")
    Write-Color ""
    Write-Color "  ${PURPLE}>>  ${RESET}${LPURPLE}${prompt}${RESET}${WHITE}: ${RESET}" -NoNewLine
    return (Read-Host).Trim()
}

# ── Registry helper ─────────────────────────────────────────────────────────
function Set-RegValue {
    param($path, $name, $type, $value)
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Type $type -Value $value -Force
}

# ── AppX removal ─────────────────────────────────────────────────────────────
function Remove-AppxSilent($pattern) {
    Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*$pattern*" } |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.PackageName -like "*$pattern*" } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# ── Virtual Terminal (ANSI) enable ──────────────────────────────────────────
function Enable-VT {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $PSStyle.OutputRendering = 'Ansi'
        return
    }
    try {
        Add-Type -MemberDefinition @"
[DllImport("kernel32.dll",SetLastError=true)] public static extern bool SetConsoleMode(IntPtr h,int m);
[DllImport("kernel32.dll",SetLastError=true)] public static extern bool GetConsoleMode(IntPtr h,out int m);
[DllImport("kernel32.dll",SetLastError=true)] public static extern IntPtr GetStdHandle(int n);
"@ -Name WC -Namespace K -ErrorAction SilentlyContinue
        $h = [K.WC]::GetStdHandle(-11); $m = 0
        [K.WC]::GetConsoleMode($h, [ref]$m) | Out-Null
        [K.WC]::SetConsoleMode($h, $m -bor 4) | Out-Null
    } catch {}
}

# ── Admin elevation ──────────────────────────────────────────────────────────
function Confirm-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = [Security.Principal.WindowsPrincipal]$id
    if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  [!] Elevating to Administrator..." -ForegroundColor Yellow
        $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        if (-not $PSCommandPath) {
            $tmp = "$env:TEMP\KenthRun.ps1"
            $MyInvocation.MyCommand.ScriptBlock | Out-File $tmp -Encoding UTF8
            $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`""
        }
        Start-Process powershell -Verb RunAs -ArgumentList $arg
        exit
    }
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ── Logo ─────────────────────────────────────────────────────────────────────
function Show-Logo {
    Clear-Host
    $L = $LPURPLE; $P = $PURPLE; $M = $MAGENTA; $W = $WHITE; $G = $GRAY; $R = $RESET; $B = $BOLD
    Write-Color ""
    Write-Color "${P}  +==========================================================================+${R}"
    Write-Color "${P}  |                                                                          |${R}"
    Write-Color "${P}  |   ${L}${B}##  ## ###### ##  ## ########  ##  ##${R}  ${M}|${R}  ${W}KENTH PC TWEAK TOOL${R}         ${P}|${R}"
    Write-Color "${P}  |   ${L}${B}##  ## ##     ### ##    ##     ##  ##${R}  ${M}|${R}  ${G}v5.0  by kenthvlr${R}           ${P}|${R}"
    Write-Color "${P}  |   ${L}${B}###### ####   ######    ##    #######${R}  ${M}|${R}  ${G}FPS  PING  PRIVACY${R}          ${P}|${R}"
    Write-Color "${P}  |   ${L}${B}##  ## ##     ## ###    ##    ##  ##${R}   ${M}|${R}  ${G}Debloat  Tweaks  Apps${R}       ${P}|${R}"
    Write-Color "${P}  |   ${L}${B}##  ## ###### ##  ##    ##    ##  ##${R}   ${M}|${R}  ${G}github.com/kenthvlr/Kenth${R}   ${P}|${R}"
    Write-Color "${P}  |                                                                          |${R}"
    Write-Color "${P}  +==========================================================================+${R}"
    Write-Color ""
}
