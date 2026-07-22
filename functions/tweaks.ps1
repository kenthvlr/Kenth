# ==============================================================================
#  tweaks.ps1  —  Windows performance, UI, power, and system tweaks
# ==============================================================================

function Invoke-WindowsTweaks {
    while ($true) {
        Show-Logo
        Header "WINDOWS TWEAKS"

        $opts = [ordered]@{
            "1"  = "Performance Tweaks             (visual effects, animations off)"
            "2"  = "Ultimate Performance Plan       (hidden max-perf power plan)"
            "3"  = "Disable Animations             (faster UI, lower latency feel)"
            "4"  = "Taskbar & Explorer Cleanup      (remove search, widgets, news)"
            "5"  = "Lock Screen Tweaks             (disable ads, Spotlight)"
            "6"  = "Notification Cleanup           (disable action center tips)"
            "7"  = "Remove Windows AI / Copilot    (Recall, Copilot, AI sidebar)"
            "8"  = "Disable Background Apps        (stop UWP apps running in BG)"
            "9"  = "Disable Windows Search Index   (free RAM / reduce disk I/O)"
            "10" = "Page File — System Managed     (optimal auto page file)"
            "11" = "Disable Reserved Storage       (~7 GB reclaimed from disk)"
            "12" = "Show File Extensions           (always show .exe .zip etc.)"
            "13" = "Disable Startup Delay          (faster boot into desktop)"
            "14" = "Disable AutoPlay / AutoRun     (security hardening)"
            "15" = "Enable Long File Paths         (paths >260 characters)"
            "16" = "Disable Hibernation            (reclaim hiberfil.sys disk)"
            "17" = "Disable Sticky / Filter Keys   (no accidental popups)"
            "18" = "Set Best Performance Visuals   (strip aero glass effects)"
            "19" = "Disable Cortana Completely     (process + search integration)"
            "20" = "Disable Windows Tips & Tricks  (stop interruptions)"
            "A"  = "Apply ALL Tweaks Above"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "A") { $YELLOW } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select tweak [0-20 / A]"
        switch ($c) {
            "1"  { Invoke-PerfTweak }
            "2"  { Invoke-UltimatePower }
            "3"  { Invoke-NoAnimations }
            "4"  { Invoke-TaskbarTweak }
            "5"  { Invoke-LockScreenTweak }
            "6"  { Invoke-NotifTweak }
            "7"  { Invoke-RemoveWinAI }
            "8"  { Invoke-DisableBgApps }
            "9"  { Invoke-DisableSearch }
            "10" { Invoke-PageFile }
            "11" { Invoke-ReservedStorage }
            "12" { Invoke-FileExtensions }
            "13" { Invoke-DisableStartupDelay }
            "14" { Invoke-DisableAutoPlay }
            "15" { Invoke-LongFilePaths }
            "16" { Invoke-DisableHibernation }
            "17" { Invoke-DisableAccessibilityKeys }
            "18" { Invoke-BestPerfVisuals }
            "19" { Invoke-DisableCortana }
            "20" { Invoke-DisableTips }
            { $_ -in "A","a" } {
                Write-Color ""; Warn "Applying ALL tweaks..."
                Invoke-PerfTweak; Invoke-UltimatePower; Invoke-NoAnimations
                Invoke-TaskbarTweak; Invoke-LockScreenTweak; Invoke-NotifTweak
                Invoke-RemoveWinAI; Invoke-DisableBgApps; Invoke-ReservedStorage
                Invoke-FileExtensions; Invoke-DisableStartupDelay; Invoke-DisableAutoPlay
                Invoke-LongFilePaths; Invoke-DisableHibernation; Invoke-DisableAccessibilityKeys
                Invoke-BestPerfVisuals; Invoke-DisableCortana; Invoke-DisableTips
                Done "All tweaks applied! Restart for full effect."
                Pause-Continue
            }
            "0" { return }
        }
    }
}

# ── Individual tweak functions ────────────────────────────────────────────────

function Invoke-PerfTweak {
    Show-Logo; Header "PERFORMANCE TWEAKS"
    Step "Setting visual effects to Best Performance..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" DWord 2
    Set-RegValue "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" String "0"
    Step "Removing menu show delay..."
    Set-RegValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" String "0"
    Step "Disabling low-disk-space notification..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoLowDiskSpaceChecks" DWord 1
    Step "Disabling NTFS last-access timestamp..."
    try { fsutil behavior set disableLastAccess 1 2>&1 | Out-Null } catch {}
    Done "Performance tweaks applied."
    Pause-Continue
}

function Invoke-UltimatePower {
    Show-Logo; Header "ULTIMATE PERFORMANCE PLAN"
    Step "Unhiding and activating Ultimate Performance power plan..."
    try {
        $out = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
        if ($out -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
            $guid = $Matches[1]
            powercfg /setactive $guid 2>&1 | Out-Null
            Done "Ultimate Performance plan activated. (GUID: $guid)"
        } else {
            Warn "Plan may already exist. Attempting to find and set it active..."
            $list = powercfg /list 2>&1
            $match = $list | Select-String "Ultimate"
            if ($match) {
                $g = ($match.Line -replace ".*\(","" -replace "\).*","").Trim()
                powercfg /setactive $g 2>&1 | Out-Null
                Done "Ultimate Performance plan activated."
            } else {
                Warn "Plan not found. Your Windows version may not support it."
            }
        }
    } catch { Fail "Error: $_" }
    Pause-Continue
}

function Invoke-NoAnimations {
    Show-Logo; Header "DISABLE ANIMATIONS"
    Step "Disabling all UI animations..."
    Set-RegValue "HKCU:\Control Panel\Desktop" "UserPreferencesMask" Binary ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
    Set-RegValue "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" String "0"
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "AlwaysHibernateThumbnails" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "Animations" DWord 0
    Done "Animations disabled."
    Pause-Continue
}

function Invoke-TaskbarTweak {
    Show-Logo; Header "TASKBAR & EXPLORER CLEANUP"
    Step "Removing Search box..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" DWord 0
    Step "Removing Task View button..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" DWord 0
    Step "Removing Widgets..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" DWord 0
    Step "Removing Chat (Teams) icon..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" DWord 0
    Step "Removing Cortana from taskbar..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCortanaButton" DWord 0
    Step "Disabling News and Interests..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" DWord 0
    Done "Taskbar cleaned up."
    Pause-Continue
}

function Invoke-LockScreenTweak {
    Show-Logo; Header "LOCK SCREEN TWEAKS"
    Step "Disabling lock screen ads / Spotlight..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" DWord 0
    Done "Lock screen cleaned up."
    Pause-Continue
}

function Invoke-NotifTweak {
    Show-Logo; Header "NOTIFICATION CLEANUP"
    Step "Disabling action center tips and suggestions..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" DWord 0
    Step "Disabling notification banners on lock screen..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" DWord 0
    Done "Notifications cleaned up."
    Pause-Continue
}

function Invoke-RemoveWinAI {
    Show-Logo; Header "REMOVE WINDOWS AI / COPILOT / RECALL"
    Step "Disabling Copilot..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" DWord 1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" DWord 0
    Step "Disabling Windows Recall / AI snapshots..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" DWord 1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsAI" "DisableAIDataAnalysis" DWord 1
    Step "Removing AI components..."
    Remove-AppxSilent "Microsoft.Windows.AI.Copilot"
    Remove-AppxSilent "Windows.Ai.Studio"
    Remove-AppxSilent "Microsoft.Copilot"
    Step "Disabling AI Sidebar..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" "DisableMachineWidePolicy" DWord 1
    Done "Windows AI / Copilot / Recall removed."
    Pause-Continue
}

function Invoke-DisableBgApps {
    Show-Logo; Header "DISABLE BACKGROUND APPS"
    Step "Disabling global background app access..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" DWord 1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BackgroundAppGlobalToggle" DWord 0
    Done "Background apps disabled."
    Pause-Continue
}

function Invoke-DisableSearch {
    Show-Logo; Header "DISABLE WINDOWS SEARCH INDEXING"
    Step "Stopping and disabling Windows Search service..."
    Stop-Service WSearch -Force -ErrorAction SilentlyContinue
    Set-Service  WSearch -StartupType Disabled -ErrorAction SilentlyContinue
    Step "Disabling indexing via registry..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" DWord 0
    Done "Search indexing disabled. Restart to free RAM."
    Pause-Continue
}

function Invoke-PageFile {
    Show-Logo; Header "PAGE FILE — SYSTEM MANAGED"
    Step "Setting page file to system-managed (optimal auto-sizing)..."
    $cs = Get-WmiObject Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($cs) { $cs.AutomaticManagedPagefile = $true; $cs.Put() | Out-Null }
    Done "Page file is now system-managed."
    Pause-Continue
}

function Invoke-ReservedStorage {
    Show-Logo; Header "DISABLE RESERVED STORAGE"
    Step "Disabling Windows reserved storage (~7 GB reclaimed)..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" "ShippedWithReserves" DWord 0
    try { DISM /Online /Set-ReservedStorageState:Disabled 2>&1 | Out-Null } catch {}
    Done "Reserved storage disabled. Effect visible after next Windows Update."
    Pause-Continue
}

function Invoke-FileExtensions {
    Show-Logo; Header "SHOW FILE EXTENSIONS"
    Step "Enabling always-show file extensions in Explorer..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" DWord 1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSuperHidden" DWord 1
    Done "File extensions are now visible."
    Pause-Continue
}

function Invoke-DisableStartupDelay {
    Show-Logo; Header "DISABLE STARTUP DELAY"
    Step "Removing startup delay for apps..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" DWord 0
    Done "Startup delay removed."
    Pause-Continue
}

function Invoke-DisableAutoPlay {
    Show-Logo; Header "DISABLE AUTOPLAY / AUTORUN"
    Step "Disabling AutoPlay for all drive types..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" "DisableAutoplay" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" DWord 255
    Done "AutoPlay / AutoRun disabled."
    Pause-Continue
}

function Invoke-LongFilePaths {
    Show-Logo; Header "ENABLE LONG FILE PATHS"
    Step "Enabling support for paths longer than 260 characters..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" DWord 1
    Done "Long file paths enabled."
    Pause-Continue
}

function Invoke-DisableHibernation {
    Show-Logo; Header "DISABLE HIBERNATION"
    Step "Disabling hibernation (reclaims hiberfil.sys)..."
    try { powercfg /hibernate off 2>&1 | Out-Null } catch {}
    Done "Hibernation disabled. Disk space reclaimed."
    Pause-Continue
}

function Invoke-DisableAccessibilityKeys {
    Show-Logo; Header "DISABLE STICKY / FILTER / TOGGLE KEYS"
    Step "Disabling Sticky Keys popup..."
    Set-RegValue "HKCU:\Control Panel\Accessibility\StickyKeys"    "Flags" String "506"
    Set-RegValue "HKCU:\Control Panel\Accessibility\ToggleKeys"    "Flags" String "58"
    Set-RegValue "HKCU:\Control Panel\Accessibility\Keyboard Response" "Flags" String "122"
    Done "Accessibility key interruptions disabled."
    Pause-Continue
}

function Invoke-BestPerfVisuals {
    Show-Logo; Header "BEST PERFORMANCE VISUAL SETTINGS"
    Step "Applying best-performance visual settings..."
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-RegValue $regPath "VisualFXSetting" DWord 2
    Set-RegValue "HKCU:\Control Panel\Desktop" "DragFullWindows" String "0"
    Set-RegValue "HKCU:\Control Panel\Desktop" "FontSmoothing" String "2"
    Set-RegValue "HKCU:\Control Panel\Desktop" "UserPreferencesMask" Binary ([byte[]](0x90,0x12,0x01,0x80,0x10,0x00,0x00,0x00))
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" DWord 0
    Done "Best performance visuals applied."
    Pause-Continue
}

function Invoke-DisableCortana {
    Show-Logo; Header "DISABLE CORTANA"
    Step "Disabling Cortana via policy..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortanaAboveLock" DWord 0
    Step "Removing Cortana app..."
    Remove-AppxSilent "Microsoft.549981C3F5F10"
    Remove-AppxSilent "Cortana"
    Done "Cortana disabled."
    Pause-Continue
}

function Invoke-DisableTips {
    Show-Logo; Header "DISABLE WINDOWS TIPS & TRICKS"
    Step "Disabling Windows tips, suggestions, and offer notifications..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353698Enabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "OemPreInstalledAppsEnabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEnabled" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" DWord 0
    Done "Windows tips and suggestions disabled."
    Pause-Continue
}
