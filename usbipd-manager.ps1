function Check-Usbipd {
    if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
        Write-Host "usbipd ei ole asennettu tai ei löydy PATH:sta." -ForegroundColor Red
        exit 1
    }
}

function Get-Devices {
    $output = usbipd list
    $devices = @()

    foreach ($line in $output) {
        if ($line -match "^\s*(\d+-\d+)\s+") {
            $devices += [PSCustomObject]@{
                BusId = $matches[1]
                Raw   = $line
            }
        }
    }
    return $devices
}

function Show-Devices {
    $devices = Get-Devices
    if ($devices.Count -eq 0) {
        Write-Host "Ei laitteita." -ForegroundColor Yellow
        return $null
    }

    for ($i = 0; $i -lt $devices.Count; $i++) {
        Write-Host "[$i] $($devices[$i].Raw)"
    }

    $choice = Read-Host "Valitse laite numerolla"
    return $devices[$choice]
}

function Get-Distros {
    $raw = wsl -l -v

    $distros = @()

    foreach ($line in $raw) {
        if ($line -match "^\s*(\*?)\s*([^\s]+)\s+(\w+)\s+(\d+)") {
            $distros += [PSCustomObject]@{
                Name = $matches[2]
                State = $matches[3]
                Version = $matches[4]
            }
        }
    }

    return $distros
}

function Show-Distros {
    $distros = Get-Distros

    if ($distros.Count -eq 0) {
        Write-Host "Ei WSL distroja." -ForegroundColor Red
        return $null
    }

    for ($i = 0; $i -lt $distros.Count; $i++) {
        Write-Host ("[{0}] {1} ({2}, WSL{3})" -f `
            $i,
            $distros[$i].Name,
            $distros[$i].State,
            $distros[$i].Version
        )
    }

    $choice = Read-Host "Valitse distro numerolla (Enter = default)"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $null
    }

    if (-not ($choice -match "^\d+$") -or $choice -ge $distros.Count) {
        Write-Host "Virheellinen valinta" -ForegroundColor Red
        return $null
    }

    return $distros[$choice].Name
}

function List-Devices {
    usbipd list
}

function Bind-Device {
    $device = Show-Devices
    if ($device) {
        usbipd bind --busid $device.BusId
    }
}

function Unbind-Device {
    $device = Show-Devices
    if ($device) {
        usbipd unbind --busid $device.BusId
    }
}

function Attach-Device {
    $device = Show-Devices
    if (-not $device) { return }

    Ensure-Any-WSL-Running

    Write-Host "Attachataan USB laite WSL2:een..." -ForegroundColor Cyan

    usbipd attach --wsl --busid $device.BusId
}

function Detach-Device {
    $device = Show-Devices
    if ($device) {
        usbipd detach --busid $device.BusId
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "=== USBIPD Manager ===" -ForegroundColor Cyan
    Write-Host "1. Listaa laitteet"
    Write-Host "2. Bind laite"
    Write-Host "3. Unbind laite"
    Write-Host "4. Attach WSL2:een"
    Write-Host "5. Detach WSL2:sta"
    Write-Host "0. Lopeta"
}

function Get-RunningDistros {
    $output = wsl -l -v
    $running = @()

    foreach ($line in $output) {
        if ($line -match "^\s*(\S+)\s+Running") {
            $running += $matches[1]
        }
    }
    return $running
}

function Ensure-Distro-Running($distro) {
    $running = Get-RunningDistros

    if ($null -eq $distro) {
        return
    }

    if ($running -notcontains $distro) {
        Write-Host "Käynnistetään distro: $distro..." -ForegroundColor Yellow
        wsl -d $distro -e sh -c "echo WSL started" | Out-Null
        Start-Sleep -Seconds 1
    }
}

function Ensure-Any-WSL-Running {
    $distros = wsl -l -v

    $running = $false

    foreach ($line in $distros) {
        if ($line -match "Running\s*$") {
            $running = $true
        }
    }

    if (-not $running) {
        Write-Host "Ei käynnissä olevaa WSL2 distroa. Käynnistetään oletus..." -ForegroundColor Yellow

        # käynnistetään default distro taustalle
        wsl -e sh -c "echo warming up WSL" | Out-Null

        Start-Sleep -Seconds 2
    }
}

# --- MAIN ---
$running = $true

while ($running) {
    Show-Menu
    $choice = Read-Host "Valinta"

    switch ($choice) {
        "1" { List-Devices }
        "2" { Bind-Device }
        "3" { Unbind-Device }
        "4" { Attach-Device }
        "5" { Detach-Device }

        "0" {
            Write-Host "Lopetetaan..." -ForegroundColor Cyan
            $running = $false
        }

        default {
            Write-Host "Virheellinen valinta." -ForegroundColor Yellow
        }
    }
}