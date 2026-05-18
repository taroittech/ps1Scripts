# Tarkista onko winget käytettävissä
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget ei ole asennettuna tähän järjestelmään. Asenna se Microsoft Storesta."
    exit
}

# Hae lista sovelluksista, joille on päivityksiä saatavilla
Write-Host "Tarkistetaan päivityksiä, odota hetki..."

# Suorita winget upgrade ja ohita interaktiivisuus
$updates = winget upgrade --accept-source-agreements | Select-String "^\S" | Where-Object { $_ -notmatch "Name\s+Id\s+Version" -and $_ -notmatch "----" }

# Laske montako riviä löytyi (eli montako päivitettävää sovellusta)
$updateCount = $updates.Count

# Tulosta tulos
if ($updateCount -eq 0) {
    Write-Host "Kaikki sovellukset ovat ajan tasalla. ✅"
} else {
    Write-Host "Päivityksiä saatavilla $updateCount sovellukselle. 🔄"
}
