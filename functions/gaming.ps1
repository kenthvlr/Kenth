# ==============================================================================
#  gaming.ps1  —  FPS, latency, gaming mode, GPU scheduling tweaks
# ==============================================================================

function Invoke-GamingMenu {
    while ($true) {
        Show-Logo
        Header "FPS & GAMING OPTIMIZATION"

        $opts = [ordered]@{
            "1"  = "Enable Game Mode                (Windows Game Mode + auto detect)"
            "2"  = "Disable Game DVR / Xbox Capture (FPS boost — removes overlay)"
            "3"  = "GPU & CPU Priority for Games    (scheduler priority boost)"
            "4"  = "Hardware GPU Scheduling (HAGS)  (modern GPU latency reduction)"
            "5"  = "Disable Fullscreen Optimizations(exclusive fullscreen fix)"
            "6"  = "Raw Mouse Input                 (disable pointer precision)"
            "7"  = "Timer Resolution — 1ms          (precision game tick rate)"
            "8"  = "Unpark CPU Cores               (all cores active at all times)"
            "9"  = "Disable CPU Throttling          (no power-saving on cores)"
            "10" = "Network Latency Pack            (TCP/IP gaming stack tuning)"
            "11" = "Process Priority Boost          (games get CPU priority)"
            "12" = "Disable Xbox Game Bar Hotkeys   (no Win+G interrupts)"
            "13" = "NVIDIA — Prefer Max Performance (per-GPU power mode hint)"
            "14" = "Disable Dynamic Tick            (more consistent frame times)"
            "A"  = "Apply ALL Gaming Tweaks"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "A") { $YELLOW } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select tweak [0-14 / A]"
        switch ($c) {
            "1"  { Invoke-GameMode }
            "2"  { Invoke-GameBarTweak }
            "3"  { Invoke-GamePriority }
            "4"  { Invoke-HAGS }
            "5"  { Invoke-FullscreenOpt }
            "6"  { Invoke-RawMouse }
            "7"  { Invoke-TimerResolution }
            "8"  { Invoke-CPUUnpark }
            "9"  { Invoke-DisableCPUThrottle }
            "10" { Invoke-NetworkLatencyPack }
            "11" { Invoke-ProcessPriorityBoost }
            "12" { Invoke-DisableXboxHotkeys }
            "13" { Invoke-NvidiaMaxPerf }
            "14" { Invoke-DynamicTick }
            { $_ -in "A","a" } {
                Write-Color ""; Warn "Applying ALL gaming tweaks..."
                Invoke-GameMode; Invoke-GameBarTweak; Invoke-GamePriority; Invoke-HAGS
                Invoke-FullscreenOpt; Invoke-RawMouse; Invoke-TimerResolution
                Invoke-CPUUnpark; Invoke-DisableCPUThrottle; Invoke-NetworkLatencyPack
                Invoke-ProcessPriorityBoost; Invoke-DisableXboxHotkeys; Invoke-DynamicTick
                Done "All gaming tweaks applied! Restart for full effect."
                Pause-Continue
            }
            "0" { return }
        }
    }
}

function Invoke-GameMode {
    Show-Logo; Header "ENABLE GAME MODE"
    Step "Enabling Windows Game Mode and auto-detection..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" DWord 1
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" DWord 1
    Done "Game Mode enabled."
    Pause-Continue
}

function Invoke-GameBarTweak {
    Show-Logo; Header "DISABLE GAME DVR / XBOX CAPTURE"
    Step "Disabling Xbox Game DVR (FPS improvement)..."
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" DWord 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" DWord 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AudioCaptureEnabled" DWord 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "HistoricalCaptureEnabled" DWord 0
    Done "Game DVR / Xbox Capture disabled."
    Pause-Continue
}

function Invoke-GamePriority {
    Show-Logo; Header "GPU & CPU GAME PRIORITY"
    Step "Setting GPU Priority to 8 for games..."
    $gp = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Set-RegValue $gp "GPU Priority"         DWord  8
    Set-RegValue $gp "Priority"             DWord  6
    Set-RegValue $gp "Scheduling Category" String "High"
    Set-RegValue $gp "SFIO Priority"       String "High"
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" DWord 0
    Done "Game CPU/GPU priority set."
    Pause-Continue
}

function Invoke-HAGS {
    Show-Logo; Header "HARDWARE GPU SCHEDULING (HAGS)"
    Step "Enabling Hardware-Accelerated GPU Scheduling..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" DWord 2
    Done "HAGS enabled. Restart for effect (requires Win10 2004+ and compatible GPU)."
    Pause-Continue
}

function Invoke-FullscreenOpt {
    Show-Logo; Header "DISABLE FULLSCREEN OPTIMIZATIONS"
    Step "Disabling FSO for exclusive fullscreen (less latency)..."
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" DWord 2
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" DWord 1
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" DWord 1
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" "DirectXUserGlobalSettings" String "SwapEffectUpgradeEnable=0;"
    Done "Fullscreen Optimizations disabled."
    Pause-Continue
}

function Invoke-RawMouse {
    Show-Logo; Header "RAW MOUSE INPUT"
    Step "Disabling mouse pointer precision (raw 1:1 input)..."
    Set-RegValue "HKCU:\Control Panel\Mouse" "MouseSpeed"      String "0"
    Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" String "0"
    Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" String "0"
    Done "Raw mouse input enabled — pointer precision off."
    Pause-Continue
}

function Invoke-TimerResolution {
    Show-Logo; Header "TIMER RESOLUTION — 1ms"
    Step "Setting global timer resolution requests to 1ms..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" DWord 1
    Done "Timer resolution set to 1ms. Better for frame timing."
    Pause-Continue
}

function Invoke-CPUUnpark {
    Show-Logo; Header "UNPARK CPU CORES"
    Step "Setting CPU core unparking policy (all cores always active)..."
    $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
    Set-RegValue $p "ValueMax" DWord 0
    Set-RegValue $p "ValueMin" DWord 0
    try {
        powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0 2>&1 | Out-Null
        powercfg /setactive scheme_current 2>&1 | Out-Null
    } catch {}
    Done "CPU cores unparked."
    Pause-Continue
}

function Invoke-DisableCPUThrottle {
    Show-Logo; Header "DISABLE CPU THROTTLING"
    Step "Disabling Windows power throttling for all processes..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" DWord 1
    Done "CPU throttling disabled."
    Pause-Continue
}

function Invoke-NetworkLatencyPack {
    Show-Logo; Header "NETWORK LATENCY PACK"
    Step "Tuning TCP/IP stack for gaming (lower latency)..."
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    netsh int tcp set global rss=enabled           2>&1 | Out-Null
    netsh int tcp set global fastopen=enabled       2>&1 | Out-Null
    netsh int tcp set global timestamps=disabled    2>&1 | Out-Null
    netsh int tcp set global dca=enabled            2>&1 | Out-Null
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" DWord 0xffffffff
    Step "Flushing DNS cache..."
    ipconfig /flushdns | Out-Null
    Done "Network latency pack applied."
    Pause-Continue
}

function Invoke-ProcessPriorityBoost {
    Show-Logo; Header "PROCESS PRIORITY BOOST"
    Step "Enabling foreground process priority boost..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" DWord 38
    Done "Process priority boost enabled."
    Pause-Continue
}

function Invoke-DisableXboxHotkeys {
    Show-Logo; Header "DISABLE XBOX GAME BAR HOTKEYS"
    Step "Disabling Win+G and all Xbox Game Bar hotkeys..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" "value" DWord 0
    Done "Xbox Game Bar hotkeys disabled."
    Pause-Continue
}

function Invoke-NvidiaMaxPerf {
    Show-Logo; Header "NVIDIA — PREFER MAX PERFORMANCE"
    Step "Setting NVIDIA power preference hint via registry..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "PerfLevelSrc" DWord 0x2222
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "PowerMizerEnable" DWord 1
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "PowerMizerLevel" DWord 1
    Warn "Also set 'Prefer Maximum Performance' in NVIDIA Control Panel for full effect."
    Done "NVIDIA max performance hint set."
    Pause-Continue
}

function Invoke-DynamicTick {
    Show-Logo; Header "DISABLE DYNAMIC TICK"
    Step "Disabling dynamic tick for more consistent frame times..."
    try { bcdedit /set disabledynamictick yes 2>&1 | Out-Null } catch {}
    Done "Dynamic tick disabled. Restart required."
    Pause-Continue
}
