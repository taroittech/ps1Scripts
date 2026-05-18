<#
.SYNOPSIS
Asentaa WinGet ja Chocolatey Windows 11 -koneelle.
#>

# Näytetään virheet heti
$ErrorActionPreference = "Stop"

# Logi tiedostoon
$LogFile = "$env:TEMP\Install-WinGet-Choco.log"
Start-Transcript -Path $LogFile -Force

Write-Host "=== Käynnistetään WinGet + Chocolatey asennusskripti ===" -ForegroundColor Cyan

# --- Tarkistetaan admin-oikeudet ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Skripti täytyy ajaa järjestelmänvalvojana!" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- WinGet ---
Write-Host "`n[1/2] Tarkistetaan WinGet..." -ForegroundColor Yellow
try {
    if (Get-Command winget -ErrorAction Stop) {
        Write-Host "✅ WinGet löytyy jo!" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚙️ WinGet ei löydy. Ladataan ja asennetaan..." -ForegroundColor Yellow
    $installer = "$env:TEMP\AppInstaller.msixbundle"
    Invoke-WebRequest "https://aka.ms/getwinget" -OutFile $installer -UseBasicParsing
    Add-AppxPackage -Path $installer
    Write-Host "✅ WinGet asennettu!" -ForegroundColor Green
}

# --- Chocolatey ---
Write-Host "`n[2/2] Tarkistetaan Chocolatey..." -ForegroundColor Yellow
if (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe") {
    Write-Host "✅ Chocolatey löytyy jo!" -ForegroundColor Green
}
else {
    Write-Host "⚙️ Asennetaan Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "✅ Chocolatey asennettu!" -ForegroundColor Green
}

# --- Tarkistukset ---
Write-Host "`n🧩 Tarkistetaan asennukset..." -ForegroundColor Cyan
try {
    Write-Host "WinGet versio: " (winget --version)
} catch {}
try {
    Write-Host "Chocolatey versio: " (choco --version)
} catch {}

Write-Host "`n🎉 Valmis! Lokitiedosto: $LogFile" -ForegroundColor Cyan
Stop-Transcript
