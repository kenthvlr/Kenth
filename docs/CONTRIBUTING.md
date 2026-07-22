# Contributing to Kenth

Thanks for wanting to contribute!

## How to Add a New App to the Installer

Edit `functions/installer.ps1`:

```powershell
"N" = @{ name = "App Display Name"; id = "Publisher.AppName" }
```

Find the correct winget ID with:
```powershell
winget search "app name"
```

Also add it to `KenthUI.ps1` in the `$GuiAppCatalog` array:
```powershell
@{ cat="Category"; name="App Name"; id="Publisher.AppId" }
```

## How to Add a New Tweak

1. Add the function to the relevant `functions/*.ps1` file
2. Add an entry to the menu array in `functions/menu.ps1`
3. Add it to the GUI definitions in `KenthUI.ps1` (`$TweakDefs` or `$GamingDefs`)
4. Add the key → action mapping in `$TweakActions` or `$GamingActions`

## Code Style

- Use `Set-RegValue` helper instead of raw `Set-ItemProperty`
- Use `Remove-AppxSilent` for app removal
- Always wrap registry/system calls in `try { } catch { }`
- Use the log functions: `Log "message" "ok"/"warn"/"err"/"info"`
- Indent with 4 spaces

## File Encoding

**All `.ps1` files MUST be saved as UTF-8** (with or without BOM).
Using ANSI encoding breaks Unicode characters in the WPF UI.

## Submitting a PR

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-tweak`
3. Make your changes
4. Test on Windows 10 and Windows 11
5. Submit a pull request with a clear description
