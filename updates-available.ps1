# Tarkista onko winget käytettävissä
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget ei ole asennettuna tähän järjestelmään. Asenna se Microsoft Storesta."
    exit
}

# Hae lista sovelluksista, joille on päivityksiä saatavilla
Write-Host "Tarkistetaan päivityksiä, odota hetki..."

# Hae päivityslista
$updates = winget upgrade --accept-source-agreements 2>$null

# Suodata oikeat sovellusrivit
$apps = $updates |
    Select-String '^\S' |
    Where-Object {
        $_ -notmatch '^Name\s+Id\s+Version' -and
        $_ -notmatch '^-+' -and
        $_ -notmatch 'upgrades available' -and
        $_ -notmatch 'No installed package found'
    }

# Laske määrä
$updateCount = $apps.Count

# Tulosta tulos
if ($updateCount -eq 0) {
    Write-Host "Kaikki sovellukset ovat ajan tasalla. ✅"
}
else {
    Write-Host "Päivityksiä saatavilla $updateCount sovellukselle. 🔄"
}
