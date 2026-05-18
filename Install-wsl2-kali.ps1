<#
PowerShell-skripti: Asentaa WSL2 ja Kali Linux (Windows 11)
Käyttö: Aja PowerShell järjestelmänvalvojana (Run as Administrator).
Huom: Skripti pyrkii automatisoimaan asennuksen, mutta Kali-distron ensimmäinen käynnistyskerta (käyttäjänluonti) vaatii yleensä interaktiivisen käyttökerran tai erillisen importin.
Lähteet: Microsoft WSL -dokumentaatio ja Kali WSL -ohjeet.
#>

# Tarkista, onko skripti käynnistetty järjestelmänvalvojana
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Tämä skripti täytyy ajaa järjestelmänvalvojana. Sulje ja aja PowerShell valitsemalla 'Run as Administrator'."
    exit 1
}

Write-Host "Aloitetaan WSL2- ja Kali-asennus..." -ForegroundColor Cyan

# Ota WSL-ominaisuus ja Virtual Machine Platform käyttöön
Write-Host "Otetaan Windows Subsystem for Linux ja Virtual Machine Platform käyttöön..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

# (Valinnainen) ota Hyper-V käyttöön jos haluat täydet virtualisointiominaisuudet
Write-Host "(Valinnainen) Ota Hyper-V käyttöön..." -ForegroundColor Yellow
try {
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
} catch {
    Write-Warning "Hyper-V:n aktivointi epäonnistui tai ei ole tuettua laitteistollasi. Jatketaan kuitenkin WSL2-asennusta."
}

Write-Host "Käynnistetään kone uudelleen automaattisesti asennusvaiheiden jälkeen..." -ForegroundColor Yellow

# Lataa ja asenna WSL Linux kernel -päivitys (jos msix/msi paketti tarvitaan)
$wslMsiUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$localMsi = "$env:TEMP\wsl_update_x64.msi"

Write-Host "Ladataan WSL Linux kernel -päivityspaketti..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $wslMsiUrl -OutFile $localMsi -UseBasicParsing -ErrorAction Stop
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$localMsi`" /quiet /norestart" -Wait -NoNewWindow
    Remove-Item $localMsi -ErrorAction SilentlyContinue
    Write-Host "Kernel-päivitys asennettu." -ForegroundColor Green
} catch {
    Write-Warning "Kernel-päivityksen lataus tai asennus epäonnistui. Jatketaan ja yritetään käyttää 'wsl --update' komentoa (jos saatavilla)."
}

# Aseta WSL oletukseksi versioksi 2 (jos komento on käytettävissä)
Write-Host "Asetetaan WSL oletusversioksi 2 (WSL2)..." -ForegroundColor Yellow
try {
    wsl --set-default-version 2 2>$null
    Write-Host "Oletusversio asetettu WSL2:ksi." -ForegroundColor Green
} catch {
    Write-Warning "wsl --set-default-version -komentoa ei voitu suorittaa. Tämä voi olla jo asetettuna tai vanhempi Windows Build."
}

# Päivitä WSL (jos saatavilla)
Write-Host "Yritetään päivittää WSL: 'wsl --update'..." -ForegroundColor Yellow
try {
    wsl --update 2>$null
    Write-Host "WSL päivitys suoritettu (jos saatavilla)." -ForegroundColor Green
} catch {
    Write-Warning "wsl --update ei ole saatavilla tällä buildilla."
}

# Listaa saatavilla olevat distrovalinnat ja asenna Kali Linux
Write-Host "Haetaan listaa saatavilla olevista WSL-distroista..." -ForegroundColor Yellow
$available = wsl --list --online 2>&1
Write-Host $available

Write-Host "Asennetaan Kali Linux WSL-distrona..." -ForegroundColor Yellow
try {
    wsl --install -d kali-linux 2>&1 | ForEach-Object { Write-Host $_ }
    Write-Host "Kali Linux -asennus käynnistetty. Jos asennus epäonnistuu Store-latausrajoitusten takia, katso vaihtoehtoinen "import"-menetelmä Kali-dokumentaatiosta." -ForegroundColor Green
} catch {
    Write-Warning "Kali-asennus epäonnistui automaattisesti. Saatat joutua asentamaan sen manuaalisesti Microsoft Storesta tai käyttämään wsl --import -menetelmää."
}

Write-Host "Asetetaan Kali oletusdistroksi..." -ForegroundColor Yellow
try {
    wsl --set-default kali-linux 2>$null
    Write-Host "Kali asetettu oletusdistroksi." -ForegroundColor Green
} catch {
    Write-Warning "Kali ei ehkä ole vielä asennettu tai nimi poikkeaa. Tarkista 'wsl --list --verbose'."
}

Write-Host "Asennusvaihe valmis. Suosittelen käynnistämään koneen uudelleen nyt." -ForegroundColor Cyan
Write-Host "HUOM: Ensimmäinen Kali-distron käynnistys avaa yleensä interaktiivisen käyttäjänluontiprosessin — käynnistä 'Kali Linux' Käynnistä-valikosta tai aja 'wsl -d kali-linux' ja luo käyttäjätunnus/salasana." -ForegroundColor Magenta

Write-Host "Valmis." -ForegroundColor Green

exit 0
