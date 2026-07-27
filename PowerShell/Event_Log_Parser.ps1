# Script 3 — Event Log Parser
$since = (Get-Date).AddHours(-24)

Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level   = 2        # Error
    StartTime = $since
} | Select-Object TimeCreated, Id, LevelDisplayName, Message
