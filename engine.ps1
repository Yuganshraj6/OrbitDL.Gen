param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PathArgs
)

$ConfigPath = Join-Path $PSScriptRoot "config.json"
$HistoryPath = Join-Path $PSScriptRoot "history.json"

# Load or initialize configuration
$DefaultConfig = @{
    Backend = "transfer.sh"
    AutoCopyClipboard = $true
    ClearScreen = $true
    DefaultArchive = "zip"
}

if (Test-Path $ConfigPath) {
    try {
        $Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json -AsHashtable
    } catch {
        $Config = $DefaultConfig
    }
} else {
    $Config = $DefaultConfig
    $Config | ConvertTo-Json -Depth 3 | Set-Content -Path $ConfigPath -Encoding UTF8
}

function Save-Config {
    $Config | ConvertTo-Json -Depth 3 | Set-Content -Path $ConfigPath -Encoding UTF8
}

function Log-History ($Name, $Url, $Size) {
    $History = @()
    if (Test-Path $HistoryPath) {
        try {
            $History = @(Get-Content -Raw -Path $HistoryPath | ConvertFrom-Json)
        } catch { $History = @() }
    }
    $Entry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Name      = $Name
        Size      = $Size
        Url       = $Url
    }
    $History += $Entry
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
    Write-Host "   orbitdlgen <file or folder path>" -ForegroundColor White
    Write-Host "   orbitdl    <file or folder path>" -ForegroundColor White
    Write-Host "   odlg       <file or folder path>" -ForegroundColor White
    Write-Host ""
    Write-Host " Flags & Interactive Modes:" -ForegroundColor Yellow
    Write-Host "   odlg                   Opens the interactive dashboard menu" -ForegroundColor White
    Write-Host "   odlg --help, -h        Shows this user guide" -ForegroundColor White
    Write-Host "   odlg --settings, -s    Directly launches settings manager" -ForegroundColor White
    Write-Host "   odlg --history         Directly views upload log" -ForegroundColor White
    Write-Host ""
    Write-Host " Key Features:" -ForegroundColor Yellow
    Write-Host "   * No quotes required for paths with spaces." -ForegroundColor Gray
    Write-Host "   * Automatic directory archiving (.zip, .tar, .tar.gz)." -ForegroundColor Gray
    Write-Host "   * Instant clipboard copy and direct download link output." -ForegroundColor Gray
    Write-Host "   * Persistent user settings and upload tracking." -ForegroundColor Gray
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-HistoryView {
    Show-Banner
    Write-Host " [H] UPLOAD HISTORY" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    if (Test-Path $HistoryPath) {
        $Records = @(Get-Content -Raw -Path $HistoryPath | ConvertFrom-Json)
        if ($Records.Count -eq 0) {
            Write-Host " No history recorded yet." -ForegroundColor DarkGray
        } else {
            $Records | Format-Table -Property Timestamp, Name, Size, Url -AutoSize | Out-String | Write-Host -ForegroundColor White
        }
    } else {
        Write-Host " No history recorded yet." -ForegroundColor DarkGray
    }
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
        $Opt = Read-Host " Select setting to toggle/change"
        switch ($Opt.ToUpper().Trim()) {
            "1" {
                if ($Config.Backend -eq "transfer.sh") { $Config.Backend = "0x0.st" }
                else { $Config.Backend = "transfer.sh" }
                Save-Config
            }
            "2" {
                $Config.AutoCopyClipboard = -not $Config.AutoCopyClipboard
                Save-Config
            }
            "3" {
                $Config.ClearScreen = -not $Config.ClearScreen
                Save-Config
            }
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
        Write-Host " [*] Selected item is a directory: $FolderName" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " Choose an archive format:" -ForegroundColor White
        Write-Host " [1] .zip    (Default: Standard Windows format)" -ForegroundColor Green
        Write-Host " [2] .tar    (Uncompressed Tarball)" -ForegroundColor Green
        Write-Host " [3] .tar.gz (GZip Compressed Tarball)" -ForegroundColor Green
        Write-Host " [4] Use system default ($($Config.DefaultArchive))" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        $Choice = Read-Host " Select option [1-4]"

        $Format = switch ($Choice.Trim()) {
            "1" { "zip" }
            "2" { "tar" }
            "3" { "tar.gz" }
            default { $Config.DefaultArchive }
        }

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
            $CurlCheck = Get-Command curl.exe -ErrorAction SilentlyContinue
            if ($CurlCheck) {
                $DirectUrl = (curl.exe -F "file=@$($UploadFile.FullName)" https://0x0.st).Trim()
            } else {
                throw "curl.exe is required for 0x0.st upload engine."
            }
        } else {
            $EncodedName = [System.Uri]::EscapeDataString($UploadFile.Name)
            $TargetUri = "https://transfer.sh/$EncodedName"
            $DirectUrl = (Invoke-RestMethod -Uri $TargetUri -Method Put -InFile $UploadFile.FullName).Trim()
        }

        if ($TempArchive -and (Test-Path $TempArchive)) {
            Remove-Item $TempArchive -Force
        }

        if ($Config.AutoCopyClipboard) {
            Set-Clipboard -Value $DirectUrl
        }

        Log-History -Name $UploadFile.Name -Url $DirectUrl -Size "$SizeMB MB"

        Show-Banner
        Write-Host " [✓] UPLOAD SUCCESSFUL!" -ForegroundColor Green
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " [▶] Direct Download Link:" -ForegroundColor Yellow
        Write-Host "     $DirectUrl" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        if ($Config.AutoCopyClipboard) {
            Write-Host " [*] Clipboard: Direct download link copied automatically!" -ForegroundColor White
        }
        Write-Host " [*] File logged to OrbitDL.Gen history database." -ForegroundColor Gray
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        if ($TempArchive -and (Test-Path $TempArchive)) {
            Remove-Item $TempArchive -Force
        }
        Write-Host " [!] Upload Failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "================================================================================" -ForegroundColor Cyan
    }
}

# Parse Arguments
if ($PathArgs.Count -gt 0) {
    $ArgString = ($PathArgs -join ' ').Trim()

    if ($ArgString -in @("--help", "-h", "/?", "-help")) {
        Show-HelpGuide
        exit
    }
    if ($ArgString -in @("--settings", "-s")) {
        Show-SettingsView
        exit
    }
    if ($ArgString -in @("--history")) {
        Show-HistoryView
        exit
    }

    $RawTarget = $ArgString.Trim('"').Trim("'")
    Process-Upload -TargetPath $RawTarget
    exit
}

# Main Interactive Menu
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
            Write-Host " Enter or drag-and-drop the file or folder path (no quotes needed):" -ForegroundColor Yellow
            $InputPath = Read-Host " Path"
            if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
                $CleanPath = $InputPath.Trim().Trim('"').Trim("'")
                Process-Upload -TargetPath $CleanPath
                Read-Host " Press Enter to return to menu..."
            }
        }
        "2" { Show-HistoryView }
        "3" { Show-SettingsView }
        "4" {
            Show-HelpGuide
            Read-Host " Press Enter to return to menu..."
        }
        "Q" {
            Show-Banner
            Write-Host " Goodbye!" -ForegroundColor Yellow
            break
        }
    }
}
