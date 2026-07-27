# Script 1 — System Health Check
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
if (!(Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" | Out-Null }

$outfile = "C:\Temp\healthcheck_$timestamp.txt"

$report = @()

# --- Disk Space Check ---
$report += "=== Disk Space Check ==="
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $freePct = [math]::Round(($_.Free / $_.Used) * 100, 2)
    $warn = if ($freePct -lt 20) { " **WARNING: Low disk space**" } else { "" }
    $report += "Drive $($_.Name): Free = $freePct%$warn"
}

# --- CPU Usage (30-second average) ---
$report += "`n=== CPU Usage (30-second average) ==="
$cpuSamples = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 30
$cpuAvg = [math]::Round(($cpuSamples.CounterSamples | Measure-Object -Property CookedValue -Average).Average, 2)
$cpuWarn = if ($cpuAvg -gt 80) { " **WARNING: High CPU usage**" } else { "" }
$report += "Average CPU Usage: $cpuAvg%$cpuWarn"

# --- Memory Check ---
$report += "`n=== Memory Check ==="
$os = Get-CimInstance Win32_OperatingSystem
$freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 2)
$memWarn = if ($freeMB -lt 500) { " **WARNING: Low memory**" } else { "" }
$report += "Free Memory: $freeMB MB$memWarn"

# --- Top 5 CPU Processes ---
$report += "`n=== Top 5 Processes by CPU ==="
$topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
$topCPU | ForEach-Object {
    $report += "Process: $($_.Name) - CPU: $($_.CPU)"
}

# --- Write Report ---
$report | Out-File -FilePath $outfile -Encoding UTF8
Write-Output "Health check complete. Report saved to $outfile"
