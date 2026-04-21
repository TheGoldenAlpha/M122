#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"
OUT_FILE="$DATA_DIR/stocks.json"
TMP_FILE="$DATA_DIR/stocks.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json

SYMBOLS = (
    "AAPL,MSFT,NVDA,GOOGL,AMZN,META,TSLA,BRK-B,JPM,V,"
    "NESN.SW,NOVN.SW,ROG.SW,ABBN.SW,UBSG.SW,"
    "ASML.AS,SAP.DE,MC.PA"
)

url = (
    "https://query1.finance.yahoo.com/v7/finance/quote?symbols=" + SYMBOLS
    + "&fields=regularMarketPrice,regularMarketChange,regularMarketChangePercent,"
    + "regularMarketOpen,regularMarketDayHigh,regularMarketDayLow,marketCap,currency,shortName"
)

req = urllib.request.Request(url, headers={
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
})

try:
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read())
    results = []
    for q in data.get("quoteResponse", {}).get("result", []):
        results.append({
            "symbol":        q.get("symbol", ""),
            "name":          q.get("shortName", q.get("symbol", "")),
            "price":         round(q.get("regularMarketPrice", 0), 2),
            "change":        round(q.get("regularMarketChange", 0), 2),
            "changePercent": round(q.get("regularMarketChangePercent", 0), 2),
            "open":          round(q.get("regularMarketOpen", 0), 2),
            "high":          round(q.get("regularMarketDayHigh", 0), 2),
            "low":           round(q.get("regularMarketDayLow", 0), 2),
            "marketCap":     q.get("marketCap", 0),
            "currency":      q.get("currency", "USD"),
        })
    print(json.dumps(results, ensure_ascii=False))
except Exception:
    print(json.dumps([]))
PYEOF

mv "$TMP_FILE" "$OUT_FILE"
