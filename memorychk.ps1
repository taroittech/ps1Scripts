Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, @{Name="CapacityGB";Expression={[math]::Round($_.Capacity/1GB,2)}}, Speed
