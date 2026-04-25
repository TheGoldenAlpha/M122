#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/weather.json"
TMP_FILE="$DATA_DIR/weather.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, sys

url = (
    "https://api.open-meteo.com/v1/forecast"
    "?latitude=47.3769&longitude=8.5417"
    "&current=temperature_2m,wind_speed_10m,precipitation"
    "&timezone=Europe%2FZurich"
)
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read())
    cur = data.get("current", {})
    result = {
        "city":        "Zürich",
        "temperature": round(cur.get("temperature_2m", 0), 1),
        "wind":        round(cur.get("wind_speed_10m", 0), 1),
        "rain":        round(cur.get("precipitation", 0), 1),
    }
    print(json.dumps(result, ensure_ascii=False))
    sys.exit(0)
except Exception as e:
    print(json.dumps({"city": "Zürich", "temperature": 0, "wind": 0, "rain": 0}), file=sys.stderr)
    print(json.dumps({"city": "Zürich", "temperature": 0, "wind": 0, "rain": 0}))
    sys.exit(1)
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [weather] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [weather] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
