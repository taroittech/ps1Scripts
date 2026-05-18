<#
.SYNOPSIS
    Asentaa uusimman Cascadia Code -fontin Windows 11 -koneelle.
.DESCRIPTION
    Lataa Cascadia Code -fontit Microsoftin virallisesta GitHub-julkaisusta
    ja asentaa ne järjestelmään, jotta Windows Terminal näyttää emojit oikein.
#>

# --- Tarkista admin-oikeudet ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Tämä skripti täytyy suorittaa järjestelmänvalvojana (Run as Administrator)." -ForegroundColor Yellow
    exit 1
}

Write-Host "Haetaan uusimmat Cascadia Code -fontit Microsoftin GitHubista..." -ForegroundColor Cyan

# --- Hae uusin julkaisu ---
$releaseUrl = "https://github.com/microsoft/cascadia-code/releases/latest"
$response = Invoke-WebRequest -Uri $releaseUrl -MaximumRedirection 0 -ErrorAction SilentlyContinue
$redirectUrl = $response.Headers.Location

if (-not $redirectUrl) {
    Write-Error "Julkaisusivua ei voitu hakea."
    exit 1
}

$version = ($redirectUrl -split "/")[-1]
$zipUrl = "https://github.com/microsoft/cascadia-code/releases/download/$version/CascadiaCode-$version.zip"

$tempPath = Join-Path $env:TEMP "CascadiaCode.zip"
$extractPath = Join-Path $env:TEMP "CascadiaCode"

Write-Host "Ladataan fonttipaketti versio $version..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $zipUrl -OutFile $tempPath -UseBasicParsing

if (Test-Path $extractPath) {
    Remove-Item -Recurse -Force $extractPath
}

Expand-Archive -Path $tempPath -DestinationPath $extractPath

# --- Etsi kaikki .ttf-fontit ---
$fonts = Get-ChildItem -Path $extractPath -Recurse -Include *.ttf
if ($fonts.Count -eq 0) {
    Write-Error "Fonttitiedostoja ei löytynyt."
    exit 1
}

Write-Host "Asennetaan fontit..." -ForegroundColor Cyan

$fontsFolder = "$env:WINDIR\Fonts"
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

foreach ($font in $fonts) {
    $fileName = Split-Path $font -Leaf
    $destPath = Join-Path $fontsFolder $fileName

    if (-not (Test-Path $destPath)) {
        Copy-Item -Path $font.FullName -Destination $destPath -Force
        Write-Host "Asennettu: $fileName"
    }
    else {
        Write-Host "Fontti jo olemassa: $fileName"
    }

    # Lisää rekisterimerkintä
    $fontName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    New-ItemProperty -Path $regPath -Name "$fontName (TrueType)" -Value $fileName -PropertyType String -Force | Out-Null
}

# --- Ilmoitetaan Windowsille fonttimuutoksesta ---
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show(
    "Cascadia Code -fontit asennettu onnistuneesti! Käynnistä Windows Terminal uudelleen.",
    "Asennus valmis",
    "OK",
    "Information"
) | Out-Null

Write-Host ""
Write-Host "Valmis! Käynnistä Windows Terminal uudelleen ja valitse fontiksi esimerkiksi 'Cascadia Code PL' tai 'Cascadia Mono PL'." -ForegroundColor Green
