# Script 2 — User Account Report
$users = Get-LocalUser
$admins = (Get-LocalGroupMember -Group "Administrators").Name
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
if (!(Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" | Out-Null }
$outfile = "C:\Temp\local_users_$timestamp.csv"

$report = foreach ($u in $users) {
    $isAdmin = $admins -contains $u.Name
    $neverLoggedInEnabled = ($u.LastLogon -eq $null -and $u.Enabled -eq $true)

    [PSCustomObject]@{
        Name                   = $u.Name
        Enabled                = $u.Enabled
        LastLogon              = $u.LastLogon
        InAdministratorsGroup  = $isAdmin
        EnabledNeverLoggedIn   = $neverLoggedInEnabled
    }
}

$report | Export-Csv -Path $outfile -NoTypeInformation
Write-Output "User account report saved to $outfile"
