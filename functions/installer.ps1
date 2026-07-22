# ==============================================================================
#  installer.ps1  —  App installer powered by winget (100+ apps, 12 categories)
# ==============================================================================

$AppCategories = [ordered]@{

    "Browsers" = [ordered]@{
        "1"  = @{ name = "Google Chrome";        id = "Google.Chrome" }
        "2"  = @{ name = "Mozilla Firefox";      id = "Mozilla.Firefox" }
        "3"  = @{ name = "Brave Browser";        id = "Brave.Brave" }
        "4"  = @{ name = "Opera GX";             id = "Opera.OperaGX" }
        "5"  = @{ name = "Vivaldi";              id = "Vivaldi.Vivaldi" }
        "6"  = @{ name = "LibreWolf";            id = "LibreWolf.LibreWolf" }
        "7"  = @{ name = "Tor Browser";          id = "TorProject.TorBrowser" }
        "8"  = @{ name = "Waterfox";             id = "Waterfox.Waterfox" }
    }

    "Communication" = [ordered]@{
        "1"  = @{ name = "Discord";              id = "Discord.Discord" }
        "2"  = @{ name = "Telegram";             id = "Telegram.TelegramDesktop" }
        "3"  = @{ name = "Signal";               id = "OpenWhisperSystems.Signal" }
        "4"  = @{ name = "Slack";                id = "SlackTechnologies.Slack" }
        "5"  = @{ name = "Zoom";                 id = "Zoom.Zoom" }
        "6"  = @{ name = "Microsoft Teams";      id = "Microsoft.Teams" }
        "7"  = @{ name = "Mumble";               id = "Mumble.Mumble" }
        "8"  = @{ name = "Element (Matrix)";     id = "Element.Element" }
    }

    "Gaming" = [ordered]@{
        "1"  = @{ name = "Steam";                id = "Valve.Steam" }
        "2"  = @{ name = "Epic Games Launcher";  id = "EpicGames.EpicGamesLauncher" }
        "3"  = @{ name = "GOG Galaxy";           id = "GOG.Galaxy" }
        "4"  = @{ name = "Battle.net";           id = "Blizzard.BattleNet" }
        "5"  = @{ name = "EA App";               id = "ElectronicArts.EADesktop" }
        "6"  = @{ name = "Ubisoft Connect";      id = "Ubisoft.Connect" }
        "7"  = @{ name = "Playnite";             id = "Playnite.Playnite" }
        "8"  = @{ name = "MSI Afterburner";      id = "Guru3D.Afterburner" }
        "9"  = @{ name = "RTSS (Frame Limiter)"; id = "Guru3D.RTSS" }
        "10" = @{ name = "HWiNFO64";             id = "REALiX.HWiNFO" }
    }

    "Media & Audio" = [ordered]@{
        "1"  = @{ name = "Spotify";              id = "Spotify.Spotify" }
        "2"  = @{ name = "VLC Media Player";     id = "VideoLAN.VLC" }
        "3"  = @{ name = "MPC-HC";               id = "clsid2.mpc-hc" }
        "4"  = @{ name = "foobar2000";           id = "PeterPawlowski.foobar2000" }
        "5"  = @{ name = "Audacity";             id = "Audacity.Audacity" }
        "6"  = @{ name = "OBS Studio";           id = "OBSProject.OBSStudio" }
        "7"  = @{ name = "HandBrake";            id = "HandBrake.HandBrake" }
        "8"  = @{ name = "AIMP";                 id = "AIMP.AIMP" }
        "9"  = @{ name = "MusicBee";             id = "MusicBee.MusicBee" }
        "10" = @{ name = "K-Lite Mega Codec";    id = "CodecGuide.K-LiteCodecPack.Mega" }
    }

    "Development" = [ordered]@{
        "1"  = @{ name = "VS Code";              id = "Microsoft.VisualStudioCode" }
        "2"  = @{ name = "Git";                  id = "Git.Git" }
        "3"  = @{ name = "Node.js LTS";          id = "OpenJS.NodeJS.LTS" }
        "4"  = @{ name = "Python 3";             id = "Python.Python.3" }
        "5"  = @{ name = "Windows Terminal";     id = "Microsoft.WindowsTerminal" }
        "6"  = @{ name = "PowerShell 7";         id = "Microsoft.PowerShell" }
        "7"  = @{ name = "JetBrains Toolbox";    id = "JetBrains.Toolbox" }
        "8"  = @{ name = "Notepad++";            id = "Notepad++.Notepad++" }
        "9"  = @{ name = "GitHub Desktop";       id = "GitHub.GitHubDesktop" }
        "10" = @{ name = "Docker Desktop";       id = "Docker.DockerDesktop" }
        "11" = @{ name = "Postman";              id = "Postman.Postman" }
        "12" = @{ name = "HeidiSQL";             id = "HeidiSQL.HeidiSQL" }
    }

    "Utilities" = [ordered]@{
        "1"  = @{ name = "7-Zip";                id = "7zip.7zip" }
        "2"  = @{ name = "WinRAR";               id = "RARLab.WinRAR" }
        "3"  = @{ name = "Everything (Search)";  id = "voidtools.Everything" }
        "4"  = @{ name = "PowerToys";            id = "Microsoft.PowerToys" }
        "5"  = @{ name = "TreeSize Free";        id = "JAMSoftware.TreeSize.Free" }
        "6"  = @{ name = "WizTree";              id = "AntibodySoftware.WizTree" }
        "7"  = @{ name = "CPU-Z";                id = "CPUID.CPU-Z" }
        "8"  = @{ name = "GPU-Z";                id = "TechPowerUp.GPU-Z" }
        "9"  = @{ name = "CrystalDiskInfo";      id = "CrystalDewWorld.CrystalDiskInfo" }
        "10" = @{ name = "Bulk Rename Utility";  id = "BulkRenameUtility.BulkRenameUtility" }
    }

    "Security" = [ordered]@{
        "1"  = @{ name = "Malwarebytes";         id = "Malwarebytes.Malwarebytes" }
        "2"  = @{ name = "Bitwarden";            id = "Bitwarden.Bitwarden" }
        "3"  = @{ name = "KeePassXC";            id = "KeePassXCTeam.KeePassXC" }
        "4"  = @{ name = "VeraCrypt";            id = "IDRIX.VeraCrypt" }
        "5"  = @{ name = "ProtonVPN";            id = "ProtonTechnologies.ProtonVPN" }
        "6"  = @{ name = "RogueKiller";          id = "Adlice.RogueKiller" }
        "7"  = @{ name = "Wireshark";            id = "WiresharkFoundation.Wireshark" }
        "8"  = @{ name = "SUMo (Update Check)";  id = "KC-Softwares.SUMo" }
    }

    "Office & Productivity" = [ordered]@{
        "1"  = @{ name = "LibreOffice";          id = "TheDocumentFoundation.LibreOffice" }
        "2"  = @{ name = "Obsidian";             id = "Obsidian.Obsidian" }
        "3"  = @{ name = "Notion";               id = "Notion.Notion" }
        "4"  = @{ name = "Thunderbird";          id = "Mozilla.Thunderbird" }
        "5"  = @{ name = "SumatraPDF";           id = "SumatraPDF.SumatraPDF" }
        "6"  = @{ name = "Okular (PDF)";         id = "KDE.Okular" }
        "7"  = @{ name = "ShareX (Screenshot)";  id = "ShareX.ShareX" }
        "8"  = @{ name = "AutoHotkey";           id = "AutoHotkey.AutoHotkey" }
    }

    "Image & Design" = [ordered]@{
        "1"  = @{ name = "GIMP";                 id = "GIMP.GIMP" }
        "2"  = @{ name = "Inkscape";             id = "Inkscape.Inkscape" }
        "3"  = @{ name = "Krita";                id = "KDE.Krita" }
        "4"  = @{ name = "Blender";              id = "BlenderFoundation.Blender" }
        "5"  = @{ name = "IrfanView";            id = "IrfanSkiljan.IrfanView" }
        "6"  = @{ name = "paint.net";            id = "dotPDN.PaintDotNet" }
        "7"  = @{ name = "Figma";                id = "Figma.Figma" }
        "8"  = @{ name = "XnViewMP";             id = "XnSoft.XnViewMP" }
    }

    "System & Tweaks" = [ordered]@{
        "1"  = @{ name = "Process Hacker 3";     id = "winsiderss.systeminformer.preview" }
        "2"  = @{ name = "Autoruns";             id = "Microsoft.Sysinternals.Autoruns" }
        "3"  = @{ name = "Process Monitor";      id = "Microsoft.Sysinternals.ProcessMonitor" }
        "4"  = @{ name = "NirSoft's NirLauncher"; id = "NirSoft.NirLauncher" }
        "5"  = @{ name = "HWMonitor";            id = "CPUID.HWMonitor" }
        "6"  = @{ name = "O&O ShutUp10++";       id = "OO-Software.ShutUp10" }
        "7"  = @{ name = "Bulk Crap Uninstaller"; id = "Klocman.BulkCrapUninstaller" }
        "8"  = @{ name = "Speccy";               id = "Piriform.Speccy" }
    }

    "Network & Remote" = [ordered]@{
        "1"  = @{ name = "WireGuard";            id = "WireGuard.WireGuard" }
        "2"  = @{ name = "PuTTY";                id = "PuTTY.PuTTY" }
        "3"  = @{ name = "WinSCP";               id = "WinSCP.WinSCP" }
        "4"  = @{ name = "FileZilla";            id = "TimKosse.FileZilla.Client" }
        "5"  = @{ name = "nmap";                 id = "Insecure.Nmap" }
        "6"  = @{ name = "Angry IP Scanner";     id = "angryziber.AngryIPScanner" }
        "7"  = @{ name = "mRemoteNG";            id = "mRemoteNG.mRemoteNG" }
        "8"  = @{ name = "RustDesk";             id = "RustDesk.RustDesk" }
    }

    "Drivers & Hardware" = [ordered]@{
        "1"  = @{ name = "DDU (Display Driver Uninstaller)"; id = "Wagnardsoft.DisplayDriverUninstaller" }
        "2"  = @{ name = "NVCleanstall (NVIDIA)"; id = "TechPowerUp.NVCleanstall" }
        "3"  = @{ name = "AMD Cleanup Utility";  id = "AMD.CleanupUtility" }
        "4"  = @{ name = "LatencyMon";           id = "ResPlat.LatencyMon" }
        "5"  = @{ name = "CrystalDiskMark";      id = "CrystalDewWorld.CrystalDiskMark" }
        "6"  = @{ name = "FurMark";              id = "Geeks3D.FurMark" }
        "7"  = @{ name = "Prime95";              id = "Prime95.Prime95" }
        "8"  = @{ name = "MemTest86";            id = "PassMark.MemTest86" }
    }
}

# ── Winget check ──────────────────────────────────────────────────────────────
function Test-Winget {
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

function Install-Winget {
    Show-Logo
    Header "INSTALLING WINGET"
    Step "winget not found. Installing via App Installer package..."
    try {
        $url  = "https://aka.ms/getwinget"
        $dest = "$env:TEMP\AppInstaller.msixbundle"
        Step "Downloading App Installer..."
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Step "Installing..."
        Add-AppxPackage -Path $dest -ErrorAction Stop
        Done "winget installed! Please restart the tool."
    } catch {
        Fail "Auto-install failed. Please install 'App Installer' from the Microsoft Store."
        Info "Store link: ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    }
    Pause-Continue
}

function Ensure-Winget {
    if (Test-Winget) { return $true }
    Warn "winget is not installed on this system."
    Write-Color ""
    Write-Color "  ${PURPLE}[1]${RESET}  ${WHITE}Auto-install winget now${RESET}"
    Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Cancel and go back${RESET}"
    $c = Read-MenuChoice "Install winget"
    if ($c -eq "1") { Install-Winget }
    return (Test-Winget)
}

# ── Single app install ────────────────────────────────────────────────────────
function Install-App {
    param([string]$WingetId, [string]$DisplayName)
    Step "Installing: ${WHITE}$DisplayName${RESET}  ${DGRAY}($WingetId)${RESET}"
    try {
        $proc = Start-Process -FilePath "winget" `
            -ArgumentList "install --id `"$WingetId`" --accept-source-agreements --accept-package-agreements --silent --no-upgrade" `
            -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        if ($proc.ExitCode -eq 0) {
            Done "$DisplayName installed successfully."
        } elseif ($proc.ExitCode -eq -1978335212) {
            Info "$DisplayName is already installed. (skipped)"
        } else {
            Warn "$DisplayName finished with exit code $($proc.ExitCode) — check manually."
        }
    } catch {
        Fail "Failed to launch winget for ${DisplayName}: $_"
    }
}

# ── Installer menu ────────────────────────────────────────────────────────────
function Invoke-Installer {
    while ($true) {
        Show-Logo
        Header "APP INSTALLER  (winget powered — 100+ apps)"

        $isWinget = Test-Winget
        if (-not $isWinget) {
            Warn "winget is NOT installed. Select option [W] to install it."
        } else {
            Done "winget is available and ready."
        }
        Write-Color ""

        $cats = @($AppCategories.Keys)
        for ($i = 0; $i -lt $cats.Count; $i++) {
            $pad   = "  [$($i+1)]".PadRight(9)
            $count = $AppCategories[$cats[$i]].Count
            Write-Color "  ${PURPLE}$pad${RESET}  ${WHITE}$($cats[$i])${RESET}  ${DGRAY}($count apps)${RESET}"
        }

        Write-Color ""
        Divider "-" 78 $DPURPLE
        Write-Color "  ${YELLOW}  [A]${RESET}  ${YELLOW}Install a CUSTOM app by winget ID${RESET}"
        if (-not $isWinget) {
            Write-Color "  ${CYAN}  [W]${RESET}  ${CYAN}Install winget (App Installer)${RESET}"
        }
        Write-Color "  ${PURPLE}  [0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select category [0-$($cats.Count)]"

        if ($c -eq "0") { return }
        if ($c -in @("W","w")) { Install-Winget; continue }
        if ($c -in @("A","a")) {
            if (-not (Ensure-Winget)) { continue }
            Write-Color "  ${LPURPLE}Enter winget package ID: ${RESET}" -NoNewLine
            $customId = Read-Host
            if ($customId) {
                Write-Color "  ${LPURPLE}Display name (optional): ${RESET}" -NoNewLine
                $customName = Read-Host
                if (-not $customName) { $customName = $customId }
                Write-Color ""
                Install-App $customId $customName
                Pause-Continue
            }
            continue
        }

        $idx = [int]$c - 1
        if ($idx -lt 0 -or $idx -ge $cats.Count) { Warn "Invalid option."; Start-Sleep 1; continue }
        Show-AppCategory $cats[$idx]
    }
}

function Show-AppCategory($catName) {
    while ($true) {
        Show-Logo
        Header "INSTALL  —  $($catName.ToUpper())"
        $apps = $AppCategories[$catName]
        foreach ($k in $apps.Keys) {
            $pad = "  [$k]".PadRight(9)
            Write-Color "  ${PURPLE}$pad${RESET}  ${WHITE}$($apps[$k].name)${RESET}  ${DGRAY}($($apps[$k].id))${RESET}"
        }
        Write-Color ""
        Divider "-" 78 $DPURPLE
        Write-Color "  ${YELLOW}  [A]${RESET}  ${YELLOW}Install ALL apps in this category${RESET}"
        Write-Color "  ${PURPLE}  [0]${RESET}  ${GRAY}Back to Category List${RESET}"

        $c = Read-MenuChoice "Select app"
        if ($c -eq "0") { return }
        if (-not (Ensure-Winget)) { Pause-Continue; return }

        if ($c -in @("A","a")) {
            Write-Color ""
            Warn "Installing ALL apps in '$catName'..."
            Write-Color ""
            foreach ($k in $apps.Keys) { Install-App $apps[$k].id $apps[$k].name }
        } elseif ($apps.ContainsKey($c)) {
            Write-Color ""
            Install-App $apps[$c].id $apps[$c].name
        } else {
            Warn "Invalid option."; Start-Sleep 1; continue
        }
        Pause-Continue
    }
}
