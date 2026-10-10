# 1. Define base installation directory
$InstallDir = "$env:USERPROFILE\OrbitDL.Gen"
If (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }

# 2. Download latest engine and launcher files directly from repository
$BaseUri = "https://raw.githubusercontent.com/Yuganshraj6/OrbitDL.Gen/main"
Write-Host " [*] Downloading latest OrbitDL.Gen core engine..." -ForegroundColor Cyan

Invoke-RestMethod -Uri "$BaseUri/engine.ps1" -OutFile (Join-Path $InstallDir "engine.ps1")

# Create CMD wrappers locally
$CorePath = Join-Path $InstallDir "engine.ps1"
$CmdTemplate = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$CorePath" %*
"@

@("orbitdlgen.cmd", "orbitdl.cmd", "odlg.cmd") | ForEach-Object {
    Set-Content -Path (Join-Path $InstallDir $_) -Value $CmdTemplate -Encoding Ascii
}

# 3. Add to Windows User PATH environment variable
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*OrbitDL.Gen*") {
    $NewPath = ($UserPath.TrimEnd(';') + ";" + $InstallDir).Replace(";;", ";")
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    Write-Host " [✓] OrbitDL.Gen registered to User PATH." -ForegroundColor Green
} else {
    Write-Host " [*] PATH already configured." -ForegroundColor Gray
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Installation complete! Restart terminal and type 'odlg' to run." -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
