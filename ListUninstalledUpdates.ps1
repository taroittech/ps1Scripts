#Lists Windows Updates whether Installed or Not and Severity
#Author: Sean Bradley
#License: BSD-3-Clause-Attribution
#Website: https://sbcode.net/zabbix/powershell-windows-updates/
$Searcher = new-object -com "Microsoft.Update.Searcher"
$Searcher.Search("IsAssigned=1 and IsHidden=0").Updates | Format-Table title, MsrcSeverity, IsInstalled | Out-String -Width 256
