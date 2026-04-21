#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"
OUT_FILE="$DATA_DIR/weather.json"

DATA=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=47.3769&longitude=8.5417&current=temperature_2m,wind_speed_10m,precipitation&timezone=Europe%2FZurich")

TEMP=$(echo "$DATA" | jq -r '.current.temperature_2m')
WIND=$(echo "$DATA" | jq -r '.current.wind_speed_10m')
RAIN=$(echo "$DATA" | jq -r '.current.precipitation')

cat > "$OUT_FILE" <<EOF
{
  "city": "Zürich",
  "temperature": "$TEMP",
  "wind": "$WIND",
  "rain": "$RAIN"
}
EOF
