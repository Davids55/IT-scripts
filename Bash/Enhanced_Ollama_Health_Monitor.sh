#!/usr/bin/env bash
# ollama-health-monitor.sh
# Requires: curl, jq, ss or netstat, mailx or sendmail for alerts
# Place approved models in /etc/ollama/approved_models.txt (one per line)

APPROVED="/etc/ollama/approved_models.txt"
LOG="/var/log/ollama-health.log"
ALERT_EMAIL="it-admin@terravalleyusd.local"
OLLAMA_API="http://127.0.0.1:11434"   # local default; change if different

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

echo "$(timestamp) - Starting Ollama health check" >> "$LOG"

# 1) Check Ollama process
if ! pgrep -f ollama >/dev/null; then
  echo "$(timestamp) - Ollama process not running" >> "$LOG"
  echo "Ollama process not running on $(hostname) at $(timestamp)" | mailx -s "ALERT: Ollama down on $(hostname)" "$ALERT_EMAIL"
  exit 2
fi

# 2) Check API binding (ss or netstat)
if command -v ss >/dev/null; then
  BINDINGS=$(ss -ltnp | grep -E '11434|ollama' || true)
else
  BINDINGS=$(netstat -ltnp | grep -E '11434|ollama' || true)
fi

echo "$(timestamp) - Bindings: $BINDINGS" >> "$LOG"

# Detect 0.0.0.0 binding
if echo "$BINDINGS" | grep -q "0.0.0.0:11434"; then
  echo "$(timestamp) - WARNING: Ollama API bound to 0.0.0.0" >> "$LOG"
  echo "Ollama API exposed on 0.0.0.0 on $(hostname) at $(timestamp). Immediate action required." | mailx -s "CRITICAL: Ollama API exposed on $(hostname)" "$ALERT_EMAIL"
fi

# 3) Query Ollama models endpoint (assumes /v1/models or /models)
MODELS_JSON=$(curl -s --max-time 5 "$OLLAMA_API/v1/models" || curl -s --max-time 5 "$OLLAMA_API/models" || echo "{}")
if [ "$MODELS_JSON" = "{}" ]; then
  echo "$(timestamp) - Could not fetch models list from Ollama API" >> "$LOG"
else
  # Extract model names (adjust parsing to Ollama's response format)
  MODEL_NAMES=$(echo "$MODELS_JSON" | jq -r '.[]?.name // .[]?.model // .[]?.id' 2>/dev/null | sort -u)
  echo "$(timestamp) - Models present: $MODEL_NAMES" >> "$LOG"

  # Load approved list
  if [ -f "$APPROVED" ]; then
    mapfile -t APPROVED_LIST < "$APPROVED"
  else
    echo "$(timestamp) - Approved list not found at $APPROVED" >> "$LOG"
    APPROVED_LIST=()
  fi

  # Check for unauthorized models
  UNAUTHORIZED=()
  for m in $MODEL_NAMES; do
    ok=false
    for a in "${APPROVED_LIST[@]}"; do
      if [ "$m" = "$a" ]; then ok=true; break; fi
    done
    if [ "$ok" = false ]; then UNAUTHORIZED+=("$m"); fi
  done

  if [ ${#UNAUTHORIZED[@]} -gt 0 ]; then
    echo "$(timestamp) - Unauthorized models detected: ${UNAUTHORIZED[*]}" >> "$LOG"
    echo "Unauthorized Ollama models detected on $(hostname): ${UNAUTHORIZED[*]}" | mailx -s "ALERT: Unauthorized Ollama models on $(hostname)" "$ALERT_EMAIL"
  fi
fi

echo "$(timestamp) - Ollama health check complete" >> "$LOG"
exit 0
