# Asenna NFS Client Windows 11:een
# Tämä skripti täytyy suorittaa PowerShellissä järjestelmänvalvojan oikeuksilla

Write-Host "Tarkistetaan, onko NFS Client jo asennettu..."

# Tarkista, onko NFS Client jo asennettuna
$nfsFeature = Get-WindowsOptionalFeature -Online -FeatureName "ServicesForNFS-ClientOnly"

if ($nfsFeature.State -eq "Enabled") {
    Write-Host "NFS Client on jo asennettu." -ForegroundColor Green
} else {
    Write-Host "Asennetaan NFS Client..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName "ServicesForNFS-ClientOnly" -All -NoRestart
    Write-Host "NFS Client asennettu onnistuneesti." -ForegroundColor Green
    Write-Host "Käynnistä tietokone uudelleen, jotta muutokset tulevat voimaan." -ForegroundColor Cyan
}

# (Valinnainen) Voit lisätä NFS-komponentit hallintatyökaluihin:
# Enable-WindowsOptionalFeature -Online -FeatureName "ClientForNFS-Infrastructure" -All -NoRestart
