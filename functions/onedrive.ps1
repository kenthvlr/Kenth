# ==============================================================================
#  onedrive.ps1  —  OneDrive removal and disabling
# ==============================================================================

function Invoke-OneDriveMenu {
    while ($true) {
        Show-Logo
        Header "MICROSOFT ONEDRIVE"

        $opts = [ordered]@{
            "1" = "Remove OneDrive completely        (uninstall + clean registry)"
            "2" = "Disable OneDrive startup          (stop auto-launch, keep files)"
            "3" = "Remove OneDrive from File Explorer sidebar"
            "4" = "Disable OneDrive via Group Policy (block reinstall)"
        }
        foreach ($k in $opts.Keys) {
            $pad = "  [$k]".PadRight(9)
            $col = if ($k -eq "1") { $RED } else { $PURPLE }
            Write-Color "  ${col}$pad${RESET}  ${WHITE}$($opts[$k])${RESET}"
        }
        Write-Color ""
        Write-Color "  ${PURPLE}[0]${RESET}  ${GRAY}Back to Main Menu${RESET}"

        $c = Read-MenuChoice "Select OneDrive action"
        switch ($c) {
            "1" { Invoke-RemoveOneDrive }
            "2" { Invoke-DisableOneDriveStartup }
            "3" { Invoke-RemoveOneDriveSidebar }
            "4" { Invoke-BlockOneDrive }
            "0" { return }
        }
    }
}

function Invoke-RemoveOneDrive {
    Show-Logo; Header "REMOVE MICROSOFT ONEDRIVE"
    Warn "This will uninstall OneDrive and remove its files. Your OneDrive cloud files are NOT deleted."
    Write-Color ""
    Write-Color "  ${PURPLE}[Y]${RESET}  ${WHITE}Continue${RESET}"
    Write-Color "  ${PURPLE}[N]${RESET}  ${GRAY}Cancel${RESET}"
    $confirm = Read-MenuChoice "Confirm"
    if ($confirm -notmatch '^[Yy]') { Info "Cancelled."; Pause-Continue; return }

    Step "Stopping OneDrive processes..."
    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    Step "Uninstalling OneDrive..."
    $installers = @(
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe"
    )
    foreach ($i in $installers) {
        if (Test-Path $i) {
            Start-Process $i -ArgumentList "/uninstall /quiet" -Wait -ErrorAction SilentlyContinue
        }
    }

    Step "Removing OneDrive folders..."
    @(
        "$env:USERPROFILE\OneDrive",
        "$env:LOCALAPPDATA\Microsoft\OneDrive",
        "$env:PROGRAMDATA\Microsoft OneDrive",
        "C:\OneDriveTemp"
    ) | ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }

    Step "Cleaning registry..."
    Remove-Item "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"          -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OneDrive" -ErrorAction SilentlyContinue
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" DWord 1

    Done "OneDrive removed successfully. Restart your PC."
    Pause-Continue
}

function Invoke-DisableOneDriveStartup {
    Show-Logo; Header "DISABLE ONEDRIVE STARTUP"
    Step "Removing OneDrive from startup..."
    Remove-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OneDrive" -ErrorAction SilentlyContinue
    Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "OneDrive" -ErrorAction SilentlyContinue
    Step "Killing running OneDrive process..."
    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Done "OneDrive startup disabled. Your files are untouched."
    Pause-Continue
}

function Invoke-RemoveOneDriveSidebar {
    Show-Logo; Header "REMOVE ONEDRIVE FROM FILE EXPLORER"
    Step "Hiding OneDrive from File Explorer sidebar..."
    Set-RegValue "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" DWord 0
    Set-RegValue "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" DWord 0
    Done "OneDrive removed from File Explorer sidebar."
    Pause-Continue
}

function Invoke-BlockOneDrive {
    Show-Logo; Header "BLOCK ONEDRIVE VIA GROUP POLICY"
    Step "Applying group policy to prevent OneDrive sync..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableLibrariesDefaultSaveToOneDrive" DWord 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableMeteredNetworkFileSync" DWord 1
    Done "OneDrive blocked via Group Policy."
    Pause-Continue
}
