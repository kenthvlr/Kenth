# ==============================================================================
#  debloat.ps1  —  Remove pre-installed / useless Windows UWP apps
# ==============================================================================

$DebloatAppList = [ordered]@{
    "1"  = @{ name = "Xbox & Xbox Game Bar";         pkgs = @("Xbox","XboxGameCallableUI","XboxSpeechToTextOverlay","XboxIdentityProvider","XboxTcUiFramework") }
    "2"  = @{ name = "Cortana";                      pkgs = @("Microsoft.549981C3F5F10","Cortana") }
    "3"  = @{ name = "Mixed Reality / 3D Viewer";    pkgs = @("MixedReality","Microsoft3DViewer","Print3D","Microsoft.Print3D") }
    "4"  = @{ name = "Mail & Calendar (UWP)";        pkgs = @("windowscommunicationsapps") }
    "5"  = @{ name = "Bing News / Weather / Maps";   pkgs = @("BingNews","BingWeather","WindowsMaps","BingFinance","BingSports") }
    "6"  = @{ name = "Microsoft Solitaire";          pkgs = @("MicrosoftSolitaireCollection") }
    "7"  = @{ name = "People App";                   pkgs = @("People") }
    "8"  = @{ name = "Sticky Notes";                 pkgs = @("MicrosoftStickyNotes") }
    "9"  = @{ name = "Skype";                        pkgs = @("SkypeApp","Microsoft.Skype") }
    "10" = @{ name = "Microsoft Teams (built-in)";   pkgs = @("Teams","MicrosoftTeams") }
    "11" = @{ name = "Feedback Hub";                 pkgs = @("WindowsFeedbackHub") }
    "12" = @{ name = "Get Help / Tips";              pkgs = @("GetHelp","Microsoft.Tips") }
    "13" = @{ name = "Clipchamp Video Editor";       pkgs = @("Clipchamp","Microsoft.Clipchamp") }
    "14" = @{ name = "Microsoft To Do / Whiteboard"; pkgs = @("Microsoft.Todos","Microsoft.Wallet","Microsoft.Whiteboard") }
    "15" = @{ name = "Groove / Zune Music & Video";  pkgs = @("ZuneMusic","ZuneVideo","Microsoft.ZuneMusic") }
    "16" = @{ name = "OneNote (UWP)";                pkgs = @("OneNote","Microsoft.OneConnect") }
    "17" = @{ name = "Paint 3D";                     pkgs = @("MSPaint","Print3D") }
    "18" = @{ name = "Microsoft Power Automate";     pkgs = @("PowerAutomateDesktop") }
    "19" = @{ name = "Microsoft Family Safety";      pkgs = @("MicrosoftFamily") }
    "20" = @{ name = "Quick Assist";                 pkgs = @("QuickAssist") }
    "21" = @{ name = "Alarms & Clock";               pkgs = @("WindowsAlarms") }
    "22" = @{ name = "Phone Link (Your Phone)";      pkgs = @("YourPhone","PhoneLink") }
    "23" = @{ name = "Network Speed Test";           pkgs = @("NetworkSpeedTest") }
    "24" = @{ name = "Windows Recall / AI Copilot";  pkgs = @("Microsoft.Windows.AI.Copilot","Windows.Ai.Studio","Microsoft.Copilot") }
    "25" = @{ name = "MSN Weather (standalone)";     pkgs = @("Microsoft.BingWeather") }
    "26" = @{ name = "Microsoft News";               pkgs = @("Microsoft.News") }
    "27" = @{ name = "Microsoft Bing Search";        pkgs = @("Microsoft.BingSearch") }
    "28" = @{ name = "Xbox Console Companion";       pkgs = @("XboxApp") }
    "29" = @{ name = "Windows Media Player (UWP)";   pkgs = @("ZuneVideo") }
    "30" = @{ name = "Office Hub";                   pkgs = @("MicrosoftOfficeHub") }
}

function Invoke-RemoveApps {
    while ($true) {
        Show-Logo
        Header "REMOVE BLOATWARE APPS"
        Write-Color "  ${GRAY}These can be reinstalled from the Microsoft Store if needed.${RESET}"
        Write-Color ""

        foreach ($k in $DebloatAppList.Keys) {
            $pad = "  [$k]".PadRight(9)
            Write-Color "  ${PURPLE}$pad${RESET}  ${WHITE}$($DebloatAppList[$k].name)${RESET}"
        }
        Write-Color ""
        Divider "-" 78 $DPURPLE
        Write-Color "  ${YELLOW}  [A]${RESET}  ${YELLOW}Remove ALL listed bloatware${RESET}"
        Write-Color "  ${PURPLE}  [0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select app to remove [0-$($DebloatAppList.Count) / A]"
        if ($c -eq "0") { return }

        if ($c -in @("A","a")) {
            Write-Color ""
            Warn "Removing ALL bloatware apps..."
            Write-Color ""
            foreach ($k in $DebloatAppList.Keys) {
                Step "Removing: $($DebloatAppList[$k].name)"
                foreach ($pkg in $DebloatAppList[$k].pkgs) {
                    Remove-AppxSilent $pkg
                }
                Done "Done."
            }
            Pause-Continue
        } elseif ($DebloatAppList.ContainsKey($c)) {
            Write-Color ""
            Step "Removing: $($DebloatAppList[$c].name)"
            foreach ($pkg in $DebloatAppList[$c].pkgs) {
                Remove-AppxSilent $pkg
            }
            Done "$($DebloatAppList[$c].name) removed."
            Pause-Continue
        } else {
            Warn "Invalid option."; Start-Sleep 1
        }
    }
}
