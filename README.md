Here is the complete, production-ready README.md file for your OrbitDL.Gen repository, formatted with both the one-line irm installer option and the direct codeblock installation method:

# OrbitDL.Gen<p align="center">
  <strong>Orbit Direct Download Link Generator</strong><br>
  <em>A fast, native terminal utility for Windows to host files and folders with instant direct download links.</em></p>
<p align="center">
  <img src="https://shields.io" alt="Platform" />
  <img src="https://shields.io" alt="PowerShell" />
  <img src="https://shields.io" alt="License" /></p>
---## ⚡ Overview
**OrbitDL.Gen** is a lightweight, standalone command-line tool designed for PowerShell and Windows Terminal. It allows you to pipe files or full directories to secure cloud backends and generates clean direct download links instantly—bypassing preview pages, speed throttles, and ad walls.

The tool includes directory auto-archiving, automatic clipboard integration, a 3-line stylized terminal dashboard, persistent settings, and an upload history logger.
---## 📥 Installation
Choose **one** of the two installation methods below:
### Option 1: One-Line Web Installer (Recommended)
Open **PowerShell as an Administrator** and run:
```powershell
irm https://raw.githubusercontent.com/Yuganshraj6/OrbitDL.Gen/main/Install-OrbitDLGen.ps1 | iex
```
---### Option 2: Standalone Codeblock (Manual Setup)
If you prefer not to pull remote scripts, open **PowerShell as an Administrator**, paste the following block, and press **Enter**:

```powershell
# 1. Create installation directory
$InstallDir = "$env:USERPROFILE\OrbitDL.Gen"
If (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }

# 2. Write engine core
$PSCoreContent = @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$PathArgs)
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$HistoryPath = Join-Path $PSScriptRoot "history.json"

$DefaultConfig = @{ Backend = "transfer.sh"; AutoCopyClipboard = $true; ClearScreen = $true; DefaultArchive = "zip" }
if (Test-Path $ConfigPath) {
    try { $Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json -AsHashtable } catch { $Config = $DefaultConfig }
} else { $Config = $DefaultConfig; $Config | ConvertTo-Json -Depth 3 | Set-Content -Path $ConfigPath -Encoding UTF8 }

function Save-Config { $Config | ConvertTo-Json -Depth 3 | Set-Content -Path $ConfigPath -Encoding UTF8 }

function Log-History ($Name, $Url, $Size) {
    $History = @()
    if (Test-Path $HistoryPath) { try { $History = @(Get-Content -Raw -Path $HistoryPath | ConvertFrom-Json) } catch { $History = @() } }
    $History += [PSCustomObject]@{ Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Name = $Name; Size = $Size; Url = $Url }
    $History | ConvertTo-Json -Depth 3 | Set-Content -Path $HistoryPath -Encoding UTF8
}

function Show-Banner {
    if ($Config.ClearScreen) { Clear-Host }
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                  ORBIT DIRECT DOWNLOAD LINK GENERATOR                          " -ForegroundColor Yellow
    Write-Host "                           [ OrbitDL.Gen v4.0 ]                                 " -ForegroundColor Magenta
    Write-Host "================================================================================" -ForegroundColor Cyan
}

function Show-HelpGuide {
    Show-Banner
    Write-Host " [?] CLI QUICK USAGE GUIDE" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " Syntax:" -ForegroundColor Yellow
    Write-Host "   odlg <file or folder path>" -ForegroundColor White
    Write-Host "   orbitdl <file or folder path>" -ForegroundColor White
    Write-Host "   orbitdlgen <file or folder path>" -ForegroundColor White
    Write-Host ""
    Write-Host " Flags & Options:" -ForegroundColor Yellow
    Write-Host "   odlg                   Open dashboard menu" -ForegroundColor White
    Write-Host "   odlg --settings, -s    Open settings manager" -ForegroundColor White
    Write-Host "   odlg --history         View upload log" -ForegroundColor White
    Write-Host "   odlg --help, -h        Display this guide" -ForegroundColor White
    Write-Host "================================================================================" -ForegroundColor Cyan
}

function Show-HistoryView {
    Show-Banner
    Write-Host " [H] UPLOAD HISTORY" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    if (Test-Path $HistoryPath) {
        $Records = @(Get-Content -Raw -Path $HistoryPath | ConvertFrom-Json)
        if ($Records.Count -eq 0) { Write-Host " No history recorded yet." -ForegroundColor DarkGray }
        else { $Records | Format-Table -Property Timestamp, Name, Size, Url -AutoSize | Out-String | Write-Host -ForegroundColor White }
    } else { Write-Host " No history recorded yet." -ForegroundColor DarkGray }
    Write-Host "================================================================================" -ForegroundColor Cyan
    Read-Host " Press Enter to return..."
}

function Show-SettingsView {
    while ($true) {
        Show-Banner
        Write-Host " [⚙] SETTINGS CONFIGURATION" -ForegroundColor Green
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " [1] Backend Host Provider    : $($Config.Backend)" -ForegroundColor White
        Write-Host " [2] Auto-Copy to Clipboard   : $($Config.AutoCopyClipboard)" -ForegroundColor White
        Write-Host " [3] Auto-Clear Terminal      : $($Config.ClearScreen)" -ForegroundColor White
        Write-Host " [4] Default Folder Archive   : $($Config.DefaultArchive)" -ForegroundColor White
        Write-Host " [B] Back to Main Menu" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        $Opt = Read-Host " Select option to toggle"
        switch ($Opt.ToUpper().Trim()) {
            "1" { $Config.Backend = if ($Config.Backend -eq "transfer.sh") { "0x0.st" } else { "transfer.sh" }; Save-Config }
            "2" { $Config.AutoCopyClipboard = -not $Config.AutoCopyClipboard; Save-Config }
            "3" { $Config.ClearScreen = -not $Config.ClearScreen; Save-Config }
            "4" {
                if ($Config.DefaultArchive -eq "zip") { $Config.DefaultArchive = "tar" }
                elseif ($Config.DefaultArchive -eq "tar") { $Config.DefaultArchive = "tar.gz" }
                else { $Config.DefaultArchive = "zip" }
                Save-Config
            }
            "B" { return }
        }
    }
}

function Process-Upload ([string]$TargetPath) {
    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Show-Banner
        Write-Host " [!] Error: Target path not found: $TargetPath" -ForegroundColor Red
        return
    }

    $IsFolder = (Get-Item -LiteralPath $TargetPath) -is [System.IO.DirectoryInfo]
    $TempArchive = $null
    $UploadFile = $null

    if ($IsFolder) {
        Show-Banner
        $FolderItem = Get-Item -LiteralPath $TargetPath
        $FolderName = $FolderItem.Name
        Write-Host " [*] Directory selected: $FolderName" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " Choose archive format: [1] .zip  [2] .tar  [3] .tar.gz  [4] Default ($($Config.DefaultArchive))" -ForegroundColor White
        $Choice = Read-Host " Enter choice"
        $Format = switch ($Choice.Trim()) { "1" { "zip" } "2" { "tar" } "3" { "tar.gz" } default { $Config.DefaultArchive } }
        
        Write-Host " [*] Compressing directory to .$Format..." -ForegroundColor Cyan
        $TempDir = [System.IO.Path]::GetTempPath()

        if ($Format -eq "tar") {
            $TempArchive = Join-Path $TempDir "$FolderName.tar"
            tar -cf "$TempArchive" -C "$($FolderItem.FullName)" .
        } elseif ($Format -eq "tar.gz") {
            $TempArchive = Join-Path $TempDir "$FolderName.tar.gz"
            tar -czf "$TempArchive" -C "$($FolderItem.FullName)" .
        } else {
            $TempArchive = Join-Path $TempDir "$FolderName.zip"
            if (Test-Path $TempArchive) { Remove-Item $TempArchive -Force }
            Compress-Archive -LiteralPath $FolderItem.FullName -DestinationPath $TempArchive -Force
        }
        $UploadFile = Get-Item -LiteralPath $TempArchive
    } else {
        $UploadFile = Get-Item -LiteralPath $TargetPath
    }

    Show-Banner
    $SizeMB = [math]::Round(($UploadFile.Length / 1MB), 2)
    Write-Host " [*] Target File : $($UploadFile.Name)" -ForegroundColor White
    Write-Host " [*] Target Size : $SizeMB MB" -ForegroundColor White
    Write-Host " [*] Engine      : $($Config.Backend)" -ForegroundColor White
    Write-Host " [*] Status      : Uploading payload..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

    try {
        $DirectUrl = ""
        if ($Config.Backend -eq "0x0.st") {
            $DirectUrl = (curl.exe -F "file=@$($UploadFile.FullName)" https://0x0.st).Trim()
        } else {
            $EncodedName = [System.Uri]::EscapeDataString($UploadFile.Name)
            $DirectUrl = (Invoke-RestMethod -Uri "https://transfer.sh" -Method Put -InFile $UploadFile.FullName).Trim()
        }

        if ($TempArchive -and (Test-Path $TempArchive)) { Remove-Item $TempArchive -Force }
        if ($Config.AutoCopyClipboard) { Set-Clipboard -Value $DirectUrl }

Log-History -Name $UploadFile.Name -Url $DirectUrl -Size "$SizeMB MB"
Show-Banner
Write-Host " [✓] UPLOAD SUCCESSFUL!" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " [▶] Direct Download Link:" -ForegroundColor Yellow
Write-Host " $DirectUrl" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
if ($Config.AutoCopyClipboard) { Write-Host " [] Direct download link copied to your clipboard!" -ForegroundColor White }
Write-Host " [] Logged to local upload history." -ForegroundColor Gray
Write-Host "================================================================================" -ForegroundColor Cyan
} catch {
if ($TempArchive -and (Test-Path $TempArchive)) { Remove-Item $TempArchive -Force }
Write-Host " [!] Upload Failed: $($_.Exception.Message)" -ForegroundColor Red
}
}
if ($PathArgs.Count -gt 0) {
$ArgString = ($PathArgs -join ' ').Trim()
if ($ArgString -in @("--help", "-h", "/?", "-help")) { Show-HelpGuide; exit }
if ($ArgString -in @("--settings", "-s")) { Show-SettingsView; exit }
if ($ArgString -in @("--history")) { Show-HistoryView; exit }
Process-Upload -TargetPath $ArgString.Trim('"').Trim("'")
exit
}
while ($true) {
Show-Banner
Write-Host " [1] Upload a File or Folder" -ForegroundColor Green
Write-Host " [2] View Upload History" -ForegroundColor Green
Write-Host " [3] Configure Settings" -ForegroundColor Green
Write-Host " [4] View User Guide" -ForegroundColor Green
Write-Host " [Q] Exit" -ForegroundColor Red
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
$MenuSelection = Read-Host " Select an option [1-4, Q]"
switch ($MenuSelection.ToUpper().Trim()) {
"1" {
Show-Banner
$InputPath = Read-Host " Enter or drag-and-drop path (no quotes needed)"
if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
Process-Upload -TargetPath $InputPath.Trim().Trim('"').Trim("'")
Read-Host " Press Enter to continue..."
}
}
"2" { Show-HistoryView }
"3" { Show-SettingsView }
"4" { Show-HelpGuide; Read-Host " Press Enter to continue..." }
"Q" { Show-Banner; Write-Host " Goodbye!" -ForegroundColor Yellow; break }
}
}
'@
$CorePath = Join-Path $InstallDir "engine.ps1"
Set-Content -Path $CorePath -Value $PSCoreContent -Encoding UTF8
## 3. Create command launcher wrappers
$CmdTemplate = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$CorePath" %*
"@
@("orbitdlgen.cmd", "orbitdl.cmd", "odlg.cmd") | ForEach-Object {
Set-Content -Path (Join-Path $InstallDir $_) -Value $CmdTemplate -Encoding Ascii
}
## 4. Add to User PATH
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "OrbitDL.Gen") {
$NewPath = ($UserPath.TrimEnd(';') + ";" + $InstallDir).Replace(";;", ";")
[Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
Write-Host "[✓] OrbitDL.Gen registered to User PATH." -ForegroundColor Green
}
Write-Host " Installation complete! Restart terminal and type 'odlg' to run." -ForegroundColor Cyan
```
------------------------------
## 💻 Commands & Usage
You can use odlg, orbitdl, or orbitdlgen interchangeably:

| Command | Action |
|---|---|
| odlg | Opens the interactive visual dashboard menu |
| odlg <path> | Instantly uploads a file or folder and copies the direct link |
| odlg -s or odlg --settings | Opens the configuration settings menu |
| odlg --history | Displays your previous uploads and links |
| odlg -h or odlg --help | Shows the quick help manual |

## Examples

* Upload a single file:
powershell odlg document.pdf 
* Upload a path with spaces (no quotes required):
powershell odlg C:\Users\Username\Documents\My Project Files\video.mp4 
* Upload an entire directory (auto-compresses):
powershell odlg C:\Users\Username\Desktop\ProjectFolder 

------------------------------
## ✨ Features

* Pure Direct Links: Delivers raw links ready for curl, wget, scripts, or clean browser downloads.
* Auto Clipboard Sync: Automatically copies generated URLs straight to your Windows clipboard (Ctrl + V).
* No Quotes Needed: Reads multi-word file and folder paths seamlessly without quotation marks.
* Folder Auto-Archiving: Automatically packages directories into .zip, .tar, or .tar.gz, uploads the archive, and removes the temporary file immediately after.
* Interactive Terminal UI: Features a colorized title banner, an interactive menu, and clean status outputs.
* Upload History: Logs file names, file sizes, timestamps, and generated links locally in history.json.
* Configurable Backend: Supports switching between transfer.sh and 0x0.st.

------------------------------
## ⚙️ Configuration
Your preferences are saved in config.json inside the tool's directory:
json { "Backend": "transfer.sh", "AutoCopyClipboard": true, "ClearScreen": true, "DefaultArchive": "zip" } 
You can change these values manually or interactively by running odlg -s.
------------------------------
## 🛠️ Requirements

* Operating System: Windows 10 or Windows 11
* Shell: Windows PowerShell 5.1+ or PowerShell Core 7+
* Network: Active internet connection

------------------------------
## 👤 Author
Developed and maintained by [@Yuganshraj6](https://github.com/yugansh-dhir).


<FollowUp>
Would you like me to show you how to commit and push this **`README.md`** update directly via Git, or add an **uninstallation instruction** section to it?
</FollowUp>


