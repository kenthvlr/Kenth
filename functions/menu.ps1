# ==============================================================================
#  menu.ps1  —  Main navigation menu (console / CLI mode)
# ==============================================================================

function Invoke-MainMenu {
    while ($true) {
        Show-Logo

        $isAdmin   = Test-IsAdmin
        $adminStr  = if ($isAdmin) { "${GREEN}ADMIN${RESET}" } else { "${RED}LIMITED (some tweaks won't work)${RESET}" }
        $wingetStr = if (Test-Winget) { "${GREEN}Ready${RESET}" } else { "${YELLOW}Not installed${RESET}" }

        Write-Color "  ${CYAN}Status:${RESET}  Admin: $adminStr   winget: $wingetStr"
        Write-Color ""
        Divider "=" 78 $PURPLE
        Write-Color ""

        $menu = [ordered]@{
            "1"  = "Install Apps             (winget powered — 100+ apps, 12 categories)"
            "2"  = "Windows Tweaks           (performance, UI, power, startup)"
            "3"  = "FPS & Gaming             (FPS boost, latency, GPU scheduling)"
            "4"  = "Privacy Engine           (ShutUp10++ built-in — 15 categories)"
            "5"  = "Remove Bloatware         (30 Windows UWP apps removable)"
            "6"  = "Cache Cleaner            (25+ junk/cache types)"
            "7"  = "Network Tweaks           (TCP stack, DNS, Nagle, QoS)"
            "8"  = "Services Manager         (disable/manage Windows services)"
            "9"  = "Hardware & Advanced      (NTFS, memory, power throttle)"
            "10" = "Edge — Remove/Tweak      (Edge removal and privacy hardening)"
            "11" = "OneDrive — Remove/Tweak  (OneDrive uninstall and disable)"
            "12" = "System Info              (CPU, RAM, GPU, storage, network)"
            "F"  = "FULL AUTO MODE           (everything at once — restart after)"
        }
        foreach ($k in $menu.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "F") { $YELLOW } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($menu[$k])${RESET}"
        }
        Write-Color ""
        Divider "-" 78 $DPURPLE
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Exit Kenth${RESET}"
        Write-Color ""

        $c = Read-MenuChoice "Main Menu [0-12 / F]"
        switch ($c) {
            "1"  { Invoke-Installer }
            "2"  { Invoke-WindowsTweaks }
            "3"  { Invoke-GamingMenu }
            "4"  { Invoke-PrivacyEngine }
            "5"  { Invoke-RemoveApps }
            "6"  { Invoke-ClearCache }
            "7"  { Invoke-NetworkMenu }
            "8"  { Invoke-ServicesMenu }
            "9"  { Invoke-HardwareMenu }
            "10" { Invoke-EdgeMenu }
            "11" { Invoke-OneDriveMenu }
            "12" { Show-SystemInfo }
            { $_ -in "F","f" } { Invoke-FullAuto }
            "0" {
                Write-Color ""
                Write-Color "  ${LPURPLE}Thanks for using Kenth! github.com/kenthvlr/Kenth${RESET}"
                Write-Color ""
                exit
            }
            default { Warn "Invalid option '$c' — press Enter to retry."; Start-Sleep 1 }
        }
    }
}

function Invoke-FullAuto {
    Show-Logo
    Header "FULL AUTO MODE — ALL 14 STEPS"
    Warn "This will apply ALL tweaks, privacy hardening, cache cleaning, and service disabling."
    Warn "A restart is REQUIRED after this completes for all changes to take effect."
    Write-Color ""
    Write-Color "  ${PURPLE}[Y]${RESET}  ${WHITE}Start Full Auto Mode${RESET}"
    Write-Color "  ${PURPLE}[N]${RESET}  ${GRAY}Cancel${RESET}"
    $confirm = Read-MenuChoice "Confirm"
    if ($confirm -notmatch '^[Yy]') { Info "Cancelled."; return }

    Show-Logo
    Header "RUNNING FULL AUTO MODE"
    Write-Color ""

    $steps = @(
        @{ label = "[ 1/14] Removing all bloatware..."              ; action = {
            foreach ($k in $DebloatAppList.Keys) {
                foreach ($pkg in $DebloatAppList[$k].pkgs) { Remove-AppxSilent $pkg }
            }
        }}
        @{ label = "[ 2/14] Clearing all cache types..."           ; action = {
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            ipconfig /flushdns | Out-Null
        }}
        @{ label = "[ 3/14] Full Privacy Engine..."                ; action = {
            Set-Telemetry; Set-LocationPrivacy; Set-AdvertisingPrivacy; Set-ActivityHistory
            Set-AppPermissions; Set-SearchPrivacy; Set-CloudPrivacy; Set-ErrorReporting
            Set-ClipboardPrivacy; Set-NetworkPrivacy; Set-WindowsFeaturePrivacy; Set-DefenderTelemetry
        }}
        @{ label = "[ 4/14] Performance tweaks..."                 ; action = {
            Invoke-PerfTweak; Invoke-NoAnimations; Invoke-FileExtensions
            Invoke-DisableStartupDelay; Invoke-LongFilePaths; Invoke-BestPerfVisuals
        }}
        @{ label = "[ 5/14] Taskbar & UI cleanup..."               ; action = {
            Invoke-TaskbarTweak; Invoke-LockScreenTweak; Invoke-NotifTweak
            Invoke-DisableAccessibilityKeys; Invoke-DisableTips
        }}
        @{ label = "[ 6/14] Remove Windows AI & Copilot..."        ; action = { Invoke-RemoveWinAI; Invoke-DisableCortana }}
        @{ label = "[ 7/14] FPS & latency tweaks..."               ; action = {
            Invoke-CPUUnpark; Invoke-TimerResolution; Invoke-DisableCPUThrottle
            Invoke-NetworkLatencyPack; Invoke-RawMouse; Invoke-ProcessPriorityBoost
        }}
        @{ label = "[ 8/14] Gaming optimizations..."               ; action = {
            Invoke-GameMode; Invoke-GameBarTweak; Invoke-GamePriority
            Invoke-HAGS; Invoke-FullscreenOpt; Invoke-DynamicTick
        }}
        @{ label = "[ 9/14] Network stack tuning..."               ; action = { Invoke-TCPTuning; Invoke-DisableNagle; Invoke-DisableQoS }}
        @{ label = "[10/14] Hardware & advanced tweaks..."          ; action = {
            Invoke-DisablePowerThrottle; Invoke-HAGS; Invoke-NTFSOptimize; Invoke-DisablePagingExec
        }}
        @{ label = "[11/14] Disable junk services..."              ; action = {
            foreach ($s in $KenthDisableList) {
                Stop-Service -Name $s.name -Force -ErrorAction SilentlyContinue
                Set-Service  -Name $s.name -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }}
        @{ label = "[12/14] Disable background apps & autoplay..." ; action = { Invoke-DisableBgApps; Invoke-DisableAutoPlay }}
        @{ label = "[13/14] Ultimate Performance power plan..."     ; action = { Invoke-UltimatePower }}
        @{ label = "[14/14] RAM & memory tweaks..."                 ; action = {
            Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" DWord 1
            Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" DWord 0
        }}
    )

    foreach ($s in $steps) {
        Write-Color "  ${LPURPLE}$($s.label)${RESET}"
        try { & $s.action } catch {}
    }

    Write-Color ""
    Divider "=" 78 $PURPLE
    Done "ALL 14 STEPS COMPLETE — github.com/kenthvlr/Kenth"
    Write-Color "  ${GRAY}Restart your PC for full effect.${RESET}"
    Divider "=" 78 $PURPLE
    Write-Color ""
    Write-Color "  ${YELLOW}Restart now? (Y/N): ${RESET}" -NoNewLine
    $r = Read-Host
    if ($r -match '^[Yy]') {
        shutdown /r /t 15 /c "Kenth PC Tweak Tool — Restarting to apply all changes..."
    }
}
