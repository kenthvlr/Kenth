# ==============================================================================
#  services.ps1  —  Manage Windows services (disable junk, tweak startup)
# ==============================================================================

$KenthDisableList = @(
    @{ name = "DiagTrack";              desc = "Connected User Experiences / Telemetry" }
    @{ name = "dmwappushservice";       desc = "WAP Push Message Routing Service" }
    @{ name = "MapsBroker";             desc = "Downloaded Maps Manager" }
    @{ name = "lfsvc";                  desc = "Geolocation Service" }
    @{ name = "SharedAccess";           desc = "Internet Connection Sharing (ICS)" }
    @{ name = "RetailDemo";             desc = "Retail Demo Service" }
    @{ name = "RemoteRegistry";         desc = "Remote Registry (security risk)" }
    @{ name = "XblAuthManager";         desc = "Xbox Live Auth Manager" }
    @{ name = "XblGameSave";            desc = "Xbox Live Game Save" }
    @{ name = "XboxNetApiSvc";          desc = "Xbox Live Networking" }
    @{ name = "XboxGipSvc";             desc = "Xbox Accessory Management Service" }
    @{ name = "WerSvc";                 desc = "Windows Error Reporting" }
    @{ name = "WMPNetworkSvc";          desc = "Windows Media Player Sharing" }
    @{ name = "icssvc";                 desc = "Windows Mobile Hotspot Service" }
    @{ name = "Fax";                    desc = "Fax Service" }
    @{ name = "SmsRouter";              desc = "Microsoft Windows SMS Router" }
    @{ name = "edgeupdate";             desc = "Microsoft Edge Update" }
    @{ name = "edgeupdatem";            desc = "Microsoft Edge Update (bg)" }
    @{ name = "MicrosoftEdgeElevationService"; desc = "Edge Elevation Service" }
    @{ name = "NcbService";             desc = "Network Connection Broker" }
    @{ name = "PcaSvc";                 desc = "Program Compatibility Assistant" }
    @{ name = "SysMain";                desc = "Superfetch / SysMain (SSD only)" }
    @{ name = "TabletInputService";     desc = "Touch Keyboard / Tablet Input" }
    @{ name = "TermService";            desc = "Remote Desktop Services" }
)

function Invoke-ServicesMenu {
    while ($true) {
        Show-Logo
        Header "SERVICES MANAGER"

        $opts = [ordered]@{
            "1" = "Disable ALL recommended junk services    ($($KenthDisableList.Count) services)"
            "2" = "View status of recommended services     (check what is running)"
            "3" = "Stop a service manually                 (type service name)"
            "4" = "Disable a service manually              (type service name)"
            "5" = "Enable / Restore a service              (type service name)"
            "6" = "Search services by keyword              (find by display name)"
            "7" = "List ALL running services               (full live list)"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "1") { $YELLOW } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select service action"
        switch ($c) {
            "1" { Invoke-DisableServices }
            "2" { Show-ServiceStatus }
            "3" {
                Write-Color "  ${LPURPLE}Service name to STOP: ${RESET}" -NoNewLine
                $sn = Read-Host
                if ($sn) {
                    Stop-Service -Name $sn -Force -ErrorAction SilentlyContinue
                    Done "$sn stopped."
                }
                Pause-Continue
            }
            "4" {
                Write-Color "  ${LPURPLE}Service name to DISABLE: ${RESET}" -NoNewLine
                $sn = Read-Host
                if ($sn) {
                    Stop-Service  -Name $sn -Force -ErrorAction SilentlyContinue
                    Set-Service   -Name $sn -StartupType Disabled -ErrorAction SilentlyContinue
                    Done "$sn disabled."
                }
                Pause-Continue
            }
            "5" {
                Write-Color "  ${LPURPLE}Service name to ENABLE: ${RESET}" -NoNewLine
                $sn = Read-Host
                if ($sn) {
                    Set-Service   -Name $sn -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name $sn -ErrorAction SilentlyContinue
                    Done "$sn enabled and started."
                }
                Pause-Continue
            }
            "6" {
                Write-Color "  ${LPURPLE}Search term: ${RESET}" -NoNewLine
                $term = Read-Host
                if ($term) {
                    Write-Color ""
                    Get-Service | Where-Object { $_.DisplayName -like "*$term*" -or $_.Name -like "*$term*" } |
                        ForEach-Object {
                            $col = if ($_.Status -eq "Running") { $GREEN } else { $RED }
                            Write-Color "  ${WHITE}$($_.Name.PadRight(35))${col}$($_.Status.PadRight(12))${RESET}${GRAY}$($_.DisplayName)${RESET}"
                        }
                    Write-Color ""
                }
                Pause-Continue
            }
            "7" {
                Write-Color ""
                Get-Service | Where-Object { $_.Status -eq "Running" } | Sort-Object Name |
                    ForEach-Object {
                        Write-Color "  ${GREEN}[RUN]${RESET}  ${WHITE}$($_.Name.PadRight(35))${RESET}${GRAY}$($_.DisplayName)${RESET}"
                    }
                Write-Color ""
                Pause-Continue
            }
            "0" { return }
        }
    }
}

function Invoke-DisableServices {
    Show-Logo
    Header "DISABLE RECOMMENDED JUNK SERVICES"
    Warn "Stopping and disabling $($KenthDisableList.Count) unnecessary services..."
    Write-Color ""
    $ok = 0; $skip = 0
    foreach ($svc in $KenthDisableList) {
        $exists = Get-Service -Name $svc.name -ErrorAction SilentlyContinue
        if ($exists) {
            Stop-Service -Name $svc.name -Force -ErrorAction SilentlyContinue
            Set-Service  -Name $svc.name -StartupType Disabled -ErrorAction SilentlyContinue
            Step "Disabled: $($svc.name.PadRight(30)) ${DGRAY}$($svc.desc)${RESET}"
            $ok++
        } else {
            Info "Not found: $($svc.name.PadRight(30)) ${DGRAY}(not installed — skipped)${RESET}"
            $skip++
        }
    }
    Write-Color ""
    Done "$ok services disabled, $skip skipped (not installed)."
    Pause-Continue
}

function Show-ServiceStatus {
    Show-Logo
    Header "RECOMMENDED SERVICES STATUS"
    foreach ($svc in $KenthDisableList) {
        $s = Get-Service -Name $svc.name -ErrorAction SilentlyContinue
        if ($s) {
            $col = if ($s.Status -eq "Running") { $RED } else { $GREEN }
            $status = $s.Status.ToString().PadRight(10)
            $start  = $s.StartType.ToString().PadRight(12)
            Write-Color "  ${col}[$status]${RESET}  ${WHITE}$($svc.name.PadRight(30))${RESET}${GRAY}$($svc.desc)${RESET}"
        } else {
            Write-Color "  ${DGRAY}[NOT FOUND]${RESET}  ${DGRAY}$($svc.name.PadRight(30))${RESET}${DGRAY}(not installed)${RESET}"
        }
    }
    Write-Color ""
    Pause-Continue
}
