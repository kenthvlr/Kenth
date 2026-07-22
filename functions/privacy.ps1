# ==============================================================================
#  privacy.ps1  —  Privacy engine (built-in ShutUp10++ equivalent)
# ==============================================================================

function Invoke-PrivacyEngine {
    while ($true) {
        Show-Logo
        Header "PRIVACY ENGINE  (Built-in ShutUp10++ Equivalent)"
        Write-Color "  ${GRAY}Granular privacy hardening — inspired by O&O ShutUp10++${RESET}"
        Write-Color ""

        $opts = [ordered]@{
            "1"  = "Telemetry & Diagnostics          (DiagTrack, data collection)"
            "2"  = "Location & Sensors               (GPS, location, sensor tracking)"
            "3"  = "Advertising & Personalization    (Ad ID, tailored experiences)"
            "4"  = "Activity History & Timeline      (cloud sync, app tracking)"
            "5"  = "App Permissions                  (camera, mic, contacts, calendar)"
            "6"  = "Search & Cortana Privacy         (Bing, web search, speech)"
            "7"  = "Microsoft Account & Cloud        (sync, OneDrive cloud settings)"
            "8"  = "SmartScreen & Security Privacy   (SmartScreen, phishing filter)"
            "9"  = "Error Reporting & Feedback       (WER, feedback frequency)"
            "10" = "Clipboard & Sync                 (clipboard history, cloud sync)"
            "11" = "Network Privacy                  (WiFi Sense, NCSI, LLMNR)"
            "12" = "Edge & Browser Privacy           (Edge telemetry, pre-launch)"
            "13" = "Windows Features Privacy         (tips, spotlight, widget ads)"
            "14" = "Defender Telemetry               (MAPS reporting, samples)"
            "15" = "User Account Control (UAC)       (UAC level selector)"
            "16" = "App Diagnostics & Feedback       (per-app data access)"
            "A"  = "APPLY ALL PRIVACY TWEAKS         (Full ShutUp10++ Mode)"
            "U"  = "UNDO — Restore Windows Defaults"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(8)
            $col = switch ($k) { "A" { $YELLOW } "U" { $RED } default { $PURPLE } }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select privacy category"
        switch ($c) {
            "1"  { Set-Telemetry }
            "2"  { Set-LocationPrivacy }
            "3"  { Set-AdvertisingPrivacy }
            "4"  { Set-ActivityHistory }
            "5"  { Set-AppPermissions }
            "6"  { Set-SearchPrivacy }
            "7"  { Set-CloudPrivacy }
            "8"  { Set-SmartScreenPrivacy }
            "9"  { Set-ErrorReporting }
            "10" { Set-ClipboardPrivacy }
            "11" { Set-NetworkPrivacy }
            "12" { Set-BrowserPrivacy }
            "13" { Set-WindowsFeaturePrivacy }
            "14" { Set-DefenderTelemetry }
            "15" { Set-UACLevel }
            "16" { Set-AppDiagnostics }
            { $_ -in "A","a" } {
                Show-Logo; Header "APPLYING ALL PRIVACY TWEAKS"
                Step "Running full privacy engine..."
                Set-Telemetry; Set-LocationPrivacy; Set-AdvertisingPrivacy
                Set-ActivityHistory; Set-AppPermissions; Set-SearchPrivacy
                Set-CloudPrivacy; Set-SmartScreenPrivacy; Set-ErrorReporting
                Set-ClipboardPrivacy; Set-NetworkPrivacy; Set-BrowserPrivacy
                Set-WindowsFeaturePrivacy; Set-DefenderTelemetry; Set-AppDiagnostics
                Done "All 15 privacy categories applied!"
                Pause-Continue
            }
            { $_ -in "U","u" } {
                Show-Logo; Header "RESTORE WINDOWS PRIVACY DEFAULTS"
                Warn "Restoring some telemetry/privacy settings to Windows defaults..."
                Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" DWord 1
                Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" DWord 1
                Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" DWord 1
                Done "Core defaults restored. Some tweaks require a Windows reset to fully undo."
                Pause-Continue
            }
            "0" { return }
        }
    }
}

function Set-Telemetry {
    Show-Logo; Header "TELEMETRY & DIAGNOSTICS"
    Step "Setting telemetry to Security (minimal) level..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DisableEnterpriseAuthProxy" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" DWord 0
    Step "Stopping DiagTrack service..."
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service  DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Step "Stopping dmwappushservice..."
    Stop-Service dmwappushservice -Force -ErrorAction SilentlyContinue
    Set-Service  dmwappushservice -StartupType Disabled -ErrorAction SilentlyContinue
    Step "Disabling Customer Experience Improvement..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\SQMClient\Windows" "CEIPEnable" DWord 0
    Done "Telemetry & diagnostics disabled."
    Pause-Continue
}

function Set-LocationPrivacy {
    Show-Logo; Header "LOCATION & SENSORS"
    Step "Disabling location access..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocationScripting" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableSensors" DWord 1
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" "Value" String "Deny"
    Done "Location & sensors disabled."
    Pause-Continue
}

function Set-AdvertisingPrivacy {
    Show-Logo; Header "ADVERTISING & PERSONALIZATION"
    Step "Disabling Advertising ID..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" DWord 1
    Step "Disabling tailored experiences..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" DWord 0
    Done "Advertising ID and personalization disabled."
    Pause-Continue
}

function Set-ActivityHistory {
    Show-Logo; Header "ACTIVITY HISTORY & TIMELINE"
    Step "Disabling activity history and cloud sync..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" DWord 0
    Done "Activity history / timeline disabled."
    Pause-Continue
}

function Set-AppPermissions {
    Show-Logo; Header "APP PERMISSIONS"
    $perms = @("microphone","camera","contacts","calendar","messaging","radios","bluetoothSync","appDiagnostics","userAccountInformation")
    foreach ($p in $perms) {
        Step "Restricting: $p"
        Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\$p" "Value" String "Deny"
        $capPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$p"
        Set-RegValue $capPath "Value" String "Deny"
    }
    Done "App permissions restricted."
    Pause-Continue
}

function Set-SearchPrivacy {
    Show-Logo; Header "SEARCH & CORTANA PRIVACY"
    Step "Disabling Bing integration in Windows Search..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" DWord 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" DWord 0
    Step "Disabling speech data collection..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" DWord 0
    Done "Search & Cortana privacy applied."
    Pause-Continue
}

function Set-CloudPrivacy {
    Show-Logo; Header "MICROSOFT ACCOUNT & CLOUD"
    Step "Disabling sync settings to cloud..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" "DisableSettingSync" DWord 2
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" "DisableSettingSyncUserOverride" DWord 1
    Step "Disabling OneDrive auto-start..."
    Remove-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OneDrive" -ErrorAction SilentlyContinue
    Done "Cloud account privacy applied."
    Pause-Continue
}

function Set-SmartScreenPrivacy {
    Show-Logo; Header "SMARTSCREEN & SECURITY PRIVACY"
    Step "Disabling SmartScreen telemetry (keeping local protection)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" String "Off"
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter" "EnabledV9" DWord 0
    Done "SmartScreen telemetry tweaked."
    Pause-Continue
}

function Set-ErrorReporting {
    Show-Logo; Header "ERROR REPORTING & FEEDBACK"
    Step "Disabling Windows Error Reporting (WER)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" DWord 1
    Stop-Service WerSvc -Force -ErrorAction SilentlyContinue
    Set-Service  WerSvc -StartupType Disabled -ErrorAction SilentlyContinue
    Step "Setting feedback frequency to Never..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" DWord 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" DWord 0
    Done "Error reporting & feedback disabled."
    Pause-Continue
}

function Set-ClipboardPrivacy {
    Show-Logo; Header "CLIPBOARD & SYNC"
    Step "Disabling clipboard history and cloud sync..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "AllowClipboardHistory" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "AllowCrossDeviceClipboard" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" DWord 0
    Done "Clipboard history and sync disabled."
    Pause-Continue
}

function Set-NetworkPrivacy {
    Show-Logo; Header "NETWORK PRIVACY"
    Step "Disabling WiFi Sense (auto-share WiFi)..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" "value" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" "value" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" DWord 0
    Step "Disabling NCSI connectivity check (no MS pings)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" "NoActiveProbe" DWord 1
    Step "Disabling LLMNR (link-local multicast name resolution)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" "EnableMulticast" DWord 0
    Done "Network privacy applied."
    Pause-Continue
}

function Set-BrowserPrivacy {
    Show-Logo; Header "EDGE & BROWSER PRIVACY"
    Step "Disabling Edge telemetry and pre-launch..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" "AllowPrelaunch" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "MetricsReportingEnabled" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "SendSiteInfoToImproveServices" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "DiagnosticData" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "PersonalizationReportingEnabled" DWord 0
    Done "Browser privacy improved."
    Pause-Continue
}

function Set-WindowsFeaturePrivacy {
    Show-Logo; Header "WINDOWS FEATURES PRIVACY"
    Step "Disabling tips, spotlight ads, start menu suggestions..."
    $cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-RegValue $cdm "SubscribedContent-338388Enabled" DWord 0
    Set-RegValue $cdm "SubscribedContent-353698Enabled" DWord 0
    Set-RegValue $cdm "SubscribedContent-338393Enabled" DWord 0
    Set-RegValue $cdm "SystemPaneSuggestionsEnabled" DWord 0
    Set-RegValue $cdm "SoftLandingEnabled" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" DWord 0
    Done "Windows feature ads/suggestions disabled."
    Pause-Continue
}

function Set-DefenderTelemetry {
    Show-Logo; Header "DEFENDER TELEMETRY"
    Step "Disabling MAPS cloud reporting and sample submission..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SpynetReporting" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SubmitSamplesConsent" DWord 2
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\MRT" "DontReportInfectionInformation" DWord 1
    Done "Defender telemetry minimized."
    Pause-Continue
}

function Set-AppDiagnostics {
    Show-Logo; Header "APP DIAGNOSTICS & FEEDBACK"
    Step "Restricting app diagnostics access..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" "Value" String "Deny"
    Step "Disabling app launch tracking..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" DWord 0
    Done "App diagnostics restricted."
    Pause-Continue
}

function Set-UACLevel {
    Show-Logo; Header "USER ACCOUNT CONTROL (UAC)"
    Write-Color "  ${WHITE}Current UAC options:${RESET}"
    Write-Color "  ${PURPLE}[1]${RESET}  ${WHITE}High   — Notify for ALL changes (most secure)${RESET}"
    Write-Color "  ${PURPLE}[2]${RESET}  ${WHITE}Medium — Notify only for app changes (Windows default)${RESET}"
    Write-Color "  ${PURPLE}[3]${RESET}  ${WHITE}Low    — App changes, no secure desktop dimming${RESET}"
    Write-Color "  ${RED}[4]${RESET}  ${RED}Off    — Disable UAC completely (NOT recommended)${RESET}"
    Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back${RESET}"
    $c = Read-MenuChoice "Select UAC level"
    switch ($c) {
        "1" {
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" DWord 2
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" DWord 1
            Done "UAC set to High."
        }
        "2" {
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" DWord 5
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" DWord 1
            Done "UAC set to Medium (default)."
        }
        "3" {
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" DWord 5
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" DWord 0
            Done "UAC set to Low."
        }
        "4" {
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" DWord 0
            Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" DWord 0
            Warn "UAC has been DISABLED. Not recommended for daily use."
        }
    }
    Pause-Continue
}
