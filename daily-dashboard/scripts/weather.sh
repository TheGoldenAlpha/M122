#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/weather.json"; TMP_FILE="$DATA_DIR/weather.tmp"

RAW=$(curl -sf --max-time 15 \
  "https://api.open-meteo.com/v1/forecast?latitude=47.3769&longitude=8.5417&current=temperature_2m,wind_speed_10m,precipitation&timezone=Europe%2FZurich")

if [ -n "$RAW" ] && echo "$RAW" | jq -e '.current' > /dev/null 2>&1; then
  echo "$RAW" | jq '{
    city:        "Zürich",
    temperature: .current.temperature_2m,
    wind:        .current.wind_speed_10m,
    rain:        .current.precipitation
  }' > "$TMP_FILE"
fi

if [ -s "$TMP_FILE" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [weather] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [weather] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
