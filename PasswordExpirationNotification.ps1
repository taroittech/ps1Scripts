#requires -Version 5.1

<#
.SYNOPSIS
    Password expiration reminder script

.DESCRIPTION
    Sends email reminders to local Windows users
    before their password expires.

.NOTES
    Modernized version
#>

#region Configuration

$Config = @{
    SmtpServer        = "smtp-out.mediam.fi"
    From              = "Salasanamuistutin <info@kaita.fi>"
    EmailDomain       = "kaita.fi"

    ReminderDays      = @(5,1)

    LogEnabled        = $true
    LogFile           = "C:\PasswordExpirationNotification\log.csv"

    Testing           = $false
    TestRecipient     = "taro.turtiainen@kaita.fi"

    ExcludedUsers     = @(
        "Administrator",
        "Guest",
        "DefaultAccount",
        "WDAGUtilityAccount",
        "Kaitabackup",
        "fwadmin",
        "Backupadmin",
        "kaitaadmin",
        "Valvoja"
    )
}

#endregion

#region Initialization

$Hostname = $env:COMPUTERNAME
$Today = Get-Date

if ($Config.LogEnabled) {

    $LogFolder = Split-Path $Config.LogFile

    if (!(Test-Path $LogFolder)) {
        New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
    }

    if (!(Test-Path $Config.LogFile)) {

        "Date,Username,FullName,Email,DaysLeft,ExpirationDate,NotificationSent" |
            Out-File -FilePath $Config.LogFile -Encoding UTF8
    }
}

#endregion

#region Functions

function Write-Log {

    param(
        [string]$Username,
        [string]$FullName,
        [string]$Email,
        [int]$DaysLeft,
        [datetime]$ExpirationDate,
        [string]$NotificationSent
    )

    if (-not $Config.LogEnabled) {
        return
    }

    $LogLine = '"{0}","{1}","{2}","{3}","{4}","{5}","{6}"' -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
        $Username,
        $FullName,
        $Email,
        $DaysLeft,
        $ExpirationDate,
        $NotificationSent

    Add-Content -Path $Config.LogFile -Value $LogLine
}

function Get-LocalUserExpiration {

    param(
        [string]$Username
    )

    try {

        $User = [ADSI]"WinNT://$env:COMPUTERNAME/$Username,user"

        $PasswordAgeSeconds = $User.PasswordAge.Value

        $MaxPasswordAge = net accounts |
            Select-String "Maximum password age"

        if (-not $MaxPasswordAge) {
            return $null
        }

        $MaxDays = ($MaxPasswordAge -replace '\D+','')

        if ($MaxDays -eq 0) {
            return $null
        }

        $PasswordSetDate = (Get-Date).AddSeconds(-$PasswordAgeSeconds)

        return $PasswordSetDate.AddDays($MaxDays)
    }
    catch {
        Write-Warning "Failed to read expiration for $Username"
        return $null
    }
}

function Send-ReminderMail {

    param(
        [string]$To,
        [string]$FullName,
        [int]$DaysLeft,
        [datetime]$ExpirationDate
    )

    if ($DaysLeft -eq 1) {

        $Subject = "Koneen $Hostname salasana vanhenee huomenna"

        $Body = @"
Hei $FullName,

Salasanasi koneella $Hostname vanhenee huomenna.

Vaihda salasana painamalla:

CTRL + ALT + DELETE
-> Change Password

Terveisin,
Ylläpito
"@
    }
    else {

        $Subject = "Koneen $Hostname salasana vanhenee $DaysLeft päivän päästä"

        $Body = @"
Hei $FullName,

Salasanasi koneella $Hostname vanhenee $DaysLeft päivän kuluttua.

Vanhenemispäivä:
$($ExpirationDate.ToString("dd.MM.yyyy"))

Voit vaihtaa salasanan painamalla:

CTRL + ALT + DELETE
-> Change Password

Terveisin,
Ylläpito
"@
    }

    if ($Config.Testing) {
        $To = $Config.TestRecipient
    }

    try {

        Send-MailMessage `
            -SmtpServer $Config.SmtpServer `
            -From $Config.From `
            -To $To `
            -Subject $Subject `
            -Body $Body `
            -Encoding UTF8

        return $true
    }
    catch {

        Write-Warning "Email sending failed to $To"
        return $false
    }
}

#endregion

#region Main

Write-Host "Scanning local users on $Hostname..."

$Users = Get-CimInstance Win32_UserAccount |
    Where-Object {
        $_.LocalAccount -eq $true -and
        $_.Disabled -eq $false -and
        $_.Name -notin $Config.ExcludedUsers
    }

if (-not $Users) {

    Write-Host ""
    Write-Host "No local user accounts found." -ForegroundColor Yellow
    Write-Host "Nothing to process." -ForegroundColor Yellow
    Write-Host ""

    return
}

Write-Host ""
Write-Host "Found users:" -ForegroundColor Cyan

$Users | ForEach-Object {
    Write-Host " - $($_.Name)"
}

Write-Host ""

foreach ($User in $Users) {

    $Username = $User.Name
    $FullName = $User.FullName

    if ([string]::IsNullOrWhiteSpace($FullName)) {
        $FullName = $Username
    }

    $EmailUser = $FullName.ToLower()

    $EmailUser = $EmailUser.Replace(" ", ".")
    $EmailUser = $EmailUser.Replace("ä", "a")
    $EmailUser = $EmailUser.Replace("ö", "o")
    $EmailUser = $EmailUser.Replace("å", "a")

    $Email = "$EmailUser@$($Config.EmailDomain)"

    $ExpirationDate = Get-LocalUserExpiration -Username $Username

    if (-not $ExpirationDate) {

        Write-Host "$Username : Password never expires"
        continue
    }

    $DaysLeft = ($ExpirationDate.Date - $Today.Date).Days

    Write-Host "$Username : $DaysLeft day(s) left"

    if ($DaysLeft -in $Config.ReminderDays) {

        $MailSent = Send-ReminderMail `
            -To $Email `
            -FullName $FullName `
            -DaysLeft $DaysLeft `
            -ExpirationDate $ExpirationDate

        Write-Log `
            -Username $Username `
            -FullName $FullName `
            -Email $Email `
            -DaysLeft $DaysLeft `
            -ExpirationDate $ExpirationDate `
            -NotificationSent $MailSent
    }
}

#endregion
