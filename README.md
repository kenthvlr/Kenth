# KENTH PC Tweak Tool v5.0

A fully-featured Windows optimization tool with a clean WPF GUI and console fallback.
Purple/black theme, hover effects, and fully working winget app installer.

---

## Quick Start

### GUI Mode (Recommended)
```powershell
iwr -useb https://raw.githubusercontent.com/kenthvlr/Kenth/main/KenthUI.ps1 | iex
```
Or if you've downloaded the files:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File KenthUI.ps1
```

### Console Mode
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Kenth.ps1
```

> **Run as Administrator** for all tweaks to work correctly.

---

## File Structure

```
Kenth/
├── KenthUI.ps1           # GUI entry point (WPF — purple/black theme)
├── Kenth.ps1             # Console / CLI entry point
├── README.md
├── LICENSE
├── functions/
│   ├── core.ps1          # Shared helpers, colors, admin elevation
│   ├── installer.ps1     # App installer (winget, 100+ apps, 12 categories)
│   ├── tweaks.ps1        # Windows tweaks (performance, UI, power)
│   ├── gaming.ps1        # FPS & gaming optimization tweaks
│   ├── privacy.ps1       # Privacy engine (ShutUp10++ equivalent)
│   ├── debloat.ps1       # Bloatware removal (30 UWP apps)
│   ├── network.ps1       # Network tweaks (TCP, DNS, Nagle, QoS)
│   ├── services.ps1      # Service manager
│   ├── cache.ps1         # Cache cleaner (20+ types)
│   ├── hardware.ps1      # Hardware & advanced tweaks
│   ├── sysinfo.ps1       # System info display
│   ├── edge.ps1          # Microsoft Edge removal/tweaks
│   ├── onedrive.ps1      # OneDrive removal/disable
│   └── menu.ps1          # Console main menu + Full Auto Mode
└── docs/
    ├── FEATURES.md
    ├── CONTRIBUTING.md
    └── TROUBLESHOOTING.md
```

---

## Features

### Install Apps (winget powered)
- 100+ apps across 12 categories
- App cards with checkboxes — select any combination
- Search and filter by category
- Auto-installs winget if not present
- Categories: Browsers, Communication, Gaming, Media, Development, Utilities, Security, Office, Image/Design, System Tools, Network/Remote, Drivers/Hardware

### Windows Tweaks
- Performance: visual effects, animations, startup delay, reserved storage
- Taskbar: remove search box, widgets, chat, Cortana button
- Power: Ultimate Performance plan (hidden), hibernation disable
- UI: file extensions, long paths, accessibility key popups

### FPS & Gaming
- Game Mode, HAGS (Hardware GPU Scheduling)
- Disable Game DVR / Xbox capture overlay
- Raw mouse input, 1ms timer resolution
- CPU unparking, dynamic tick disable
- Network latency pack, TCP gaming tuning

### Privacy Engine (ShutUp10++ built-in)
- 15 privacy categories
- Telemetry, DiagTrack, advertising ID, location, activity history
- Search privacy, clipboard sync, network (WiFi Sense, LLMNR)
- Edge & browser telemetry, Defender MAPS
- Apply all or individually

### Debloat
- 30 removable Windows UWP apps
- Xbox, Cortana, Bing apps, Mail, Teams, Skype, Solitaire, and more
- Restorable from Microsoft Store

### Cache Cleaner
- 20 cache types: User Temp, Windows Temp, Prefetch, WER
- Browser caches: Chrome, Edge, Firefox
- App caches: Discord, Spotify
- Shader caches: Steam, NVIDIA, AMD
- Recycle Bin, DNS flush, Windows Update cache

### Services Manager
- Disable 24 junk/telemetry services
- Manual stop/disable/enable/search
- View running services

### Hardware & Advanced
- NTFS optimization (last-access, 8.3 names)
- Disable power throttling
- SSD TRIM, memory compression toggle
- RAM: paging executive, page file at shutdown

### Edge & OneDrive
- Edge privacy hardening, pre-launch disable
- Edge removal (AppX + registry)
- OneDrive complete uninstall or startup disable

### System Info
- CPU, RAM, GPU, storage, network details
- Live admin and winget status

---

## Requirements

- Windows 10 / 11
- PowerShell 5.1+ (built-in on Windows 10/11)
- Administrator rights (recommended)
- winget (App Installer) for the app installer tab — auto-detected

---

## Uploading to GitHub

1. Upload the entire `Kenth/` folder to your GitHub repo
2. Make sure `KenthUI.ps1` is at the **root** of the repo
3. The one-liner will work:
   ```powershell
   iwr -useb https://raw.githubusercontent.com/YOUR_USERNAME/Kenth/main/KenthUI.ps1 | iex
   ```
   > Note: When running via `iex`, the `functions/` folder won't be available.
   > The GUI works standalone. For the console mode (`Kenth.ps1`), run from a local copy.

---

## License

MIT License — see `LICENSE` file.
