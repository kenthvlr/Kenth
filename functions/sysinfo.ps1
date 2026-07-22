# ==============================================================================
#  sysinfo.ps1  —  System information overview
# ==============================================================================

function Show-SystemInfo {
    Show-Logo
    Header "SYSTEM INFORMATION"

    try {
        $cs    = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
        $os    = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop
        $cpu   = Get-WmiObject Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
        $gpu   = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $bios  = Get-WmiObject Win32_BIOS -ErrorAction SilentlyContinue
        $net   = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue | Select-Object -First 1

        $ramGB  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedGB = [math]::Round($ramGB - $freeGB, 2)

        $osName  = $os.Caption
        $osBuild = $os.Version
        $osArch  = $os.OSArchitecture
        $uptime  = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
        $uptimeStr = "$([int]$uptime.TotalDays)d $($uptime.Hours)h $($uptime.Minutes)m"

        $isAdmin = Test-IsAdmin
        $adminStr = if ($isAdmin) { "${GREEN}YES (Admin)${RESET}" } else { "${RED}NO (Limited)${RESET}" }

        $isWinget = Test-Winget
        $wingetStr = if ($isWinget) { "${GREEN}Available${RESET}" } else { "${RED}Not installed${RESET}" }

        Write-Color "  ${LPURPLE}SYSTEM${RESET}"
        Divider "-" 78 $DPURPLE
        Write-Color "  ${CYAN}Hostname     ${RESET}  ${WHITE}$($env:COMPUTERNAME)${RESET}"
        Write-Color "  ${CYAN}OS           ${RESET}  ${WHITE}$osName  ($osBuild  $osArch)${RESET}"
        Write-Color "  ${CYAN}Uptime       ${RESET}  ${WHITE}$uptimeStr${RESET}"
        Write-Color "  ${CYAN}Admin        ${RESET}  $adminStr"
        Write-Color "  ${CYAN}winget       ${RESET}  $wingetStr"
        Write-Color ""

        Write-Color "  ${LPURPLE}HARDWARE${RESET}"
        Divider "-" 78 $DPURPLE
        Write-Color "  ${CYAN}CPU          ${RESET}  ${WHITE}$($cpu.Name.Trim())${RESET}"
        Write-Color "  ${CYAN}Cores/Threads${RESET}  ${WHITE}$($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads${RESET}"
        Write-Color "  ${CYAN}CPU Speed    ${RESET}  ${WHITE}$($cpu.MaxClockSpeed) MHz${RESET}"
        Write-Color "  ${CYAN}RAM Total    ${RESET}  ${WHITE}$ramGB GB${RESET}"
        Write-Color "  ${CYAN}RAM Used     ${RESET}  ${WHITE}$usedGB GB  (${YELLOW}$([math]::Round($usedGB/$ramGB*100))% used${RESET})"
        Write-Color "  ${CYAN}RAM Free     ${RESET}  ${WHITE}$freeGB GB${RESET}"
        if ($gpu) {
            Write-Color "  ${CYAN}GPU          ${RESET}  ${WHITE}$($gpu.Name)${RESET}"
            $vramMB = [math]::Round($gpu.AdapterRAM / 1MB)
            if ($vramMB -gt 0) {
                Write-Color "  ${CYAN}VRAM         ${RESET}  ${WHITE}$vramMB MB${RESET}"
            }
        }
        if ($bios) {
            Write-Color "  ${CYAN}BIOS         ${RESET}  ${WHITE}$($bios.Manufacturer) v$($bios.SMBIOSBIOSVersion)${RESET}"
        }
        Write-Color ""

        Write-Color "  ${LPURPLE}STORAGE${RESET}"
        Divider "-" 78 $DPURPLE
        foreach ($d in $disks) {
            $totalGB = [math]::Round($d.Size / 1GB, 1)
            $freeGBd = [math]::Round($d.FreeSpace / 1GB, 1)
            $usedGBd = [math]::Round(($d.Size - $d.FreeSpace) / 1GB, 1)
            $pct     = if ($d.Size -gt 0) { [math]::Round($usedGBd/$totalGB*100) } else { 0 }
            $bar     = "#" * [int]($pct / 5) + "." * (20 - [int]($pct / 5))
            $barCol  = if ($pct -gt 85) { $RED } elseif ($pct -gt 60) { $YELLOW } else { $GREEN }
            Write-Color "  ${CYAN}$($d.DeviceID.PadRight(5))${RESET}  ${WHITE}$($d.VolumeName.PadRight(16))${RESET}  ${barCol}[$bar]${RESET}  ${WHITE}$usedGBd / $totalGB GB${RESET}  ${GRAY}($pct%)${RESET}"
        }
        Write-Color ""

        if ($net) {
            Write-Color "  ${LPURPLE}NETWORK${RESET}"
            Divider "-" 78 $DPURPLE
            Write-Color "  ${CYAN}Adapter      ${RESET}  ${WHITE}$($net.Description)${RESET}"
            Write-Color "  ${CYAN}IP Address   ${RESET}  ${WHITE}$($net.IPAddress -join ', ')${RESET}"
            Write-Color "  ${CYAN}DNS Servers  ${RESET}  ${WHITE}$($net.DNSServerSearchOrder -join ', ')${RESET}"
            Write-Color ""
        }

    } catch {
        Fail "Could not retrieve system information: $_"
    }

    Pause-Continue
}
