#!/bin/bash
PROJECT_DIR="/home/florianh/pr2/src/M122"

echo "==> Neuesten Code holen..."
cd "$PROJECT_DIR"
git stash
git pull

echo "==> Daten aktualisieren..."
bash "$PROJECT_DIR/daily-dashboard/scripts/update.sh"

echo "==> Server neustarten..."
pkill -f "http.server 8347" 2>/dev/null
sleep 1
nohup python3 -m http.server 8347 \
    --bind 127.0.0.1 \
    --directory "$PROJECT_DIR/daily-dashboard" \
    > "$PROJECT_DIR/daily-dashboard/logs/server.log" 2>&1 &
disown

echo ""
echo "Fertig! Dashboard laeuft auf http://localhost:8347/public/"
