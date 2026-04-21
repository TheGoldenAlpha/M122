#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"
OUT_FILE="$DATA_DIR/coins.json"
TMP_FILE="$DATA_DIR/coins.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json

url = (
    "https://api.coingecko.com/api/v3/coins/markets"
    "?vs_currency=chf"
    "&ids=bitcoin,ethereum,solana,binancecoin,ripple,cardano,"
    "avalanche-2,polkadot,chainlink,dogecoin,litecoin,uniswap"
    "&order=market_cap_desc&per_page=12&page=1&sparkline=false"
)

req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read())
    results = []
    for c in data:
        results.append({
            "id":            c["id"],
            "symbol":        c["symbol"].upper(),
            "name":          c["name"],
            "image":         c.get("image", ""),
            "price":         c.get("current_price", 0),
            "change":        round(c.get("price_change_24h", 0) or 0, 4),
            "changePercent": round(c.get("price_change_percentage_24h", 0) or 0, 2),
            "marketCap":     c.get("market_cap", 0),
            "volume24h":     c.get("total_volume", 0),
            "high24h":       c.get("high_24h", 0),
            "low24h":        c.get("low_24h", 0),
        })
    print(json.dumps(results, ensure_ascii=False))
except Exception:
    print(json.dumps([]))
PYEOF

mv "$TMP_FILE" "$OUT_FILE"
