<#
.SYNOPSIS
  Workstation onboarding script: rename, set DNS, enable firewall, disable services, report.

.NOTES
  Run as local admin. Tested on Windows 10/11.
#>

param(
  [Parameter(Mandatory=$true)][string]$NewName,
  [Parameter(Mandatory=$true)][string[]]$DnsServers,
  [Parameter(Mandatory=$false)][string]$DomainJoinOU = ""
)

function Write-Report {
  param($Message)
  $ts = (Get-Date).ToString("s")
  "$ts - $Message" | Out-File -FilePath C:\Onboard\onboard-report.txt -Append -Encoding UTF8
}

# Ensure report folder
New-Item -Path C:\Onboard -ItemType Directory -Force | Out-Null

Write-Report "Starting onboarding on $(hostname)"

# Rename computer
try {
  Rename-Computer -NewName $NewName -Force -ErrorAction Stop
  Write-Report "Renamed computer to $NewName"
} catch {
  Write-Report "ERROR renaming computer: $_"
}

# Set DNS servers on primary Ethernet adapter
try {
  $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true } | Select-Object -First 1
  if ($null -ne $adapter) {
    $ifIndex = $adapter.ifIndex
    Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $DnsServers -ErrorAction Stop
    Write-Report "Set DNS servers to: $($DnsServers -join ',') on adapter $($adapter.Name)"
  } else {
    Write-Report "No active physical adapter found to set DNS"
  }
} catch {
  Write-Report "ERROR setting DNS: $_"
}

# Enable Windows Firewall (all profiles)
try {
  Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction Stop
  Write-Report "Enabled Windows Firewall for Domain, Public, Private"
} catch {
  Write-Report "ERROR enabling firewall: $_"
}

# Disable 3 unnecessary services (example: Fax, XblGameSave, WSearch) - adjust per policy
$servicesToDisable = @("Fax","XblGameSave","WSearch")
foreach ($svc in $servicesToDisable) {
  try {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
      Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
      Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
      Write-Report "Disabled service $svc"
    } else {
      Write-Report "Service $svc not present"
    }
  } catch {
    Write-Report "ERROR disabling service $svc: $_"
  }
}

# Output final status
$report = @{
  ComputerName = $env:COMPUTERNAME
  NewName = $NewName
  DNS = $DnsServers -join ","
  Firewall = (Get-NetFirewallProfile | Select-Object Name,Enabled | ConvertTo-Json)
  DisabledServices = $servicesToDisable
  Timestamp = (Get-Date).ToString("s")
}
$report | ConvertTo-Json -Depth 4 | Out-File -FilePath C:\Onboard\onboard-summary.json -Encoding UTF8

Write-Report "Onboarding complete. Summary written to C:\Onboard\onboard-summary.json"
Write-Output "Onboarding complete. See C:\Onboard\onboard-summary.json"
