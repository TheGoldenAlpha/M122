#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"

# Format: KEY|NAME|LAT|LON
CITIES=(
  "zurich|Zürich|47.3769|8.5417"
  "bern|Bern|46.9481|7.4474"
  "basel|Basel|47.5596|7.5886"
  "genf|Genf|46.2044|6.1432"
  "lausanne|Lausanne|46.5197|6.6323"
  "luzern|Luzern|47.0502|8.3093"
  "stgallen|St. Gallen|47.4245|9.3767"
  "lugano|Lugano|46.0037|8.9511"
  "winterthur|Winterthur|47.4994|8.7240"
)

fetch_city() {
  local IFS='|'
  read -r key name lat lon <<< "$1"
  local raw
  raw=$(curl -sf --max-time 15 \
    "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&hourly=temperature_2m,wind_speed_10m,precipitation&current=temperature_2m,wind_speed_10m,precipitation&timezone=Europe%2FZurich&forecast_days=1") || return
  echo "$raw" | jq --arg city "$name" '{
    city:        $city,
    temperature: .current.temperature_2m,
    wind:        .current.wind_speed_10m,
    rain:        .current.precipitation,
    current:     .current,
    hourly:      .hourly
  }' > "$DATA_DIR/weather_${key}.json"
}

for entry in "${CITIES[@]}"; do
  fetch_city "$entry" &
done
wait

# weather.json = Zürich (für Übersicht-Widget)
if [ -f "$DATA_DIR/weather_zurich.json" ]; then
  cp "$DATA_DIR/weather_zurich.json" "$DATA_DIR/weather.json"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [weather] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [weather] FEHLER" >> "$LOG_DIR/update.log"
fi
