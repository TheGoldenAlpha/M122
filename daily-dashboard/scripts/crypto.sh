#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/crypto.json"
TMP_FILE="$DATA_DIR/crypto.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, sys

url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=chf"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read())
    result = {
        "bitcoin_chf":  data.get("bitcoin",  {}).get("chf", 0),
        "ethereum_chf": data.get("ethereum", {}).get("chf", 0),
        "solana_chf":   data.get("solana",   {}).get("chf", 0),
    }
    print(json.dumps(result, ensure_ascii=False))
    sys.exit(0)
except Exception as e:
    print(json.dumps({"bitcoin_chf": 0, "ethereum_chf": 0, "solana_chf": 0}), file=sys.stderr)
    print(json.dumps({"bitcoin_chf": 0, "ethereum_chf": 0, "solana_chf": 0}))
    sys.exit(1)
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [crypto] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [crypto] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
