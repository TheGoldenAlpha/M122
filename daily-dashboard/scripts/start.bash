#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "========================================"
echo "  AllMyDay Dashboard – Server starten"
echo "========================================"
echo ""

# Sudo-Cache leeren, damit immer eine Passwort-Eingabe erzwungen wird
sudo -k

echo "Bitte sudo-Passwort eingeben, um den Webserver zu starten:"
if ! sudo -v; then
    echo ""
    echo "Falsches Passwort oder abgebrochen. Server wird NICHT gestartet."
    exit 1
fi

echo ""
echo "Authentifizierung erfolgreich."
echo ""

# Laufenden Server stoppen (falls vorhanden)
if pgrep -f "http.server 8347" > /dev/null 2>&1; then
    echo "Stoppe laufenden Server..."
    pkill -f "http.server 8347" 2>/dev/null
    sleep 1
fi

# Server starten (läuft als normaler User, kein sudo nötig)
echo "Starte Webserver auf http://localhost:8347/public/ ..."
nohup python3 -m http.server 8347 \
    --bind 127.0.0.1 \
    --directory "$PROJECT_DIR/public" \
    > "$LOG_DIR/server.log" 2>&1 &
disown

echo ""
echo "Server gestartet! Dashboard: http://localhost:8347/public/"
echo "Logs: $LOG_DIR/server.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') Server gestartet" >> "$LOG_DIR/update.log"
