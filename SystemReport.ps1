# ================================
# System Health Report Script
# ================================

$reportPath = "C:\SystemHealthReport.txt"
$report = @()

# --- (1) Disk Space Check on C: ---
$drive = Get-PSDrive -Name C
$total = $drive.Free + $drive.Used
$freePercent = [math]::Round(($drive.Free / $total) * 100, 2)

$report += "=== Disk Space Check (C:) ==="
$report += "Free Space: $([math]::Round($drive.Free / 1GB, 2)) GB"
$report += "Used Space: $([math]::Round($drive.Used / 1GB, 2)) GB"
$report += "Free Percentage: $freePercent%"

if ($freePercent -lt 20) {
    $report += "WARNING: Free disk space is below 20%."
} else {
    $report += "Disk space is within normal range."
}
$report += ""

# --- (2) Windows Defender Status ---
$defender = Get-MpComputerStatus

$report += "=== Windows Defender Status ==="
$report += "Real-Time Protection Enabled: $($defender.RealTimeProtectionEnabled)"
$report += "Antivirus Enabled: $($defender.AntivirusEnabled)"
$report += "Behavior Monitoring Enabled: $($defender.BehaviorMonitorEnabled)"
$report += ""

# --- (3) Top 10 CPU Processes ---
$report += "=== Top 10 Processes by CPU Usage ==="

$topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

foreach ($p in $topCPU) {
    $report += ("{0,-25} CPU: {1}" -f $p.ProcessName, $p.CPU)
}
$report += ""

# --- (4) Save Report ---
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Report saved to $reportPath"
