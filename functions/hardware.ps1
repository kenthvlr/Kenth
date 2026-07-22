# ==============================================================================
#  hardware.ps1  —  Hardware and advanced system tweaks
# ==============================================================================

function Invoke-HardwareMenu {
    while ($true) {
        Show-Logo
        Header "HARDWARE & ADVANCED TWEAKS"

        $opts = [ordered]@{
            "1"  = "Disable Power Throttling          (no CPU power limits)"
            "2"  = "Enable HAGS                       (Hardware GPU Scheduling)"
            "3"  = "Optimize NTFS                     (disable last-access, 8.3 names)"
            "4"  = "Disable Drive Write Cache Flush   (performance, needs UPS)"
            "5"  = "Enable SSD TRIM                   (keep SSD healthy)"
            "6"  = "RAM — Disable Paging Executive    (keep kernel in RAM)"
            "7"  = "RAM — Clear Page File at Shutdown (privacy tweak)"
            "8"  = "Disable HDCP                      (driver-level DRM hint)"
            "9"  = "Disable Memory Compression        (free RAM at cost of pagefile)"
            "10" = "Optimize IRQ Priority for GPU     (less CPU interrupt delay)"
            "A"  = "Apply ALL Hardware Tweaks"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "A") { $YELLOW } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select hardware tweak"
        switch ($c) {
            "1"  { Invoke-DisablePowerThrottle }
            "2"  { Invoke-HAGS }
            "3"  { Invoke-NTFSOptimize }
            "4"  { Invoke-WriteCacheFlush }
            "5"  { Invoke-EnableTRIM }
            "6"  { Invoke-DisablePagingExec }
            "7"  { Invoke-ClearPageFileShutdown }
            "8"  { Invoke-DisableHDCP }
            "9"  { Invoke-DisableMemCompression }
            "10" { Invoke-IRQPriority }
            { $_ -in "A","a" } {
                Write-Color ""; Warn "Applying ALL hardware tweaks..."
                Invoke-DisablePowerThrottle; Invoke-HAGS; Invoke-NTFSOptimize
                Invoke-DisablePagingExec; Invoke-EnableTRIM
                Done "All hardware tweaks applied! Restart for full effect."
                Pause-Continue
            }
            "0" { return }
        }
    }
}

function Invoke-DisablePowerThrottle {
    Show-Logo; Header "DISABLE POWER THROTTLING"
    Step "Disabling Windows power throttling for all processes..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" DWord 1
    Done "Power throttling disabled."
    Pause-Continue
}

function Invoke-NTFSOptimize {
    Show-Logo; Header "OPTIMIZE NTFS"
    Step "Disabling last-access timestamp update..."
    try { fsutil behavior set disableLastAccess 1 2>&1 | Out-Null } catch {}
    Step "Disabling 8.3 short filename creation..."
    try { fsutil behavior set disable8dot3 1 2>&1 | Out-Null } catch {}
    Step "Enabling delete notifications (TRIM for HDDs)..."
    try { fsutil behavior set DisableDeleteNotify 0 2>&1 | Out-Null } catch {}
    Done "NTFS optimized."
    Pause-Continue
}

function Invoke-WriteCacheFlush {
    Show-Logo; Header "DISABLE DRIVE WRITE CACHE FLUSH"
    Warn "Only recommended if you have a UPS or desktop (power loss can corrupt data)."
    Write-Color ""
    Write-Color "  ${PURPLE}[Y]${RESET}  ${WHITE}Continue and disable write cache flush${RESET}"
    Write-Color "  ${PURPLE}[N]${RESET}  ${GRAY}Cancel${RESET}"
    $confirm = Read-MenuChoice "Confirm"
    if ($confirm -in @("Y","y")) {
        Get-Disk | ForEach-Object {
            $disk = $_
            Get-StorageReliabilityCounter -Disk $disk -ErrorAction SilentlyContinue | Out-Null
        }
        Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "DontVerifyRandomDrivers" DWord 1
        Done "Write cache flush disabled (use with caution)."
    } else { Info "Cancelled." }
    Pause-Continue
}

function Invoke-EnableTRIM {
    Show-Logo; Header "ENABLE SSD TRIM"
    Step "Enabling TRIM for SSD health..."
    try { fsutil behavior set DisableDeleteNotify 0 2>&1 | Out-Null } catch {}
    try { Optimize-Volume -DriveType SSD -ReTrim -ErrorAction SilentlyContinue } catch {}
    Done "TRIM enabled."
    Pause-Continue
}

function Invoke-DisablePagingExec {
    Show-Logo; Header "RAM — DISABLE PAGING EXECUTIVE"
    Step "Disabling paging executive (keeps kernel code in RAM)..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" DWord 1
    Done "Paging executive disabled. Requires restart."
    Pause-Continue
}

function Invoke-ClearPageFileShutdown {
    Show-Logo; Header "CLEAR PAGE FILE AT SHUTDOWN"
    Write-Color "  ${PURPLE}[1]${RESET}  ${WHITE}Enable  — clear page file at shutdown (slower, more private)${RESET}"
    Write-Color "  ${PURPLE}[2]${RESET}  ${WHITE}Disable — keep page file across reboots (faster shutdown)${RESET}"
    $c = Read-MenuChoice "Select"
    switch ($c) {
        "1" { Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" DWord 1; Done "Page file will be cleared at shutdown." }
        "2" { Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" DWord 0; Done "Page file kept across reboots." }
    }
    Pause-Continue
}

function Invoke-DisableHDCP {
    Show-Logo; Header "DISABLE HDCP"
    Step "Setting HDCP hint via registry (may require DDU + clean driver install)..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" "RMHdcpKeyGlobZero" DWord 1
    Warn "HDCP disable is GPU driver-dependent. DDU + reinstall may be needed for full effect."
    Done "HDCP hint set."
    Pause-Continue
}

function Invoke-DisableMemCompression {
    Show-Logo; Header "DISABLE MEMORY COMPRESSION"
    Warn "Disabling memory compression frees CPU but increases page file usage."
    try {
        Disable-MMAgent -MemoryCompression -ErrorAction Stop
        Done "Memory compression disabled."
    } catch {
        Fail "Could not disable memory compression: $_"
    }
    Pause-Continue
}

function Invoke-IRQPriority {
    Show-Logo; Header "OPTIMIZE IRQ PRIORITY FOR GPU"
    Step "Boosting GPU interrupt priority in system profile..."
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Set-RegValue $path "GPU Priority"         DWord  8
    Set-RegValue $path "Priority"             DWord  6
    Set-RegValue $path "Scheduling Category" String "High"
    Set-RegValue $path "SFIO Priority"       String "High"
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" DWord 0
    Done "IRQ / interrupt priority optimized for GPU."
    Pause-Continue
}
