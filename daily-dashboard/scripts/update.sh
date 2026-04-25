#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "========================================" >> "$LOG_DIR/update.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') Update gestartet" >> "$LOG_DIR/update.log"

run_script() {
    local name="$1"
    local script="$PROJECT_DIR/scripts/${name}.sh"
    local start=$(date +%s)
    bash "$script"
    local end=$(date +%s)
    echo "$(date '+%Y-%m-%d %H:%M:%S') [${name}] fertig in $((end - start))s" >> "$LOG_DIR/update.log"
}

run_script news
run_script weather
run_script crypto
run_script sport
run_script stocks
run_script coins

echo "$(date '+%Y-%m-%d %H:%M:%S') Update abgeschlossen" >> "$LOG_DIR/update.log"
echo "----------------------------------------" >> "$LOG_DIR/update.log"
