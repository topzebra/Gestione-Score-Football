#!/usr/bin/env bash
set -euo pipefail

SERVER_URL="${SERVER_URL:-http://92.5.62.91:9000}"
AGENT_SECRET="${AGENT_SECRET:-codespace-secret-key-2026}"
AGENT_DIR="/tmp/codespace-agent"

echo "=== Configurazione Automatica Agente Codespace ==="
echo "Server target: ${SERVER_URL}"

mkdir -p "${AGENT_DIR}"

echo "Download agente protetto da password..."
if curl -s -f -H "X-Agent-Secret: ${AGENT_SECRET}" \
  "${SERVER_URL}/api/agent/download" -o "${AGENT_DIR}/agent.py"; then
  echo "Agente scaricato con successo."
else
  echo "Errore durante il download dell'agente."
  exit 1
fi

chmod +x "${AGENT_DIR}/agent.py"

curl -s -f -H "X-Agent-Secret: ${AGENT_SECRET}" \
  "${SERVER_URL}/api/agent/download-vt-client" -o "${AGENT_DIR}/vt_client.py" || true

AGENT_ID="cs-${CODESPACE_NAME:-$(hostname)}"

echo "Avvio agente in background (ID: ${AGENT_ID})..."
nohup python3 "${AGENT_DIR}/agent.py" \
  --server "${SERVER_URL}" \
  --secret "${AGENT_SECRET}" \
  --agent-id "${AGENT_ID}" \
  --threads 4 \
  > "${AGENT_DIR}/agent.log" 2>&1 &

echo "Agente Codespace operativo in background."
