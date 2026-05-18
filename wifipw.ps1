# Listaa kaikki tallennetut Wi-Fi-verkot ja niiden salasanat
# Varmista, että suoritat tämän skriptin järjestelmänvalvojana

# Hakee kaikki Wi-Fi-profiilit
$wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
    ($_ -split ":")[1].Trim()
}

# Tarkistaa jokaisen profiilin salasanan
$wifiProfiles | ForEach-Object {
    $profile = $_
    $details = netsh wlan show profile name="$profile" key=clear

    # Etsii salasanan
    $passwordLine = $details | Select-String "Key Content"
    
    if ($passwordLine) {
        $password = ($passwordLine -split ":")[1].Trim()
    } else {
        $password = "(Ei salasanaa tallennettu)"
    }

    # Tulostaa profiilin ja salasanan
    [PSCustomObject]@{
        Verkko = $profile
        Salasana = $password
    }
} | Format-Table -AutoSize
