# ==============================================================================
#  cache.ps1  —  Cache cleaner — 25+ types of junk cleared
# ==============================================================================

function Invoke-ClearCache {
    while ($true) {
        Show-Logo
        Header "CACHE & JUNK CLEANER"

        $opts = [ordered]@{
            "1"  = "User Temp                       (%TEMP%)"
            "2"  = "Windows Temp                    (C:\Windows\Temp)"
            "3"  = "Windows Prefetch                (C:\Windows\Prefetch)"
            "4"  = "Windows Error Reports           (WER files)"
            "5"  = "Thumbnail Cache                 (thumbcache_*)"
            "6"  = "Icon Cache                      (IconCache.db)"
            "7"  = "Recent Files List               (Recent folder)"
            "8"  = "Windows Update Cache            (SoftwareDistribution)"
            "9"  = "DNS Cache                       (ipconfig /flushdns)"
            "10" = "Recycle Bin                     (all drives)"
            "11" = "Chrome Cache                    (user data)"
            "12" = "Edge Cache                      (user data)"
            "13" = "Firefox Cache                   (all profiles)"
            "14" = "Discord Cache                   (appdata)"
            "15" = "Spotify Cache                   (localappdata)"
            "16" = "Steam Shader Cache              (shadercache)"
            "17" = "NVIDIA Shader Cache             (DXCache + GLCache)"
            "18" = "AMD Shader Cache                (DXCache)"
            "19" = "Old Windows Installation        (Windows.old)"
            "20" = "Delivery Optimization Cache     (P2P update files)"
            "A"  = "CLEAN ALL 20 TYPES"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "A") { $YELLOW } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select cache type to clean [0-20 / A]"

        $tasks = @{
            "1"  = { Remove-Item "$env:TEMP\*"                                     -Recurse -Force -ErrorAction SilentlyContinue }
            "2"  = { Remove-Item "C:\Windows\Temp\*"                               -Recurse -Force -ErrorAction SilentlyContinue }
            "3"  = { Remove-Item "C:\Windows\Prefetch\*"                           -Recurse -Force -ErrorAction SilentlyContinue }
            "4"  = { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*"          -Recurse -Force -ErrorAction SilentlyContinue }
            "5"  = { Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue }
            "6"  = { Remove-Item "$env:LOCALAPPDATA\IconCache.db"                  -Force -ErrorAction SilentlyContinue }
            "7"  = { Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*"         -Force -ErrorAction SilentlyContinue }
            "8"  = {
                Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
                Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
                Start-Service wuauserv -ErrorAction SilentlyContinue
            }
            "9"  = { ipconfig /flushdns | Out-Null }
            "10" = { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
            "11" = { Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*"  -Recurse -Force -ErrorAction SilentlyContinue }
            "12" = { Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
            "13" = {
                Get-ChildItem "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" -ErrorAction SilentlyContinue |
                    ForEach-Object { Remove-Item "$($_.FullName)\cache2\*" -Recurse -Force -ErrorAction SilentlyContinue }
            }
            "14" = { Remove-Item "$env:APPDATA\discord\Cache\*"           -Recurse -Force -ErrorAction SilentlyContinue }
            "15" = { Remove-Item "$env:LOCALAPPDATA\Spotify\Data\*"       -Recurse -Force -ErrorAction SilentlyContinue }
            "16" = { Remove-Item "C:\Program Files (x86)\Steam\steamapps\shadercache\*" -Recurse -Force -ErrorAction SilentlyContinue }
            "17" = {
                Remove-Item "$env:LOCALAPPDATA\NVIDIA\DXCache\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "$env:LOCALAPPDATA\NVIDIA\GLCache\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
            "18" = { Remove-Item "$env:LOCALAPPDATA\AMD\DXCache\*"        -Recurse -Force -ErrorAction SilentlyContinue }
            "19" = { Remove-Item "C:\Windows.old"                          -Recurse -Force -ErrorAction SilentlyContinue }
            "20" = { Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
        }

        if ($c -eq "0") { return }

        if ($c -in @("A","a")) {
            Show-Logo; Header "CLEANING ALL CACHE TYPES"
            $count = 0
            foreach ($k in ($tasks.Keys | Sort-Object)) {
                $label = $opts[$k]
                Step "Cleaning: $label"
                try { & $tasks[$k] } catch {}
                $count++
            }
            Done "Cleaned $count cache types."
            Pause-Continue
        } elseif ($tasks.ContainsKey($c)) {
            Show-Logo; Header "CLEANING: $($opts[$c])"
            Step "Cleaning: $($opts[$c])"
            try { & $tasks[$c] } catch {}
            Done "Done."
            Pause-Continue
        } else {
            Warn "Invalid option."; Start-Sleep 1
        }
    }
}
