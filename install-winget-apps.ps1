<#
.SYNOPSIS
    Asentaa yleiset työkalut wingetillä Windows 11 -koneelle (ilman Spotifyta).

.USAGE
    Suorita PowerShellissä järjestelmänvalvojana:
    PowerShell -ExecutionPolicy Bypass -File .\install-winget-apps.ps1
#>

# Varmistetaan, että skriptiä ajetaan järjestelmänvalvojana
function Ensure-RunAsAdmin {
    $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
    $wp = New-Object Security.Principal.WindowsPrincipal($wi)
    if (-not $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Ei järjestelmänvalvojan oikeuksia — yritetään nostaa oikeudet..."
        Start-Process -FilePath pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}
Ensure-RunAsAdmin

# Asennettavat paketit
$packages = @(
    "PuTTY.PuTTY",
    "7zip.7zip",
    "WinSCP.WinSCP",
    "Balena.Etcher",
    "Microsoft.VisualStudioCode",
    "Obsidian.Obsidian",
    "GIMP.GIMP.3",
    "Zoom.Zoom.EXE",
    "Microsoft.RemoteDesktopClient"
)

# Tarkistetaan, että winget on käytettävissä
try {
    winget --version | Out-Null
} catch {
    Write-Error "Winget ei ole käytettävissä. Asenna 'App Installer' Microsoft Storesta ja yritä uudelleen."
    exit 1
}

# Lokitiedosto
$log = Join-Path -Path $env:TEMP -ChildPath "winget-install-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
"Winget install log - $(Get-Date)" | Out-File -FilePath $log -Encoding utf8

# Asennusfunktio
function Install-PackageWithWinget {
    param([string]$Id)

    Write-Host "Asennetaan: $Id ..."
    "`n[$(Get-Date)] Installing $Id" | Out-File -FilePath $log -Append -Encoding utf8

    try {
        winget install --exact --id $Id -e --accept-package-agreements --accept-source-agreements -h
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $Id asennettu onnistuneesti." -ForegroundColor Green
            "`n[$(Get-Date)] SUCCESS: $Id" | Out-File -FilePath $log -Append -Encoding utf8
        } else {
            Write-Warning "⚠️  Virhe asennuksessa: $Id (exit code $LASTEXITCODE)"
            "`n[$(Get-Date)] ERROR: $Id (exit $LASTEXITCODE)" | Out-File -FilePath $log -Append -Encoding utf8
        }
    } catch {
        Write-Warning "Poikkeus asennuksessa: $Id - $_"
        "`n[$(Get-Date)] EXCEPTION: $Id - $_" | Out-File -FilePath $log -Append -Encoding utf8
    }
}

# Käydään paketit läpi ja asennetaan
foreach ($pkg in $packages) {
    Install-PackageWithWinget -Id $pkg
}

Write-Host "`n✅ Kaikki ohjelmat asennettu. Lokitiedosto löytyy: $log"
