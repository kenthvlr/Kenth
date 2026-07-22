# ==============================================================================
#  network.ps1  —  Network tweaks, DNS, TCP stack, latency optimization
# ==============================================================================

function Invoke-NetworkMenu {
    while ($true) {
        Show-Logo
        Header "NETWORK TWEAKS"

        $opts = [ordered]@{
            "1"  = "TCP/IP Stack Tuning             (autotune, RSS, FastOpen)"
            "2"  = "DNS Flush & Change              (flush cache, set fast DNS)"
            "3"  = "Disable Nagle's Algorithm       (lower TCP latency)"
            "4"  = "Disable Network Throttling      (remove MM scheduler limit)"
            "5"  = "Enable TCP Fast Open            (reduce handshake overhead)"
            "6"  = "Disable LLMNR / NetBIOS         (privacy + security)"
            "7"  = "Disable WiFi Sense              (stop sharing WiFi)"
            "8"  = "Set MTU to 1500                 (standard Ethernet MTU)"
            "9"  = "Disable QoS Packet Scheduler    (free reserved bandwidth)"
            "A"  = "Apply ALL Network Tweaks"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "A") { $YELLOW } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select network tweak"
        switch ($c) {
            "1"  { Invoke-TCPTuning }
            "2"  { Invoke-DNSTweak }
            "3"  { Invoke-DisableNagle }
            "4"  { Invoke-DisableNetworkThrottle }
            "5"  { Invoke-TCPFastOpen }
            "6"  { Invoke-DisableLLMNR }
            "7"  { Invoke-DisableWiFiSense }
            "8"  { Invoke-SetMTU }
            "9"  { Invoke-DisableQoS }
            { $_ -in "A","a" } {
                Write-Color ""; Warn "Applying ALL network tweaks..."
                Invoke-TCPTuning; Invoke-DisableNagle; Invoke-DisableNetworkThrottle
                Invoke-TCPFastOpen; Invoke-DisableLLMNR; Invoke-DisableWiFiSense; Invoke-DisableQoS
                ipconfig /flushdns | Out-Null
                Done "All network tweaks applied."
                Pause-Continue
            }
            "0" { return }
        }
    }
}

function Invoke-TCPTuning {
    Show-Logo; Header "TCP/IP STACK TUNING"
    Step "Enabling receive-side scaling (RSS)..."
    netsh int tcp set global rss=enabled           2>&1 | Out-Null
    Step "Setting autotune level to Normal..."
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    Step "Enabling Direct Cache Access (DCA)..."
    netsh int tcp set global dca=enabled            2>&1 | Out-Null
    Step "Enabling ECN capability..."
    netsh int tcp set global ecncapability=enabled  2>&1 | Out-Null
    Step "Disabling timestamps (reduces overhead)..."
    netsh int tcp set global timestamps=disabled    2>&1 | Out-Null
    Step "Removing network throttling index..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" DWord 0xffffffff
    ipconfig /flushdns | Out-Null
    Done "TCP/IP stack tuned."
    Pause-Continue
}

function Invoke-DNSTweak {
    Show-Logo; Header "DNS FLUSH & CHANGE"
    Step "Flushing DNS cache..."
    ipconfig /flushdns | Out-Null
    Write-Color ""
    Write-Color "  ${WHITE}Change DNS servers? Select a provider:${RESET}"
    Write-Color "  ${PURPLE}[1]${RESET}  ${WHITE}Cloudflare      1.1.1.1  /  1.0.0.1  (fastest)${RESET}"
    Write-Color "  ${PURPLE}[2]${RESET}  ${WHITE}Google          8.8.8.8  /  8.8.4.4${RESET}"
    Write-Color "  ${PURPLE}[3]${RESET}  ${WHITE}Quad9           9.9.9.9  /  149.112.112.112  (secure)${RESET}"
    Write-Color "  ${PURPLE}[4]${RESET}  ${WHITE}OpenDNS         208.67.222.222 / 208.67.220.220${RESET}"
    Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Skip DNS change (just flush)${RESET}"
    $d = Read-MenuChoice "Select DNS"
    $dns = switch ($d) {
        "1" { @("1.1.1.1","1.0.0.1") }
        "2" { @("8.8.8.8","8.8.4.4") }
        "3" { @("9.9.9.9","149.112.112.112") }
        "4" { @("208.67.222.222","208.67.220.220") }
        default { $null }
    }
    if ($dns) {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($a in $adapters) {
            Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses $dns -ErrorAction SilentlyContinue
        }
        Done "DNS changed to $($dns[0]) / $($dns[1])."
    } else {
        Done "DNS cache flushed."
    }
    Pause-Continue
}

function Invoke-DisableNagle {
    Show-Logo; Header "DISABLE NAGLE'S ALGORITHM"
    Step "Disabling Nagle's Algorithm (lower TCP latency for gaming)..."
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $tcpPath -ErrorAction SilentlyContinue | ForEach-Object {
        Set-RegValue $_.PSPath "TcpAckFrequency" DWord 1
        Set-RegValue $_.PSPath "TCPNoDelay" DWord 1
    }
    Done "Nagle's Algorithm disabled across all interfaces."
    Pause-Continue
}

function Invoke-DisableNetworkThrottle {
    Show-Logo; Header "DISABLE NETWORK THROTTLING"
    Step "Removing Multimedia scheduler network throttle..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" DWord 0xffffffff
    Done "Network throttling removed."
    Pause-Continue
}

function Invoke-TCPFastOpen {
    Show-Logo; Header "ENABLE TCP FAST OPEN"
    Step "Enabling TCP Fast Open..."
    netsh int tcp set global fastopen=enabled 2>&1 | Out-Null
    Done "TCP Fast Open enabled."
    Pause-Continue
}

function Invoke-DisableLLMNR {
    Show-Logo; Header "DISABLE LLMNR / NETBIOS"
    Step "Disabling LLMNR (Link-Local Multicast Name Resolution)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" "EnableMulticast" DWord 0
    Step "Disabling NetBIOS over TCP/IP on all adapters..."
    Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue |
        Where-Object { $_.IPEnabled } |
        ForEach-Object { $_.SetTcpipNetbios(2) | Out-Null }
    Done "LLMNR and NetBIOS disabled."
    Pause-Continue
}

function Invoke-DisableWiFiSense {
    Show-Logo; Header "DISABLE WIFI SENSE"
    Step "Disabling automatic WiFi network sharing..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" "value" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" "value" DWord 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" DWord 0
    Done "WiFi Sense disabled."
    Pause-Continue
}

function Invoke-SetMTU {
    Show-Logo; Header "SET MTU TO 1500"
    Step "Setting MTU to 1500 on all active adapters..."
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($a in $adapters) {
        netsh interface ipv4 set subinterface "$($a.Name)" mtu=1500 store=persistent 2>&1 | Out-Null
        Step "Set MTU=1500 on $($a.Name)"
    }
    Done "MTU set to 1500."
    Pause-Continue
}

function Invoke-DisableQoS {
    Show-Logo; Header "DISABLE QOS PACKET SCHEDULER"
    Step "Removing 20% bandwidth reservation for QoS..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" DWord 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" "NoReserveBandwidth" DWord 1
    Done "QoS bandwidth reservation removed."
    Pause-Continue
}
