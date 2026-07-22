# ==============================================================================
#  edge.ps1  —  Microsoft Edge removal and privacy tweaks
# ==============================================================================

function Invoke-EdgeMenu {
    while ($true) {
        Show-Logo
        Header "MICROSOFT EDGE"

        $opts = [ordered]@{
            "1" = "Privacy-harden Edge              (disable telemetry, pre-launch, tracking)"
            "2" = "Block Edge Auto-updates           (prevent forced reinstall)"
            "3" = "Remove Edge from Startup          (stop Edge auto-launch on boot)"
            "4" = "Attempt Edge Removal              (experimental — may be re-installed by Windows Update)"
            "5" = "Disable Edge background service   (EdgeUpdate, MicrosoftEdgeElevation)"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "4") { $RED } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select Edge action"
        switch ($c) {
            "1" { Invoke-EdgePrivacy }
            "2" { Invoke-BlockEdgeUpdate }
            "3" { Invoke-RemoveEdgeStartup }
            "4" { Invoke-RemoveEdge }
            "5" { Invoke-DisableEdgeServices }
            "0" { return }
        }
    }
}

function Invoke-EdgePrivacy {
    Show-Logo; Header "PRIVACY-HARDEN EDGE"
    Step "Disabling Edge telemetry reporting..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "MetricsReportingEnabled" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "SendSiteInfoToImproveServices" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "DiagnosticData" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "PersonalizationReportingEnabled" DWord 0
    Step "Disabling Edge pre-launch (loads Edge on Windows startup)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" "AllowPrelaunch" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" DWord 0
    Step "Disabling Edge background extensions when closed..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" DWord 0
    Step "Disabling tracking protection override..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "TrackingPrevention" DWord 3
    Done "Edge privacy settings applied."
    Pause-Continue
}

function Invoke-BlockEdgeUpdate {
    Show-Logo; Header "BLOCK EDGE AUTO-UPDATES"
    Step "Blocking Edge from updating via policy..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" "UpdateDefault" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" "DoNotUpdateToEdgeWithChromium" DWord 1
    Done "Edge auto-update blocked."
    Pause-Continue
}

function Invoke-RemoveEdgeStartup {
    Show-Logo; Header "REMOVE EDGE FROM STARTUP"
    Step "Removing Edge auto-launch from startup..."
    Remove-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "MicrosoftEdgeAutoLaunch*" -ErrorAction SilentlyContinue
    Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "MicrosoftEdgeAutoLaunch*" -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskPath "\MicrosoftEdgeUpdateTaskMachine*" -ErrorAction SilentlyContinue |
        Disable-ScheduledTask -ErrorAction SilentlyContinue
    Done "Edge startup entries removed."
    Pause-Continue
}

function Invoke-RemoveEdge {
    Show-Logo; Header "ATTEMPT EDGE REMOVAL"
    Warn "Edge is protected by Windows. It may be re-installed by Windows Update."
    Warn "For full removal, use DDU or a dedicated Edge removal tool."
    Write-Color ""
    Write-Color "  ${PURPLE}[Y]${RESET}  ${WHITE}Attempt removal anyway${RESET}"
    Write-Color "  ${PURPLE}[N]${RESET}  ${GRAY}Cancel${RESET}"
    $confirm = Read-MenuChoice "Confirm"
    if ($confirm -notmatch '^[Yy]') { Info "Cancelled."; Pause-Continue; return }

    Step "Stopping Edge processes..."
    Get-Process -Name "msedge","MicrosoftEdgeUpdate" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Step "Attempting AppX removal..."
    Remove-AppxSilent "MicrosoftEdge"
    Remove-AppxSilent "Microsoft.MicrosoftEdge"
    Remove-AppxSilent "Microsoft.MicrosoftEdgeDevToolsClient"
    Step "Blocking reinstallation..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" "UpdateDefault" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" "DoNotUpdateToEdgeWithChromium" DWord 1
    Done "Edge removal attempted. Restart your PC to complete."
    Pause-Continue
}

function Invoke-DisableEdgeServices {
    Show-Logo; Header "DISABLE EDGE BACKGROUND SERVICES"
    $edgeSvcs = @("edgeupdate","edgeupdatem","MicrosoftEdgeElevationService")
    foreach ($svc in $edgeSvcs) {
        Step "Disabling: $svc"
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service  $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Done "Edge background services disabled."
    Pause-Continue
}
