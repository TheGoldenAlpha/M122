#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "Update gestartet: $(date)" >> "$LOG_DIR/update.log"
bash "$PROJECT_DIR/scripts/news.sh"
bash "$PROJECT_DIR/scripts/weather.sh"
bash "$PROJECT_DIR/scripts/crypto.sh"
echo "Update fertig: $(date)" >> "$LOG_DIR/update.log"
