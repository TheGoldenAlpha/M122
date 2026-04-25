#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/coins.json"
TMP_FILE="$DATA_DIR/coins.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, sys, time

IDS = (
    "bitcoin,ethereum,solana,binancecoin,ripple,cardano,"
    "avalanche-2,polkadot,chainlink,dogecoin,litecoin,uniswap"
)

url = (
    "https://api.coingecko.com/api/v3/coins/markets"
    "?vs_currency=chf"
    "&ids=" + IDS
    + "&order=market_cap_desc&per_page=12&page=1&sparkline=false"
)

req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

for attempt in range(3):
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            status = r.getcode()
            raw = r.read()
        if status == 429:
            time.sleep(5)
            continue
        data = json.loads(raw)
        results = []
        for c in data:
            results.append({
                "id":            c["id"],
                "symbol":        c["symbol"].upper(),
                "name":          c["name"],
                "image":         c.get("image", ""),
                "price":         c.get("current_price", 0) or 0,
                "change":        round(c.get("price_change_24h", 0) or 0, 4),
                "changePercent": round(c.get("price_change_percentage_24h", 0) or 0, 2),
                "marketCap":     c.get("market_cap", 0) or 0,
                "volume24h":     c.get("total_volume", 0) or 0,
                "high24h":       c.get("high_24h", 0) or 0,
                "low24h":        c.get("low_24h", 0) or 0,
            })
        print(json.dumps(results, ensure_ascii=False))
        sys.exit(0)
    except Exception as e:
        time.sleep(3)

print(json.dumps([]))
sys.exit(1)
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ] && [ "$(cat "$TMP_FILE")" != "[]" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [coins] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [coins] FEHLER (CoinGecko Rate-Limit oder Netzwerkfehler)" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
