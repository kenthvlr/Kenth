# ==============================================================================
#  KenthUI.ps1  —  WPF GUI entry point
#  Run: powershell -NoProfile -ExecutionPolicy Bypass -File KenthUI.ps1
#  Or:  iwr -useb https://raw.githubusercontent.com/kenthvlr/Kenth/main/KenthUI.ps1 | iex
# ==============================================================================

#Requires -Version 5.1
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"

# ── Load WPF assemblies ───────────────────────────────────────────────────────
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ── Admin check ───────────────────────────────────────────────────────────────
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
$isAdmin = Test-IsAdmin

if (-not $isAdmin) {
    $result = [System.Windows.MessageBox]::Show(
        "Kenth should run as Administrator for all tweaks to work.`n`nRelaunch as Administrator now?",
        "Kenth — Admin Required",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($result -eq "Yes") {
        $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process powershell -Verb RunAs -ArgumentList $arg
        exit
    }
}

# ── Registry helpers (inline for standalone UI mode) ─────────────────────────
function Set-RegValue { param($path,$name,$type,$value)
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Type $type -Value $value -Force
}
function Remove-AppxSilent($pattern) {
    Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$pattern*" } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*$pattern*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
function Test-Winget { $null -ne (Get-Command winget -ErrorAction SilentlyContinue) }

# ── Load function modules if running from file (not iex) ─────────────────────
if ($PSCommandPath) {
    $root = Split-Path -Parent $PSCommandPath
    $modules = @("functions\core.ps1","functions\installer.ps1","functions\tweaks.ps1",
                 "functions\gaming.ps1","functions\privacy.ps1","functions\debloat.ps1",
                 "functions\network.ps1","functions\services.ps1","functions\cache.ps1",
                 "functions\hardware.ps1","functions\sysinfo.ps1","functions\edge.ps1",
                 "functions\onedrive.ps1","functions\menu.ps1")
    foreach ($m in $modules) {
        $p = Join-Path $root $m
        if (Test-Path $p) { . $p }
    }
}

# ==============================================================================
#  APP CATALOG  (for GUI app installer)
# ==============================================================================
$GuiAppCatalog = @(
    # Browsers
    @{ cat="Browsers";    name="Google Chrome";        id="Google.Chrome" }
    @{ cat="Browsers";    name="Mozilla Firefox";      id="Mozilla.Firefox" }
    @{ cat="Browsers";    name="Brave";                id="Brave.Brave" }
    @{ cat="Browsers";    name="Opera GX";             id="Opera.OperaGX" }
    @{ cat="Browsers";    name="LibreWolf";             id="LibreWolf.LibreWolf" }
    @{ cat="Browsers";    name="Tor Browser";           id="TorProject.TorBrowser" }
    @{ cat="Browsers";    name="Vivaldi";               id="Vivaldi.Vivaldi" }
    @{ cat="Browsers";    name="Waterfox";              id="Waterfox.Waterfox" }
    # Communication
    @{ cat="Communication"; name="Discord";             id="Discord.Discord" }
    @{ cat="Communication"; name="Telegram";            id="Telegram.TelegramDesktop" }
    @{ cat="Communication"; name="Signal";              id="OpenWhisperSystems.Signal" }
    @{ cat="Communication"; name="Slack";               id="SlackTechnologies.Slack" }
    @{ cat="Communication"; name="Zoom";                id="Zoom.Zoom" }
    @{ cat="Communication"; name="Microsoft Teams";     id="Microsoft.Teams" }
    @{ cat="Communication"; name="Mumble";              id="Mumble.Mumble" }
    @{ cat="Communication"; name="Element";             id="Element.Element" }
    # Gaming
    @{ cat="Gaming";      name="Steam";                 id="Valve.Steam" }
    @{ cat="Gaming";      name="Epic Games";            id="EpicGames.EpicGamesLauncher" }
    @{ cat="Gaming";      name="GOG Galaxy";            id="GOG.Galaxy" }
    @{ cat="Gaming";      name="Battle.net";            id="Blizzard.BattleNet" }
    @{ cat="Gaming";      name="EA App";                id="ElectronicArts.EADesktop" }
    @{ cat="Gaming";      name="Ubisoft Connect";       id="Ubisoft.Connect" }
    @{ cat="Gaming";      name="Playnite";              id="Playnite.Playnite" }
    @{ cat="Gaming";      name="MSI Afterburner";       id="Guru3D.Afterburner" }
    @{ cat="Gaming";      name="RTSS";                  id="Guru3D.RTSS" }
    @{ cat="Gaming";      name="HWiNFO64";              id="REALiX.HWiNFO" }
    # Media
    @{ cat="Media";       name="Spotify";               id="Spotify.Spotify" }
    @{ cat="Media";       name="VLC";                   id="VideoLAN.VLC" }
    @{ cat="Media";       name="OBS Studio";            id="OBSProject.OBSStudio" }
    @{ cat="Media";       name="Audacity";              id="Audacity.Audacity" }
    @{ cat="Media";       name="HandBrake";             id="HandBrake.HandBrake" }
    @{ cat="Media";       name="foobar2000";            id="PeterPawlowski.foobar2000" }
    @{ cat="Media";       name="MusicBee";              id="MusicBee.MusicBee" }
    @{ cat="Media";       name="MPC-HC";                id="clsid2.mpc-hc" }
    @{ cat="Media";       name="AIMP";                  id="AIMP.AIMP" }
    # Development
    @{ cat="Development"; name="VS Code";               id="Microsoft.VisualStudioCode" }
    @{ cat="Development"; name="Git";                   id="Git.Git" }
    @{ cat="Development"; name="Node.js LTS";           id="OpenJS.NodeJS.LTS" }
    @{ cat="Development"; name="Python 3";              id="Python.Python.3" }
    @{ cat="Development"; name="Windows Terminal";      id="Microsoft.WindowsTerminal" }
    @{ cat="Development"; name="PowerShell 7";          id="Microsoft.PowerShell" }
    @{ cat="Development"; name="Notepad++";             id="Notepad++.Notepad++" }
    @{ cat="Development"; name="GitHub Desktop";        id="GitHub.GitHubDesktop" }
    @{ cat="Development"; name="Docker Desktop";        id="Docker.DockerDesktop" }
    @{ cat="Development"; name="Postman";               id="Postman.Postman" }
    @{ cat="Development"; name="HeidiSQL";              id="HeidiSQL.HeidiSQL" }
    @{ cat="Development"; name="JetBrains Toolbox";     id="JetBrains.Toolbox" }
    # Utilities
    @{ cat="Utilities";   name="7-Zip";                 id="7zip.7zip" }
    @{ cat="Utilities";   name="WinRAR";                id="RARLab.WinRAR" }
    @{ cat="Utilities";   name="Everything";            id="voidtools.Everything" }
    @{ cat="Utilities";   name="PowerToys";             id="Microsoft.PowerToys" }
    @{ cat="Utilities";   name="TreeSize Free";         id="JAMSoftware.TreeSize.Free" }
    @{ cat="Utilities";   name="WizTree";               id="AntibodySoftware.WizTree" }
    @{ cat="Utilities";   name="CPU-Z";                 id="CPUID.CPU-Z" }
    @{ cat="Utilities";   name="GPU-Z";                 id="TechPowerUp.GPU-Z" }
    @{ cat="Utilities";   name="CrystalDiskInfo";       id="CrystalDewWorld.CrystalDiskInfo" }
    @{ cat="Utilities";   name="ShareX";                id="ShareX.ShareX" }
    # Security
    @{ cat="Security";    name="Malwarebytes";          id="Malwarebytes.Malwarebytes" }
    @{ cat="Security";    name="Bitwarden";             id="Bitwarden.Bitwarden" }
    @{ cat="Security";    name="KeePassXC";             id="KeePassXCTeam.KeePassXC" }
    @{ cat="Security";    name="ProtonVPN";             id="ProtonTechnologies.ProtonVPN" }
    @{ cat="Security";    name="VeraCrypt";             id="IDRIX.VeraCrypt" }
    @{ cat="Security";    name="Wireshark";             id="WiresharkFoundation.Wireshark" }
    @{ cat="Security";    name="O&O ShutUp10++";        id="OO-Software.ShutUp10" }
    # System Tools
    @{ cat="System Tools"; name="Process Hacker";       id="winsiderss.systeminformer.preview" }
    @{ cat="System Tools"; name="Autoruns";             id="Microsoft.Sysinternals.Autoruns" }
    @{ cat="System Tools"; name="BCUninstaller";        id="Klocman.BulkCrapUninstaller" }
    @{ cat="System Tools"; name="Speccy";               id="Piriform.Speccy" }
    @{ cat="System Tools"; name="HWMonitor";            id="CPUID.HWMonitor" }
    @{ cat="System Tools"; name="NVCleanstall";         id="TechPowerUp.NVCleanstall" }
    @{ cat="System Tools"; name="DDU";                  id="Wagnardsoft.DisplayDriverUninstaller" }
    @{ cat="System Tools"; name="LatencyMon";           id="ResPlat.LatencyMon" }
)
$AllCategories = ($GuiAppCatalog | Select-Object -ExpandProperty cat -Unique | Sort-Object) + @("All")

# ==============================================================================
#  XAML — Clean dark purple/black UI with hover effects + blur
# ==============================================================================
[xml]$XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Kenth PC Tweak Tool v5.0"
    Height="820" Width="1200"
    MinHeight="600" MinWidth="900"
    Background="#0A0010"
    WindowStartupLocation="CenterScreen"
    AllowsTransparency="False"
    FontFamily="Segoe UI"
    >
  <Window.Resources>

    <!-- ── Color palette ── -->
    <SolidColorBrush x:Key="BgDark"     Color="#0A0010"/>
    <SolidColorBrush x:Key="BgPanel"    Color="#100020"/>
    <SolidColorBrush x:Key="BgCard"     Color="#160030"/>
    <SolidColorBrush x:Key="BgHover"    Color="#220050"/>
    <SolidColorBrush x:Key="Purple1"    Color="#7C3AED"/>
    <SolidColorBrush x:Key="Purple2"    Color="#9D5CF0"/>
    <SolidColorBrush x:Key="Purple3"    Color="#C4B5FD"/>
    <SolidColorBrush x:Key="Purple4"    Color="#4C1D95"/>
    <SolidColorBrush x:Key="AccentGreen" Color="#10B981"/>
    <SolidColorBrush x:Key="AccentRed"   Color="#EF4444"/>
    <SolidColorBrush x:Key="AccentYellow" Color="#F59E0B"/>
    <SolidColorBrush x:Key="TextMain"   Color="#E5E7EB"/>
    <SolidColorBrush x:Key="TextSub"    Color="#9CA3AF"/>
    <SolidColorBrush x:Key="Border1"    Color="#2E1060"/>

    <!-- ── Tab style ── -->
    <Style x:Key="KenthTab" TargetType="TabItem">
      <Setter Property="Foreground"  Value="#9CA3AF"/>
      <Setter Property="Background"  Value="#100020"/>
      <Setter Property="BorderBrush" Value="#2E1060"/>
      <Setter Property="Padding"     Value="18,10"/>
      <Setter Property="FontSize"    Value="12"/>
      <Setter Property="FontWeight"  Value="SemiBold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TabItem">
            <Border Name="Bd" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="0,0,0,2"
                    Padding="{TemplateBinding Padding}"
                    CornerRadius="4,4,0,0" Margin="2,4,2,0">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                ContentSource="Header" TextBlock.Foreground="{TemplateBinding Foreground}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="Bd" Property="Background"   Value="#1E0040"/>
                <Setter TargetName="Bd" Property="BorderBrush"  Value="#7C3AED"/>
                <Setter Property="Foreground"                   Value="#C4B5FD"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background"   Value="#180035"/>
                <Setter Property="Foreground"                   Value="#A78BFA"/>
                <Setter TargetName="Bd" Property="Cursor"       Value="Hand"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ── Primary purple button ── -->
    <Style x:Key="PurpleBtn" TargetType="Button">
      <Setter Property="Background"   Value="#6D28D9"/>
      <Setter Property="Foreground"   Value="#F3F0FF"/>
      <Setter Property="BorderBrush"  Value="#7C3AED"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding"      Value="14,8"/>
      <Setter Property="Margin"       Value="4,0"/>
      <Setter Property="FontSize"     Value="12"/>
      <Setter Property="FontWeight"   Value="SemiBold"/>
      <Setter Property="Cursor"       Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Name="Bd" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                TextBlock.Foreground="{TemplateBinding Foreground}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background"  Value="#7C3AED"/>
                <Setter TargetName="Bd" Property="BorderBrush" Value="#A78BFA"/>
                <Setter TargetName="Bd" Property="Effect">
                  <Setter.Value>
                    <DropShadowEffect Color="#7C3AED" BlurRadius="10" ShadowDepth="0" Opacity="0.6"/>
                  </Setter.Value>
                </Setter>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="Bd" Property="Background"  Value="#5B21B6"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="Bd" Property="Background"  Value="#2D1B5E"/>
                <Setter Property="Foreground"                  Value="#6B7280"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ── Green button ── -->
    <Style x:Key="GreenBtn" TargetType="Button" BasedOn="{StaticResource PurpleBtn}">
      <Setter Property="Background"  Value="#065F46"/>
      <Setter Property="BorderBrush" Value="#10B981"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background"  Value="#047857"/>
          <Setter Property="BorderBrush" Value="#34D399"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- ── Red button ── -->
    <Style x:Key="RedBtn" TargetType="Button" BasedOn="{StaticResource PurpleBtn}">
      <Setter Property="Background"  Value="#7F1D1D"/>
      <Setter Property="BorderBrush" Value="#EF4444"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background"  Value="#991B1B"/>
          <Setter Property="BorderBrush" Value="#FCA5A5"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- ── Yellow/orange button ── -->
    <Style x:Key="OrangeBtn" TargetType="Button" BasedOn="{StaticResource PurpleBtn}">
      <Setter Property="Background"  Value="#78350F"/>
      <Setter Property="BorderBrush" Value="#F59E0B"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background"  Value="#92400E"/>
          <Setter Property="BorderBrush" Value="#FCD34D"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- ── Outline button ── -->
    <Style x:Key="OutlineBtn" TargetType="Button" BasedOn="{StaticResource PurpleBtn}">
      <Setter Property="Background"  Value="Transparent"/>
      <Setter Property="BorderBrush" Value="#4C1D95"/>
      <Setter Property="Foreground"  Value="#C4B5FD"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background"  Value="#1E0040"/>
          <Setter Property="BorderBrush" Value="#7C3AED"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- ── App card checkbox style ── -->
    <Style x:Key="AppCard" TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="FontSize"   Value="12"/>
      <Setter Property="Padding"    Value="10,8"/>
      <Setter Property="Margin"     Value="4"/>
      <Setter Property="Cursor"     Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border Name="Bd"
                    Background="#160030" BorderBrush="#2E1060" BorderThickness="1"
                    CornerRadius="8" Padding="12,8" Width="175">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="20"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                  <TextBlock Name="AppName" Text="{TemplateBinding Content}"
                             FontWeight="SemiBold" Foreground="#E5E7EB" FontSize="12"
                             TextWrapping="Wrap"/>
                  <TextBlock Name="AppCat"  Text="{TemplateBinding Tag}"
                             Foreground="#6B7280" FontSize="10" Margin="0,2,0,0"/>
                </StackPanel>
                <Border Grid.Column="1" Name="Check"
                        Width="18" Height="18" CornerRadius="4"
                        BorderBrush="#4C1D95" BorderThickness="1.5"
                        Background="Transparent" VerticalAlignment="Center">
                  <TextBlock Name="Tick" Text="" Foreground="#7C3AED"
                             HorizontalAlignment="Center" VerticalAlignment="Center"
                             FontSize="12" FontWeight="Bold" Visibility="Collapsed"/>
                </Border>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd"    Property="Background"   Value="#1E0040"/>
                <Setter TargetName="Bd"    Property="BorderBrush"  Value="#7C3AED"/>
                <Setter TargetName="Check" Property="Background"   Value="#7C3AED"/>
                <Setter TargetName="Check" Property="BorderBrush"  Value="#A78BFA"/>
                <Setter TargetName="Tick"  Property="Visibility"   Value="Visible"/>
                <Setter TargetName="AppName" Property="Foreground" Value="#C4B5FD"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background"      Value="#1A0035"/>
                <Setter TargetName="Bd" Property="BorderBrush"     Value="#6D28D9"/>
                <Setter TargetName="Bd" Property="Effect">
                  <Setter.Value>
                    <DropShadowEffect Color="#7C3AED" BlurRadius="8" ShadowDepth="0" Opacity="0.3"/>
                  </Setter.Value>
                </Setter>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ── Tweak row checkbox ── -->
    <Style x:Key="TweakCheck" TargetType="CheckBox">
      <Setter Property="Foreground"   Value="#E5E7EB"/>
      <Setter Property="FontSize"     Value="12"/>
      <Setter Property="Margin"       Value="0,2"/>
      <Setter Property="Padding"      Value="8,6"/>
      <Setter Property="Cursor"       Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border Name="Bd" Background="Transparent" CornerRadius="6" Padding="8,6">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="24"/>
                  <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border Grid.Column="0" Name="Check"
                        Width="18" Height="18" CornerRadius="4"
                        BorderBrush="#4C1D95" BorderThickness="1.5"
                        Background="Transparent" VerticalAlignment="Center">
                  <TextBlock Name="Tick" Text="v" Foreground="#7C3AED"
                             HorizontalAlignment="Center" VerticalAlignment="Center"
                             FontSize="11" FontWeight="Bold" Visibility="Collapsed"/>
                </Border>
                <ContentPresenter Grid.Column="1" Margin="8,0,0,0"
                                  VerticalAlignment="Center"
                                  TextBlock.Foreground="{TemplateBinding Foreground}"/>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Check" Property="Background"   Value="#7C3AED"/>
                <Setter TargetName="Check" Property="BorderBrush"  Value="#A78BFA"/>
                <Setter TargetName="Tick"  Property="Visibility"   Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background"      Value="#1A0035"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ── ScrollBar style ── -->
    <Style TargetType="ScrollBar">
      <Setter Property="Background" Value="#100020"/>
      <Setter Property="Width"      Value="6"/>
    </Style>

    <!-- ── TextBox style ── -->
    <Style x:Key="SearchBox" TargetType="TextBox">
      <Setter Property="Background"         Value="#160030"/>
      <Setter Property="Foreground"         Value="#D1C4FD"/>
      <Setter Property="BorderBrush"        Value="#3B0D87"/>
      <Setter Property="BorderThickness"    Value="1"/>
      <Setter Property="Padding"            Value="10,7"/>
      <Setter Property="FontSize"           Value="12"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border Name="Bd" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ScrollViewer x:Name="PART_ContentHost" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsFocused" Value="True">
                <Setter TargetName="Bd" Property="BorderBrush" Value="#7C3AED"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ── ComboBox style ── -->
    <Style TargetType="ComboBox">
      <Setter Property="Background"      Value="#160030"/>
      <Setter Property="Foreground"      Value="#D1C4FD"/>
      <Setter Property="BorderBrush"     Value="#3B0D87"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding"         Value="10,6"/>
      <Setter Property="FontSize"        Value="12"/>
    </Style>

    <!-- ── Log TextBox ── -->
    <Style x:Key="LogBox" TargetType="TextBox">
      <Setter Property="Background"      Value="#08000E"/>
      <Setter Property="Foreground"      Value="#A78BFA"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="FontFamily"      Value="Consolas, Cascadia Code, Courier New"/>
      <Setter Property="FontSize"        Value="11"/>
      <Setter Property="IsReadOnly"      Value="True"/>
      <Setter Property="TextWrapping"    Value="Wrap"/>
      <Setter Property="Padding"         Value="10"/>
      <Setter Property="VerticalScrollBarVisibility" Value="Auto"/>
    </Style>

  </Window.Resources>

  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="52"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="140"/>
    </Grid.RowDefinitions>

    <!-- ── Title bar ── -->
    <Border Grid.Row="0" Background="#0D0020" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" Margin="18,0">
          <Border Background="#2D0A6B" CornerRadius="6" Padding="8,4" Margin="0,0,10,0">
            <TextBlock FontFamily="Consolas" FontWeight="Bold" FontSize="14">
              <Run Text="[K]" Foreground="#7C3AED"/>
              <Run Text=" KENTH" Foreground="#C4B5FD"/>
            </TextBlock>
          </Border>
          <TextBlock Foreground="#6D28D9" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center">
            <Run Text="PC TWEAK TOOL" Foreground="#9D5CF0"/>
            <Run Text=" v5.0" Foreground="#4C1D95" FontSize="10"/>
          </TextBlock>
        </StackPanel>
        <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,14,0">
          <TextBlock Name="AdminBadge" VerticalAlignment="Center" FontSize="11" Margin="0,0,14,0"/>
          <Button Name="BtnFullAuto" Content="FULL AUTO MODE" Style="{StaticResource OrangeBtn}" Padding="16,9" FontSize="12"/>
        </StackPanel>
      </Grid>
    </Border>

    <!-- ── Tab control ── -->
    <TabControl Grid.Row="1" Background="#0A0010" BorderThickness="0" TabStripPlacement="Top" Padding="0" Margin="0">
      <TabControl.Resources>
        <Style TargetType="TabPanel">
          <Setter Property="Background" Value="#0D0020"/>
        </Style>
      </TabControl.Resources>

      <!-- TAB 1: INSTALL APPS -->
      <TabItem Header="Install Apps" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <StackPanel Orientation="Horizontal">
              <TextBlock Foreground="#9CA3AF">Select apps and click Install. </TextBlock>
              <TextBlock Foreground="#A78BFA" FontWeight="Bold">80+ apps</TextBlock>
              <TextBlock Foreground="#9CA3AF"> across 8 categories. Powered by winget.</TextBlock>
            </StackPanel>
          </Border>
          <Grid Grid.Row="1" Background="#0E0020" Margin="0">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="180"/>
            </Grid.ColumnDefinitions>
            <TextBox Name="AppSearchBox" Grid.Column="0" Style="{StaticResource SearchBox}"
                     Text="Search apps..." Foreground="#6B7280"
                     Margin="8,6" BorderThickness="1"/>
            <ComboBox Name="CatFilter" Grid.Column="1" Margin="4,6,10,6"
                      Background="#160030" Foreground="#D1C4FD" BorderBrush="#3B0D87"/>
          </Grid>
          <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
            <WrapPanel Name="AppCardPanel" Margin="8,8" Orientation="Horizontal"/>
          </ScrollViewer>
          <Border Grid.Row="3" Background="#0E0020" Padding="12,10" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal">
              <Button Name="BtnInstallSelected"  Content="Install Selected"   Style="{StaticResource GreenBtn}"  Padding="16,9"/>
              <Button Name="BtnInstallAll"       Content="Install All Shown"  Style="{StaticResource PurpleBtn}" Padding="16,9"/>
              <Button Name="BtnSelectAll"        Content="Select All"         Style="{StaticResource OutlineBtn}" Padding="12,9"/>
              <Button Name="BtnClearSelection"   Content="Clear Selection"    Style="{StaticResource OutlineBtn}" Padding="12,9"/>
              <TextBlock Name="SelCountLabel" Foreground="#6B7280" FontSize="11"
                         VerticalAlignment="Center" Margin="12,0,0,0"/>
            </StackPanel>
          </Border>
        </Grid>
      </TabItem>

      <!-- TAB 2: TWEAKS -->
      <TabItem Header="Tweaks" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <TextBlock Foreground="#9CA3AF">Select tweaks to apply. Hover for tooltip info. Restart after applying.</TextBlock>
          </Border>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="TweakPanel" Margin="16,12"/>
          </StackPanel>
          </ScrollViewer>
          <Border Grid.Row="2" Background="#0E0020" Padding="12,10" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal">
              <Button Name="BtnApplyTweaks"  Content="Apply Selected Tweaks" Style="{StaticResource PurpleBtn}" Padding="16,9"/>
              <Button Name="BtnSelectAllTweaks" Content="Select All"         Style="{StaticResource OutlineBtn}" Padding="12,9"/>
              <Button Name="BtnClearTweaks"  Content="Clear All"             Style="{StaticResource OutlineBtn}" Padding="12,9"/>
            </StackPanel>
          </Border>
        </Grid>
      </TabItem>

      <!-- TAB 3: GAMING -->
      <TabItem Header="Gaming / FPS" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <TextBlock Foreground="#9CA3AF">FPS optimization and gaming-specific tweaks. Apply individually or all at once.</TextBlock>
          </Border>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="GamingPanel" Margin="16,12"/>
          </ScrollViewer>
          <Border Grid.Row="2" Background="#0E0020" Padding="12,10" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal">
              <Button Name="BtnApplyGaming"    Content="Apply Selected"   Style="{StaticResource PurpleBtn}" Padding="16,9"/>
              <Button Name="BtnApplyAllGaming" Content="Apply ALL Gaming" Style="{StaticResource OrangeBtn}" Padding="16,9"/>
            </StackPanel>
          </Border>
        </Grid>
      </TabItem>

      <!-- TAB 4: PRIVACY -->
      <TabItem Header="Privacy" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <StackPanel Orientation="Horizontal">
              <TextBlock Foreground="#9CA3AF">Built-in privacy engine — equivalent to </TextBlock>
              <TextBlock Foreground="#A78BFA" FontWeight="Bold">O&amp;O ShutUp10++</TextBlock>
              <TextBlock Foreground="#9CA3AF">. Disables telemetry, tracking, and ads.</TextBlock>
            </StackPanel>
          </Border>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="PrivacyPanel" Margin="16,12"/>
          </ScrollViewer>
          <Border Grid.Row="2" Background="#0E0020" Padding="12,10" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal">
              <Button Name="BtnApplyPrivacy"    Content="Apply Selected"     Style="{StaticResource PurpleBtn}" Padding="16,9"/>
              <Button Name="BtnApplyAllPrivacy" Content="Apply ALL Privacy"  Style="{StaticResource GreenBtn}"  Padding="16,9"/>
            </StackPanel>
          </Border>
        </Grid>
      </TabItem>

      <!-- TAB 5: DEBLOAT -->
      <TabItem Header="Debloat" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <TextBlock Foreground="#9CA3AF">Remove pre-installed Microsoft bloatware. Restorable from the Microsoft Store.</TextBlock>
          </Border>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="DebloatPanel" Margin="16,12"/>
          </ScrollViewer>
          <Border Grid.Row="2" Background="#0E0020" Padding="12,10" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal">
              <Button Name="BtnApplyDebloat"    Content="Remove Selected"   Style="{StaticResource RedBtn}"    Padding="16,9"/>
              <Button Name="BtnApplyAllDebloat" Content="Remove ALL Listed" Style="{StaticResource RedBtn}"    Padding="16,9"/>
            </StackPanel>
          </Border>
        </Grid>
      </TabItem>

      <!-- TAB 6: CACHE -->
      <TabItem Header="Cache Cleaner" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <TextBlock Foreground="#9CA3AF">Clean junk files, browser caches, shader caches, and system temp files.</TextBlock>
          </Border>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="CachePanel" Margin="16,12"/>
          </ScrollViewer>
          <Border Grid.Row="2" Background="#0E0020" Padding="12,10" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal">
              <Button Name="BtnApplyCache"    Content="Clean Selected"  Style="{StaticResource PurpleBtn}" Padding="16,9"/>
              <Button Name="BtnApplyAllCache" Content="Clean ALL"       Style="{StaticResource GreenBtn}"  Padding="16,9"/>
            </StackPanel>
          </Border>
        </Grid>
      </TabItem>

      <!-- TAB 7: SERVICES -->
      <TabItem Header="Services" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <TextBlock Foreground="#9CA3AF">Disable unnecessary Windows services. Reduces RAM usage and background activity.</TextBlock>
          </Border>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="ServicePanel" Margin="16,12"/>
          </ScrollViewer>
          <Border Grid.Row="2" Background="#0E0020" Padding="12,10" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal">
              <Button Name="BtnDisableServices" Content="Disable Selected Services" Style="{StaticResource RedBtn}" Padding="16,9"/>
              <Button Name="BtnDisableAllSvc"   Content="Disable ALL Listed"        Style="{StaticResource RedBtn}" Padding="16,9"/>
            </StackPanel>
          </Border>
        </Grid>
      </TabItem>

      <!-- TAB 8: SYSTEM INFO -->
      <TabItem Header="System Info" Style="{StaticResource KenthTab}">
        <Grid Background="#0A0010">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
          </Grid.RowDefinitions>
          <Border Grid.Row="0" Background="#100020" Padding="16,10" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
            <TextBlock Foreground="#9CA3AF">Live system information — CPU, RAM, GPU, storage, and network.</TextBlock>
          </Border>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="SysInfoPanel" Margin="16,12"/>
          </ScrollViewer>
        </Grid>
      </TabItem>

    </TabControl>

    <!-- ── Log panel ── -->
    <Border Grid.Row="2" Background="#08000E" BorderBrush="#2E1060" BorderThickness="0,1,0,0">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#0D0020" Padding="10,5" BorderBrush="#2E1060" BorderThickness="0,0,0,1">
          <StackPanel Orientation="Horizontal">
            <TextBlock Foreground="#7C3AED" FontFamily="Consolas" FontWeight="Bold" FontSize="11">OUTPUT LOG</TextBlock>
            <Button Name="BtnClearLog" Content="Clear" Style="{StaticResource OutlineBtn}"
                    Padding="8,3" Margin="12,0,0,0" FontSize="10"/>
            <Border Name="ProgressBorder" Background="#160030" CornerRadius="4"
                    Margin="16,0,0,0" Padding="8,3" Visibility="Collapsed">
              <StackPanel Orientation="Horizontal">
                <TextBlock Name="ProgressLabel" Foreground="#A78BFA" FontSize="11" FontFamily="Consolas"
                           VerticalAlignment="Center" Margin="0,0,10,0"/>
                <ProgressBar Name="ProgressBar" Width="200" Height="8"
                             Foreground="#7C3AED" Background="#2E1060"
                             Minimum="0" Maximum="100" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
          </StackPanel>
        </Border>
        <TextBox Name="LogBox" Grid.Row="1" Style="{StaticResource LogBox}"/>
      </Grid>
    </Border>
  </Grid>
</Window>
'@

# ==============================================================================
#  POWERSHELL LOGIC
# ==============================================================================

# Parse XAML
$reader = [System.Xml.XmlNodeReader]::new($XAML)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Helper: get named element
function G($name) { $window.FindName($name) }

# ── Logging ────────────────────────────────────────────────────────────────────
$logBox = G "LogBox"
function Log {
    param([string]$msg, [string]$level = "info")
    $prefix = switch ($level) {
        "ok"   { "[OK]  " }
        "warn" { "[!!]  " }
        "err"  { "[ERR] " }
        default{ "[>>]  " }
    }
    $ts   = (Get-Date).ToString("HH:mm:ss")
    $line = "[$ts] $prefix$msg`n"
    $window.Dispatcher.Invoke([Action]{
        $logBox.AppendText($line)
        $logBox.ScrollToEnd()
    })
}

function SetProg {
    param([int]$pct, [string]$label = "")
    $window.Dispatcher.Invoke([Action]{
        (G "ProgressBorder").Visibility = "Visible"
        (G "ProgressBar").Value   = $pct
        (G "ProgressLabel").Text  = if ($label) { $label } else { "$pct%" }
        if ($pct -ge 100) {
            Start-Sleep -Milliseconds 800
            (G "ProgressBorder").Visibility = "Collapsed"
        }
    })
}

# ── Admin badge ───────────────────────────────────────────────────────────────
$badge = G "AdminBadge"
if ($isAdmin) {
    $badge.Text       = "ADMIN"
    $badge.Foreground = [System.Windows.Media.Brushes]::LimeGreen
} else {
    $badge.Text       = "NOT ADMIN"
    $badge.Foreground = [System.Windows.Media.Brushes]::Tomato
}

# ── Clear log ─────────────────────────────────────────────────────────────────
(G "BtnClearLog").Add_Click({ $logBox.Clear() })

# ==============================================================================
#  TAB 1 — APP INSTALLER
# ==============================================================================
$appCheckboxes = @{}

function Build-AppCards {
    param([string]$filter = "", [string]$catFilter = "All")
    $panel = G "AppCardPanel"
    $panel.Children.Clear()
    $appCheckboxes.Clear()

    $apps = $GuiAppCatalog | Where-Object {
        ($catFilter -eq "All" -or $_.cat -eq $catFilter) -and
        ($filter -eq "" -or $_.name -like "*$filter*" -or $_.cat -like "*$filter*")
    }

    foreach ($app in $apps) {
        $cb = [System.Windows.Controls.CheckBox]::new()
        $cb.Style   = $window.FindResource("AppCard")
        $cb.Content = $app.name
        $cb.Tag     = $app.cat
        $cb.ToolTip = "winget ID: $($app.id)"
        $appCheckboxes[$app.id] = $cb
        $panel.Children.Add($cb) | Out-Null
    }

    $selLabel = G "SelCountLabel"
    $selLabel.Text = "$($apps.Count) apps shown"
}

# Populate category filter
$cf = G "CatFilter"
foreach ($c in $AllCategories) { $cf.Items.Add($c) | Out-Null }
$cf.SelectedIndex = 0
Build-AppCards

# Filter on type/category change
$searchBox = G "AppSearchBox"
$searchBox.Add_GotFocus({
    if ($searchBox.Foreground.ToString() -eq "#FF6B7280") {
        $searchBox.Text = ""; $searchBox.Foreground = [System.Windows.Media.Brushes]::White
    }
})
$searchBox.Add_LostFocus({
    if ($searchBox.Text -eq "") {
        $searchBox.Text = "Search apps..."; $searchBox.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#6B7280")
    }
})
$searchBox.Add_TextChanged({
    $q = if ($searchBox.Text -eq "Search apps...") { "" } else { $searchBox.Text }
    $cat = if ($cf.SelectedIndex -le 0 -or $cf.SelectedValue -eq "All") { "All" } else { $cf.SelectedValue.ToString() }
    Build-AppCards -filter $q -catFilter $cat
})
$cf.Add_SelectionChanged({
    $q = if ($searchBox.Text -eq "Search apps...") { "" } else { $searchBox.Text }
    $cat = if ($cf.SelectedValue -eq $null -or $cf.SelectedValue -eq "All") { "All" } else { $cf.SelectedValue.ToString() }
    Build-AppCards -filter $q -catFilter $cat
})

# Select / clear all
(G "BtnSelectAll").Add_Click({
    foreach ($cb in $appCheckboxes.Values) { $cb.IsChecked = $true }
    (G "SelCountLabel").Text = "$($appCheckboxes.Count) selected"
})
(G "BtnClearSelection").Add_Click({
    foreach ($cb in $appCheckboxes.Values) { $cb.IsChecked = $false }
    (G "SelCountLabel").Text = "0 selected"
})

# ── winget install runner ─────────────────────────────────────────────────────
function Install-AppGui {
    param([string]$id, [string]$name)
    Log "Installing: $name ($id)..." "info"
    try {
        $proc = Start-Process -FilePath "winget" `
            -ArgumentList "install --id `"$id`" --accept-source-agreements --accept-package-agreements --silent --no-upgrade" `
            -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        switch ($proc.ExitCode) {
            0           { Log "$name installed successfully." "ok" }
            -1978335212 { Log "$name already installed — skipped." "info" }
            default     { Log "$name: exit code $($proc.ExitCode)" "warn" }
        }
    } catch {
        Log "ERROR launching winget for ${name}: $_" "err"
    }
}

# Install Selected
(G "BtnInstallSelected").Add_Click({
    $selected = $appCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked }
    if (-not $selected) { Log "No apps selected." "warn"; return }
    if (-not (Test-Winget)) { Log "winget is not installed! Install 'App Installer' from the Microsoft Store." "err"; return }
    Log "Starting installation of $($selected.Count) apps..." "info"
    $total = @($selected).Count; $i = 0
    [System.Threading.Tasks.Task]::Run([Action]{
        foreach ($entry in $selected) {
            $i++
            $appObj = $GuiAppCatalog | Where-Object { $_.id -eq $entry.Key } | Select-Object -First 1
            SetProg ([int]($i / $total * 100)) "Installing $($appObj.name)..."
            Install-AppGui -id $entry.Key -name $appObj.name
        }
        SetProg 100 "Done!"
        Log "All $total apps processed." "ok"
    }) | Out-Null
})

# Install All Shown
(G "BtnInstallAll").Add_Click({
    $visible = @($appCheckboxes.Keys)
    if ($visible.Count -eq 0) { Log "No apps visible." "warn"; return }
    if (-not (Test-Winget)) { Log "winget is not installed!" "err"; return }
    Log "Installing all $($visible.Count) shown apps..." "info"
    $total = $visible.Count; $i = 0
    [System.Threading.Tasks.Task]::Run([Action]{
        foreach ($id in $visible) {
            $i++
            $appObj = $GuiAppCatalog | Where-Object { $_.id -eq $id } | Select-Object -First 1
            SetProg ([int]($i / $total * 100)) "Installing $($appObj.name)..."
            Install-AppGui -id $id -name $appObj.name
        }
        SetProg 100 "Done!"
        Log "All $total apps processed." "ok"
    }) | Out-Null
})

# ==============================================================================
#  CHECK PANEL BUILDER  (Tweaks, Gaming, Privacy, Debloat, Cache, Services)
# ==============================================================================
function Build-CheckPanel {
    param($panel, $defs)
    $panel.Children.Clear()
    foreach ($d in $defs) {
        $sec = $d.section
        if ($sec) {
            $sep = [System.Windows.Controls.TextBlock]::new()
            $sep.Text       = $sec.ToUpper()
            $sep.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#7C3AED")
            $sep.FontWeight = "Bold"
            $sep.FontSize   = 11
            $sep.Margin     = [System.Windows.Thickness]::new(0,14,0,4)
            $panel.Children.Add($sep) | Out-Null

            $line = [System.Windows.Controls.Border]::new()
            $line.Height          = 1
            $line.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#2E1060")
            $line.Margin          = [System.Windows.Thickness]::new(0,0,0,8)
            $panel.Children.Add($line) | Out-Null
            continue
        }

        $cb = [System.Windows.Controls.CheckBox]::new()
        $cb.Style   = $window.FindResource("TweakCheck")
        $cb.Content = $d.label
        $cb.Tag     = $d.key
        if ($d.tooltip) { $cb.ToolTip = $d.tooltip }
        $panel.Children.Add($cb) | Out-Null
    }
}

function Get-CheckedKeys($panel) {
    $panel.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.IsChecked }
}
function Set-AllChecked($panel, [bool]$val) {
    $panel.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] } | ForEach-Object { $_.IsChecked = $val }
}

# ── TWEAK DEFINITIONS ─────────────────────────────────────────────────────────
$TweakDefs = @(
    @{ section = "Performance" }
    @{ label = "Best performance visual effects";   key = "perf";     tooltip = "Disables window animations, shadows, and visual effects for maximum speed." }
    @{ label = "Ultimate Performance power plan";   key = "power";    tooltip = "Unlocks the hidden Ultimate Performance power plan for maximum CPU speed." }
    @{ label = "Disable UI animations";             key = "anim";     tooltip = "Removes taskbar, window minimize/maximize animations." }
    @{ label = "Remove startup delay";              key = "boot";     tooltip = "Removes the 5-second startup delay for apps." }
    @{ label = "Disable hibernation (reclaim disk)"; key = "hiber";   tooltip = "Disables hibernation and removes hiberfil.sys (~4-16 GB freed)." }
    @{ label = "Disable reserved storage (~7 GB)";  key = "reserve";  tooltip = "Frees ~7 GB reserved by Windows Update for updates." }
    @{ label = "Show file extensions";              key = "ext";      tooltip = "Always shows .exe, .zip, .dll etc. in Explorer." }
    @{ label = "Enable long file paths (>260 char)"; key = "path";    tooltip = "Removes the 260-character path limit." }
    @{ label = "Disable sticky/filter/toggle keys"; key = "a11y";     tooltip = "Stops the annoying accessibility key popups when holding Shift." }
    @{ section = "Taskbar & UI" }
    @{ label = "Remove Search box from taskbar";    key = "search";   tooltip = "Hides the taskbar search box." }
    @{ label = "Remove Widgets button";             key = "widgets";  tooltip = "Removes the Widgets (news feed) button from the taskbar." }
    @{ label = "Remove Chat / Teams icon";          key = "chat";     tooltip = "Removes Microsoft Teams Chat from the taskbar." }
    @{ label = "Remove Cortana button";             key = "cortana";  tooltip = "Removes the Cortana button from the taskbar." }
    @{ label = "Disable lock screen ads";           key = "lockads";  tooltip = "Stops Windows Spotlight ads on the lock screen." }
    @{ label = "Disable notification tips";         key = "notif";    tooltip = "Clears Windows tips and system tray suggestions." }
    @{ label = "Disable Windows tips & suggestions"; key = "tips";    tooltip = "Stops app install suggestions in Start Menu and notifications." }
    @{ section = "AI & Bloat" }
    @{ label = "Remove Windows AI / Copilot";       key = "ai";       tooltip = "Disables Copilot and Windows Recall AI features." }
    @{ label = "Disable Cortana completely";        key = "cort2";    tooltip = "Fully disables the Cortana process and registry entries." }
    @{ label = "Disable background apps";           key = "bgapps";   tooltip = "Prevents UWP apps from running in the background." }
    @{ label = "Disable Windows Search indexing";   key = "idx";      tooltip = "Stops the Windows Search indexer service to free RAM." }
)

$GamingDefs = @(
    @{ section = "Core Gaming" }
    @{ label = "Enable Windows Game Mode";          key = "gmode";    tooltip = "Enables auto game mode detection for priority boost." }
    @{ label = "Disable Game DVR / Xbox Capture";   key = "dvr";      tooltip = "Removes Xbox Game Bar overlay — FPS improvement." }
    @{ label = "GPU & CPU Priority for Games";      key = "gprio";    tooltip = "Sets GPU priority 8 and CPU scheduling to High for games." }
    @{ label = "Hardware GPU Scheduling (HAGS)";    key = "hags";     tooltip = "Enables HAGS for reduced GPU latency (Win10 2004+ + modern GPU)." }
    @{ label = "Disable Fullscreen Optimizations";  key = "fso";      tooltip = "Fixes exclusive fullscreen for lower latency." }
    @{ section = "Input & Timing" }
    @{ label = "Raw mouse input (no accel)";        key = "mouse";    tooltip = "Disables pointer precision for raw 1:1 mouse input." }
    @{ label = "Timer resolution 1ms";              key = "timer";    tooltip = "Sets global timer to 1ms for better frame timing." }
    @{ label = "Disable dynamic tick";              key = "dtick";    tooltip = "Disables variable timer tick for more consistent frame times." }
    @{ section = "CPU & System" }
    @{ label = "Unpark CPU cores";                  key = "unpark";   tooltip = "Keeps all CPU cores active at all times." }
    @{ label = "Disable CPU throttling";            key = "throttle"; tooltip = "Disables Windows power throttling for all processes." }
    @{ label = "Process priority boost";            key = "pprio";    tooltip = "Boosts foreground process CPU priority." }
    @{ label = "Network latency pack (TCP gaming)"; key = "netlat";   tooltip = "Tunes TCP/IP stack for lower gaming latency." }
    @{ label = "Disable Xbox hotkeys (Win+G)";      key = "xhot";     tooltip = "Prevents Win+G from triggering Game Bar." }
)

$PrivacyDefs = @(
    @{ section = "Telemetry & Data" }
    @{ label = "Disable telemetry & diagnostics";   key = "tel";      tooltip = "Sets telemetry to Security level and stops DiagTrack." }
    @{ label = "Disable advertising ID";            key = "adid";     tooltip = "Prevents apps from using your advertising identifier." }
    @{ label = "Disable activity history / timeline"; key = "act";    tooltip = "Stops Windows syncing your activity to Microsoft servers." }
    @{ label = "Disable Defender MAPS/telemetry";   key = "deftel";   tooltip = "Stops Defender from sending samples to Microsoft." }
    @{ label = "Disable error reporting (WER)";     key = "wer";      tooltip = "Stops Windows Error Reporting from sending crash data." }
    @{ section = "Location & Sensors" }
    @{ label = "Disable location access";           key = "loc";      tooltip = "Prevents apps from accessing your location." }
    @{ label = "Disable app permissions (cam/mic)"; key = "appperm";  tooltip = "Restricts camera, mic, contacts, and calendar app access." }
    @{ section = "Network & Browser" }
    @{ label = "Disable WiFi Sense";                key = "wifi";     tooltip = "Stops Windows from sharing your WiFi password." }
    @{ label = "Disable LLMNR / NetBIOS";           key = "llmnr";    tooltip = "Removes local network name resolution telemetry." }
    @{ label = "Disable Edge telemetry";            key = "edgetel";  tooltip = "Stops Edge from sending usage data to Microsoft." }
    @{ section = "Search & Cortana" }
    @{ label = "Disable Bing search integration";   key = "bing";     tooltip = "Removes Bing web search from Windows Search." }
    @{ label = "Disable speech data collection";    key = "speech";   tooltip = "Stops speech recognition data being sent to Microsoft." }
    @{ section = "UI & Cloud" }
    @{ label = "Disable clipboard cloud sync";      key = "clip";     tooltip = "Stops clipboard history being synced to Microsoft cloud." }
    @{ label = "Disable tailored experiences";      key = "tailor";   tooltip = "Stops Microsoft using diagnostic data to personalize Windows." }
    @{ label = "Disable Windows tips & features";   key = "wintips";  tooltip = "Disables Start Menu suggestions and Windows feature ads." }
)

$DebloatDefs = @(
    @{ section = "Microsoft Apps" }
    @{ label = "Xbox & Xbox Game Bar";              key = "xbox" }
    @{ label = "Cortana";                           key = "cortan" }
    @{ label = "Mixed Reality & 3D Viewer";         key = "3d" }
    @{ label = "Mail & Calendar";                   key = "mail" }
    @{ label = "Bing News / Weather / Maps";        key = "bing" }
    @{ label = "Solitaire Collection";              key = "sol" }
    @{ section = "Communication" }
    @{ label = "People App";                        key = "people" }
    @{ label = "Skype";                             key = "skype" }
    @{ label = "Microsoft Teams (built-in)";        key = "teams" }
    @{ label = "Phone Link (Your Phone)";           key = "phone" }
    @{ section = "Productivity & Other" }
    @{ label = "Sticky Notes";                      key = "sticky" }
    @{ label = "Feedback Hub";                      key = "fb" }
    @{ label = "Get Help / Tips";                   key = "help" }
    @{ label = "Clipchamp Video Editor";            key = "clip" }
    @{ label = "Microsoft To Do / Whiteboard";      key = "todo" }
    @{ label = "Groove / Zune Music & Video";       key = "zune" }
    @{ label = "OneNote (UWP)";                     key = "onenote" }
    @{ label = "Paint 3D";                          key = "paint3d" }
    @{ label = "Power Automate";                    key = "pa" }
    @{ label = "Family Safety";                     key = "fam" }
    @{ label = "Quick Assist";                      key = "qa" }
    @{ label = "Alarms & Clock";                    key = "alarms" }
    @{ label = "Windows AI / Recall / Copilot";     key = "winai" }
    @{ label = "Microsoft News";                    key = "news" }
    @{ label = "Office Hub";                        key = "ohub" }
)

$CacheDefs = @(
    @{ section = "Windows System" }
    @{ label = "User Temp folder (%TEMP%)";         key = "atemp" }
    @{ label = "Windows Temp (C:\\Windows\\Temp)";  key = "wtemp" }
    @{ label = "Windows Prefetch";                  key = "prefetch" }
    @{ label = "Windows Error Reports (WER)";       key = "wer" }
    @{ label = "Thumbnail cache";                   key = "thumb" }
    @{ label = "Icon cache";                        key = "icons" }
    @{ label = "Recent files list";                 key = "recent" }
    @{ label = "Windows Update cache";              key = "wucache" }
    @{ label = "DNS cache (flush)";                 key = "dns" }
    @{ label = "Recycle Bin";                       key = "bin" }
    @{ label = "Delivery Optimization cache";       key = "delopt" }
    @{ label = "Old Windows installation (Windows.old)"; key = "winold" }
    @{ section = "Browsers" }
    @{ label = "Chrome cache";                      key = "chrome" }
    @{ label = "Edge cache";                        key = "edge" }
    @{ label = "Firefox cache";                     key = "firefox" }
    @{ section = "Apps" }
    @{ label = "Discord cache";                     key = "discord" }
    @{ label = "Spotify cache";                     key = "spotify" }
    @{ label = "Steam shader cache";                key = "steam" }
    @{ label = "NVIDIA shader cache";               key = "nvidia" }
    @{ label = "AMD shader cache";                  key = "amd" }
)

$ServiceDefs = @(
    @{ section = "Telemetry Services" }
    @{ label = "DiagTrack (Connected User Experiences)"; key = "DiagTrack" }
    @{ label = "dmwappushservice (WAP Push)";            key = "dmwappushservice" }
    @{ label = "WerSvc (Error Reporting)";               key = "WerSvc" }
    @{ section = "Xbox Services" }
    @{ label = "XblAuthManager";                         key = "XblAuthManager" }
    @{ label = "XblGameSave";                            key = "XblGameSave" }
    @{ label = "XboxNetApiSvc";                          key = "XboxNetApiSvc" }
    @{ label = "XboxGipSvc";                             key = "XboxGipSvc" }
    @{ section = "Microsoft Edge Services" }
    @{ label = "edgeupdate";                             key = "edgeupdate" }
    @{ label = "edgeupdatem";                            key = "edgeupdatem" }
    @{ label = "MicrosoftEdgeElevationService";          key = "MicrosoftEdgeElevationService" }
    @{ section = "Other Junk Services" }
    @{ label = "MapsBroker (Downloaded Maps)";           key = "MapsBroker" }
    @{ label = "lfsvc (Geolocation)";                    key = "lfsvc" }
    @{ label = "Fax";                                    key = "Fax" }
    @{ label = "RemoteRegistry";                         key = "RemoteRegistry" }
    @{ label = "RetailDemo";                             key = "RetailDemo" }
    @{ label = "SysMain (Superfetch)";                   key = "SysMain" }
    @{ label = "WMPNetworkSvc (Media Player Sharing)";   key = "WMPNetworkSvc" }
    @{ label = "TabletInputService";                     key = "TabletInputService" }
    @{ label = "icssvc (Mobile Hotspot)";                key = "icssvc" }
    @{ label = "SharedAccess (ICS)";                     key = "SharedAccess" }
)

# ── Build all panels ──────────────────────────────────────────────────────────
Build-CheckPanel (G "TweakPanel")   $TweakDefs
Build-CheckPanel (G "GamingPanel")  $GamingDefs
Build-CheckPanel (G "PrivacyPanel") $PrivacyDefs
Build-CheckPanel (G "DebloatPanel") $DebloatDefs
Build-CheckPanel (G "CachePanel")   $CacheDefs
Build-CheckPanel (G "ServicePanel") $ServiceDefs

# Select All / Clear helpers per tab
(G "BtnSelectAllTweaks").Add_Click({ Set-AllChecked (G "TweakPanel") $true })
(G "BtnClearTweaks").Add_Click({ Set-AllChecked (G "TweakPanel") $false })

# ==============================================================================
#  ACTION MAPS — key → scriptblock
# ==============================================================================

$TweakActions = @{
    "perf"    = { Invoke-PerfTweak }
    "power"   = { Invoke-UltimatePower }
    "anim"    = { Invoke-NoAnimations }
    "boot"    = { Invoke-DisableStartupDelay }
    "hiber"   = { Invoke-DisableHibernation }
    "reserve" = { Invoke-ReservedStorage }
    "ext"     = { Invoke-FileExtensions }
    "path"    = { Invoke-LongFilePaths }
    "a11y"    = { Invoke-DisableAccessibilityKeys }
    "search"  = { Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" DWord 0 }
    "widgets" = { Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" DWord 0; Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" DWord 0 }
    "chat"    = { Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" DWord 0 }
    "cortana" = { Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCortanaButton" DWord 0 }
    "lockads" = { Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" DWord 0 }
    "notif"   = { Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" DWord 0 }
    "tips"    = { Invoke-DisableTips }
    "ai"      = { Invoke-RemoveWinAI }
    "cort2"   = { Invoke-DisableCortana }
    "bgapps"  = { Invoke-DisableBgApps }
    "idx"     = { Invoke-DisableSearch }
}

$GamingActions = @{
    "gmode"   = { Invoke-GameMode }
    "dvr"     = { Invoke-GameBarTweak }
    "gprio"   = { Invoke-GamePriority }
    "hags"    = { Invoke-HAGS }
    "fso"     = { Invoke-FullscreenOpt }
    "mouse"   = { Invoke-RawMouse }
    "timer"   = { Invoke-TimerResolution }
    "dtick"   = { Invoke-DynamicTick }
    "unpark"  = { Invoke-CPUUnpark }
    "throttle"= { Invoke-DisableCPUThrottle }
    "pprio"   = { Invoke-ProcessPriorityBoost }
    "netlat"  = { Invoke-NetworkLatencyPack }
    "xhot"    = { Invoke-DisableXboxHotkeys }
}

$PrivacyActions = @{
    "tel"     = { Set-Telemetry }
    "adid"    = { Set-AdvertisingPrivacy }
    "act"     = { Set-ActivityHistory }
    "deftel"  = { Set-DefenderTelemetry }
    "wer"     = { Set-ErrorReporting }
    "loc"     = { Set-LocationPrivacy }
    "appperm" = { Set-AppPermissions }
    "wifi"    = { Invoke-DisableWiFiSense }
    "llmnr"   = { Invoke-DisableLLMNR }
    "edgetel" = { Set-BrowserPrivacy }
    "bing"    = { Set-SearchPrivacy }
    "speech"  = { Set-RegValue "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" DWord 0 }
    "clip"    = { Set-ClipboardPrivacy }
    "tailor"  = { Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" DWord 0 }
    "wintips" = { Set-WindowsFeaturePrivacy }
}

$DebloatPkgMap = @{
    "xbox"    = @("Xbox","XboxGameCallableUI","XboxIdentityProvider","XboxTcUiFramework")
    "cortan"  = @("Microsoft.549981C3F5F10","Cortana")
    "3d"      = @("MixedReality","Microsoft3DViewer","Print3D")
    "mail"    = @("windowscommunicationsapps")
    "bing"    = @("BingNews","BingWeather","WindowsMaps","BingFinance")
    "sol"     = @("MicrosoftSolitaireCollection")
    "people"  = @("People")
    "skype"   = @("SkypeApp","Microsoft.Skype")
    "teams"   = @("Teams","MicrosoftTeams")
    "phone"   = @("YourPhone","PhoneLink")
    "sticky"  = @("MicrosoftStickyNotes")
    "fb"      = @("WindowsFeedbackHub")
    "help"    = @("GetHelp","Microsoft.Tips")
    "clip"    = @("Clipchamp","Microsoft.Clipchamp")
    "todo"    = @("Microsoft.Todos","Microsoft.Whiteboard")
    "zune"    = @("ZuneMusic","ZuneVideo","Microsoft.ZuneMusic")
    "onenote" = @("OneNote","Microsoft.OneConnect")
    "paint3d" = @("MSPaint","Print3D")
    "pa"      = @("PowerAutomateDesktop")
    "fam"     = @("MicrosoftFamily")
    "qa"      = @("QuickAssist")
    "alarms"  = @("WindowsAlarms")
    "winai"   = @("Microsoft.Windows.AI.Copilot","Windows.Ai.Studio","Microsoft.Copilot")
    "news"    = @("Microsoft.News","BingNews")
    "ohub"    = @("MicrosoftOfficeHub")
}

$CacheActions = @{
    "atemp"   = { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "wtemp"   = { Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "prefetch"= { Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "wer"     = { Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "thumb"   = { Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue }
    "icons"   = { Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue }
    "recent"  = { Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -ErrorAction SilentlyContinue }
    "wucache" = { Stop-Service wuauserv -Force -ErrorAction SilentlyContinue; Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue; Start-Service wuauserv -ErrorAction SilentlyContinue }
    "dns"     = { ipconfig /flushdns | Out-Null }
    "bin"     = { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
    "delopt"  = { Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "winold"  = { Remove-Item "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue }
    "chrome"  = { Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "edge"    = { Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "firefox" = { Get-ChildItem "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item "$($_.FullName)\cache2\*" -Recurse -Force -ErrorAction SilentlyContinue } }
    "discord" = { Remove-Item "$env:APPDATA\discord\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "spotify" = { Remove-Item "$env:LOCALAPPDATA\Spotify\Data\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "steam"   = { Remove-Item "C:\Program Files (x86)\Steam\steamapps\shadercache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "nvidia"  = { Remove-Item "$env:LOCALAPPDATA\NVIDIA\DXCache\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item "$env:LOCALAPPDATA\NVIDIA\GLCache\*" -Recurse -Force -ErrorAction SilentlyContinue }
    "amd"     = { Remove-Item "$env:LOCALAPPDATA\AMD\DXCache\*" -Recurse -Force -ErrorAction SilentlyContinue }
}

# ── Generic panel Apply button handler ───────────────────────────────────────
function Invoke-PanelApply {
    param($panel, $actionMap, $label)
    $checked = Get-CheckedKeys $panel
    if (-not $checked) { Log "No $label selected." "warn"; return }
    $items = @($checked)
    [System.Threading.Tasks.Task]::Run([Action]{
        $i = 0; $total = $items.Count
        foreach ($cb in $items) {
            $i++; $key = $cb.Tag.ToString()
            SetProg ([int]($i / $total * 100)) "Applying $label $i/$total..."
            Log "Applying: $($cb.Content)" "info"
            $action = $actionMap[$key]
            if ($action) { try { & $action } catch { Log "Error on $key : $_" "err" } }
            else { Log "No action mapped for key: $key" "warn" }
        }
        SetProg 100 "Done!"
        Log "Applied $total $label." "ok"
    }) | Out-Null
}

# ── Tweak buttons ─────────────────────────────────────────────────────────────
(G "BtnApplyTweaks").Add_Click({ Invoke-PanelApply (G "TweakPanel") $TweakActions "tweaks" })

# ── Gaming buttons ────────────────────────────────────────────────────────────
(G "BtnApplyGaming").Add_Click({ Invoke-PanelApply (G "GamingPanel") $GamingActions "gaming tweaks" })
(G "BtnApplyAllGaming").Add_Click({
    Set-AllChecked (G "GamingPanel") $true
    Invoke-PanelApply (G "GamingPanel") $GamingActions "gaming tweaks"
})

# ── Privacy buttons ───────────────────────────────────────────────────────────
(G "BtnApplyPrivacy").Add_Click({ Invoke-PanelApply (G "PrivacyPanel") $PrivacyActions "privacy tweaks" })
(G "BtnApplyAllPrivacy").Add_Click({
    Set-AllChecked (G "PrivacyPanel") $true
    Invoke-PanelApply (G "PrivacyPanel") $PrivacyActions "privacy tweaks"
})

# ── Debloat buttons ───────────────────────────────────────────────────────────
function Invoke-DebloatApply($panel) {
    $checked = Get-CheckedKeys $panel
    if (-not $checked) { Log "No apps selected to remove." "warn"; return }
    $items = @($checked)
    [System.Threading.Tasks.Task]::Run([Action]{
        $i = 0; $total = $items.Count
        foreach ($cb in $items) {
            $i++; $key = $cb.Tag.ToString()
            SetProg ([int]($i / $total * 100)) "Removing $i/$total..."
            Log "Removing: $($cb.Content)" "info"
            $pkgs = $DebloatPkgMap[$key]
            if ($pkgs) { foreach ($p in $pkgs) { Remove-AppxSilent $p } }
        }
        SetProg 100 "Done!"
        Log "Removed $total apps." "ok"
    }) | Out-Null
}
(G "BtnApplyDebloat").Add_Click({ Invoke-DebloatApply (G "DebloatPanel") })
(G "BtnApplyAllDebloat").Add_Click({
    Set-AllChecked (G "DebloatPanel") $true
    Invoke-DebloatApply (G "DebloatPanel")
})

# ── Cache buttons ─────────────────────────────────────────────────────────────
(G "BtnApplyCache").Add_Click({ Invoke-PanelApply (G "CachePanel") $CacheActions "cache types" })
(G "BtnApplyAllCache").Add_Click({
    Set-AllChecked (G "CachePanel") $true
    Invoke-PanelApply (G "CachePanel") $CacheActions "cache types"
})

# ── Service buttons ───────────────────────────────────────────────────────────
function Invoke-ServiceApply($panel, $all) {
    if ($all) { Set-AllChecked $panel $true }
    $checked = Get-CheckedKeys $panel
    if (-not $checked) { Log "No services selected." "warn"; return }
    $items = @($checked)
    [System.Threading.Tasks.Task]::Run([Action]{
        $i = 0; $total = $items.Count
        foreach ($cb in $items) {
            $i++; $svcName = $cb.Tag.ToString()
            SetProg ([int]($i / $total * 100)) "Disabling $svcName..."
            Log "Disabling: $svcName" "info"
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            Set-Service  -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
        }
        SetProg 100 "Done!"
        Log "Disabled $total services." "ok"
    }) | Out-Null
}
(G "BtnDisableServices").Add_Click({ Invoke-ServiceApply (G "ServicePanel") $false })
(G "BtnDisableAllSvc").Add_Click({ Invoke-ServiceApply (G "ServicePanel") $true })

# ── FULL AUTO ─────────────────────────────────────────────────────────────────
(G "BtnFullAuto").Add_Click({
    $ans = [System.Windows.MessageBox]::Show(
        "FULL AUTO MODE will apply all tweaks, privacy hardening, cache cleaning, and service disabling.`n`nA restart is required after. Continue?",
        "Kenth — Full Auto Mode",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($ans -ne "Yes") { return }

    Log "FULL AUTO MODE starting..." "info"
    [System.Threading.Tasks.Task]::Run([Action]{
        $step = 0; $total = 14
        function FA($label,$action) {
            $script:step++
            SetProg ([int]($script:step/$total*100)) "Step $($script:step)/$total..."
            Log "[$($script:step)/$total] $label" "info"
            try { & $action } catch { Log "Error in step $($script:step): $_" "warn" }
        }
        FA "Performance tweaks"   { Invoke-PerfTweak; Invoke-NoAnimations; Invoke-DisableStartupDelay; Invoke-LongFilePaths; Invoke-BestPerfVisuals }
        FA "Taskbar & UI cleanup" { Invoke-TaskbarTweak; Invoke-LockScreenTweak; Invoke-NotifTweak; Invoke-DisableTips }
        FA "Remove Windows AI"    { Invoke-RemoveWinAI; Invoke-DisableCortana }
        FA "Privacy engine"       { Set-Telemetry; Set-AdvertisingPrivacy; Set-ActivityHistory; Set-SearchPrivacy; Set-WindowsFeaturePrivacy; Set-DefenderTelemetry }
        FA "Remove bloatware"     { foreach ($k in $DebloatPkgMap.Keys) { foreach ($p in $DebloatPkgMap[$k]) { Remove-AppxSilent $p } } }
        FA "FPS & gaming tweaks"  { Invoke-GameMode; Invoke-GameBarTweak; Invoke-GamePriority; Invoke-HAGS; Invoke-FullscreenOpt; Invoke-RawMouse }
        FA "Timer & CPU tweaks"   { Invoke-TimerResolution; Invoke-CPUUnpark; Invoke-DisableCPUThrottle; Invoke-ProcessPriorityBoost; Invoke-DynamicTick }
        FA "Network stack tuning" { Invoke-TCPTuning; Invoke-DisableNagle }
        FA "Hardware tweaks"      { Invoke-DisablePowerThrottle; Invoke-NTFSOptimize; Invoke-DisablePagingExec }
        FA "Disable services"     { foreach ($s in $KenthDisableList) { Stop-Service $s.name -Force -ErrorAction SilentlyContinue; Set-Service $s.name -StartupType Disabled -ErrorAction SilentlyContinue } }
        FA "Background apps"      { Invoke-DisableBgApps; Invoke-DisableAutoPlay }
        FA "Ultimate power plan"  { Invoke-UltimatePower }
        FA "Clear cache"          { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; ipconfig /flushdns | Out-Null }
        FA "RAM tweaks"           { Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" DWord 1 }

        SetProg 100 "DONE"
        Log "FULL AUTO MODE complete! Restart your PC for full effect." "ok"
        $window.Dispatcher.Invoke([Action]{
            [System.Windows.MessageBox]::Show(
                "All done! Restart your PC for best results.",
                "Kenth — Done!",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
        })
    }) | Out-Null
})

# ==============================================================================
#  SYSTEM INFO TAB
# ==============================================================================
function Build-SysInfo {
    $panel = G "SysInfoPanel"
    $panel.Children.Clear()

    function AddSIRow($label, $value, $valueColor = "#E5E7EB") {
        $row = [System.Windows.Controls.Grid]::new()
        $c1 = [System.Windows.Controls.ColumnDefinition]::new(); $c1.Width = [System.Windows.GridLength]::new(180)
        $c2 = [System.Windows.Controls.ColumnDefinition]::new(); $c2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $row.ColumnDefinitions.Add($c1); $row.ColumnDefinitions.Add($c2)
        $row.Margin = [System.Windows.Thickness]::new(0,2,0,2)

        $lbl = [System.Windows.Controls.TextBlock]::new()
        $lbl.Text = $label; $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#7C3AED")
        $lbl.FontSize = 12; $lbl.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($lbl, 0); $row.Children.Add($lbl) | Out-Null

        $val = [System.Windows.Controls.TextBlock]::new()
        $val.Text = $value.ToString(); $val.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($valueColor)
        $val.FontSize = 12; $val.VerticalAlignment = "Center"; $val.TextWrapping = "Wrap"
        [System.Windows.Controls.Grid]::SetColumn($val, 1); $row.Children.Add($val) | Out-Null

        $panel.Children.Add($row) | Out-Null
    }
    function AddSISect($title) {
        $t = [System.Windows.Controls.TextBlock]::new()
        $t.Text = $title.ToUpper(); $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#9D5CF0")
        $t.FontWeight = "Bold"; $t.FontSize = 11; $t.Margin = [System.Windows.Thickness]::new(0,14,0,4)
        $panel.Children.Add($t) | Out-Null
        $sep = [System.Windows.Controls.Border]::new()
        $sep.Height = 1; $sep.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#2E1060")
        $sep.Margin = [System.Windows.Thickness]::new(0,0,0,8)
        $panel.Children.Add($sep) | Out-Null
    }

    try {
        $cs  = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
        $os  = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop
        $cpu = Get-WmiObject Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $gpu = Get-WmiObject Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
        $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
        $bios  = Get-WmiObject Win32_BIOS -ErrorAction SilentlyContinue
        $net   = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue | Select-Object -First 1

        $ramGB  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedGB = [math]::Round($ramGB - $freeGB, 2)
        $usedPct = [math]::Round($usedGB / $ramGB * 100)
        $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)

        AddSISect "System"
        AddSIRow "Hostname"     $env:COMPUTERNAME
        AddSIRow "OS"           $os.Caption
        AddSIRow "Build"        $os.Version
        AddSIRow "Architecture" $os.OSArchitecture
        AddSIRow "Uptime"       "$([int]$uptime.TotalDays)d $($uptime.Hours)h $($uptime.Minutes)m"
        AddSIRow "Admin"        $(if ($isAdmin) { "YES (Administrator)" } else { "NO (Limited)" }) $(if ($isAdmin) { "#10B981" } else { "#EF4444" })
        AddSIRow "winget"       $(if (Test-Winget) { "Installed and ready" } else { "Not installed" }) $(if (Test-Winget) { "#10B981" } else { "#F59E0B" })

        AddSISect "Processor"
        AddSIRow "CPU"          $cpu.Name.Trim()
        AddSIRow "Cores"        "$($cpu.NumberOfCores) physical / $($cpu.NumberOfLogicalProcessors) logical"
        AddSIRow "Base Speed"   "$($cpu.MaxClockSpeed) MHz"

        AddSISect "Memory"
        AddSIRow "Total RAM"    "$ramGB GB"
        AddSIRow "Used"         "$usedGB GB  ($usedPct%)" $(if ($usedPct -gt 85) { "#EF4444" } elseif ($usedPct -gt 60) { "#F59E0B" } else { "#10B981" })
        AddSIRow "Free"         "$freeGB GB"

        if ($gpu) {
            AddSISect "GPU"
            AddSIRow "GPU"      $gpu.Name
            $vramMB = [math]::Round($gpu.AdapterRAM / 1MB)
            if ($vramMB -gt 0) { AddSIRow "VRAM" "$vramMB MB" }
        }

        if ($bios) {
            AddSISect "Motherboard / BIOS"
            AddSIRow "BIOS Vendor"  $bios.Manufacturer
            AddSIRow "BIOS Version" $bios.SMBIOSBIOSVersion
            AddSIRow "Board"        $cs.Manufacturer + " " + $cs.Model
        }

        if ($disks) {
            AddSISect "Storage"
            foreach ($d in $disks) {
                $totalGB = [math]::Round($d.Size / 1GB, 1)
                $freeGBd = [math]::Round($d.FreeSpace / 1GB, 1)
                $usedGBd = [math]::Round(($d.Size - $d.FreeSpace) / 1GB, 1)
                $pct     = if ($d.Size -gt 0) { [math]::Round($usedGBd / $totalGB * 100) } else { 0 }
                $col     = if ($pct -gt 85) { "#EF4444" } elseif ($pct -gt 60) { "#F59E0B" } else { "#E5E7EB" }
                AddSIRow "$($d.DeviceID) $($d.VolumeName)" "$usedGBd GB / $totalGB GB  ($pct% used)" $col
            }
        }

        if ($net) {
            AddSISect "Network"
            AddSIRow "Adapter"     $net.Description
            AddSIRow "IP Address"  ($net.IPAddress -join ", ")
            AddSIRow "DNS"         ($net.DNSServerSearchOrder -join ", ")
        }
    } catch {
        AddSIRow "Error" "Could not load system info: $_" "#EF4444"
    }
}

Build-SysInfo

# ── Initial log ───────────────────────────────────────────────────────────────
Log "Kenth PC Tweak Tool v5.0 — github.com/kenthvlr/Kenth" "ok"
Log "Admin: $isAdmin  |  winget: $(Test-Winget)  |  Windows: $([System.Environment]::OSVersion.Version)" "info"

# ── Show window ───────────────────────────────────────────────────────────────
$window.ShowDialog() | Out-Null
