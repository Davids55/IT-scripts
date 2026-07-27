#!/usr/bin/env bash

### ------------------------------------------------------------
###  OLLAMA HEALTH CHECKS
### ------------------------------------------------------------

echo "=== OLLAMA HEALTH CHECK ==="

STATUS=0   # 0 = healthy, 1 = warning, 2 = critical

# 1. Is the Ollama service running?
SERVICE_STATUS=$(systemctl is-active ollama 2>/dev/null)
if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo "Ollama service running: PASS"
else
    echo "Ollama service running: FAIL"
    STATUS=2
fi

# 2. Is Ollama bound to 127.0.0.1?
BIND_CHECK=$(ss -tuln | grep ":11434" | awk '{print $5}' | grep -v "127.0.0.1")
if [[ -z "$BIND_CHECK" ]]; then
    echo "Ollama bound to 127.0.0.1: PASS"
else
    echo "Ollama bound to 127.0.0.1: FAIL (bound to $BIND_CHECK)"
    STATUS=2
fi

# 3. Is the Ollama API responding?
API_CHECK=$(curl -s http://localhost:11434/api/tags)
if [[ -n "$API_CHECK" ]]; then
    echo "Ollama API responding: PASS"
else
    echo "Ollama API responding: FAIL"
    STATUS=2
fi

# 4. How many models are installed?
MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
echo "Models installed: $MODEL_COUNT"

# 5. Is model disk usage below 80%?
MODEL_DIR="/usr/share/ollama"   # adjust if needed
if [[ -d "$MODEL_DIR" ]]; then
    USAGE=$(df "$MODEL_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
    if (( USAGE < 80 )); then
        echo "Model disk usage < 80%: PASS ($USAGE%)"
    else
        echo "Model disk usage < 80%: FAIL ($USAGE%)"
        STATUS=1
    fi
else
    echo "Model directory not found: WARNING"
    STATUS=1
fi

# 6. Any ERROR entries in Ollama journal in last hour?
ERRORS=$(journalctl -u ollama --since "1 hour ago" | grep -i "error")
if [[ -z "$ERRORS" ]]; then
    echo "No ERROR entries in last hour: PASS"
else
    echo "ERROR entries found in last hour: FAIL"
    STATUS=1
fi

# Final summary
echo "=== SUMMARY ==="
if [[ $STATUS -eq 0 ]]; then
    echo "SYSTEM HEALTH: HEALTHY"
elif [[ $STATUS -eq 1 ]]; then
    echo "SYSTEM HEALTH: WARNING"
else
    echo "SYSTEM HEALTH: CRITICAL"
fi


### ------------------------------------------------------------
###  USER AUDIT
### ------------------------------------------------------------

echo ""
echo "=== USER AUDIT ==="

# 1. List all users with login shells
echo "Users with login shells:"
awk -F: '$7 !~ /(nologin|false)/ {print $1}' /etc/passwd

# 2. Check which have sudo rights
echo ""
echo "Users with sudo rights:"
grep -Po '^sudo.+:\K.*' /etc/group | tr ',' '\n'

# 3. Flag any user with UID 0 other than root
echo ""
echo "UID 0 users (should only be root):"
awk -F: '$3 == 0 && $1 != "root" {print "WARNING: "$1" has UID 0"}' /etc/passwd
