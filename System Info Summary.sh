#!/bin/bash

# === System Info Summary Script ===
DATE=$(date +"%Y-%m-%d")
OUTFILE="$HOME/sysinfo_${DATE}.txt"

{
    echo "===== System Info Summary ($DATE) ====="
    echo

    # Hostname, IP, OS, Kernel, Uptime
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I | awk '{print $1}')"
    echo "OS Version: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
    echo "Kernel Version: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo

    # Disk usage with >80% flagged
    echo "===== Disk Usage (Flagging >80%) ====="
    df -h --output=source,pcent,target | tail -n +2 | while read line; do
        PCT=$(echo "$line" | awk '{print $2}' | tr -d '%')
        if [ "$PCT" -gt 80 ]; then
            echo "WARNING: $line"
        else
            echo "$line"
        fi
    done
    echo

    # Memory info
    echo "===== Memory Info ====="
    free -h
    echo

    # CPU model
    echo "===== CPU Model ====="
    grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'
    echo

} > "$OUTFILE"

echo "System info written to: $OUTFILE"
