#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/stocks.json"
TMP_FILE="$DATA_DIR/stocks.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, sys, time

SYMBOLS = (
    # US Tech / Wachstum
    "AAPL,NVDA,MSFT,GOOGL,AMZN,META,TSLA,TSM,AVGO,LLY,"
    "ORCL,NFLX,AMD,CRM,"
    # US Finanzen / Konsum / Energie
    "BRK-B,JPM,V,MA,WMT,XOM,COST,HD,UNH,PG,JNJ,BAC,KO,MCD,DIS,NVO,"
    # Schweiz
    "NESN.SW,NOVN.SW,ROG.SW,ABBN.SW,UBSG.SW,"
    # Europa
    "ASML.AS,SAP.DE,MC.PA,OR.PA,SIE.DE"
)

HEADERS = {
    "User-Agent":      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept":          "application/json",
    "Accept-Language": "de-CH,de;q=0.9,en;q=0.8",
    "Referer":         "https://finance.yahoo.com/",
}

ENDPOINTS = [
    "https://query1.finance.yahoo.com/v7/finance/quote?symbols=" + SYMBOLS
    + "&fields=regularMarketPrice,regularMarketChange,regularMarketChangePercent,"
    + "regularMarketOpen,regularMarketDayHigh,regularMarketDayLow,marketCap,currency,shortName",

    "https://query2.finance.yahoo.com/v7/finance/quote?symbols=" + SYMBOLS
    + "&fields=regularMarketPrice,regularMarketChange,regularMarketChangePercent,"
    + "regularMarketOpen,regularMarketDayHigh,regularMarketDayLow,marketCap,currency,shortName",
]

data = None
for url in ENDPOINTS:
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=20) as r:
            raw = json.loads(r.read())
        quotes = raw.get("quoteResponse", {}).get("result", [])
        if quotes:
            data = quotes
            break
    except Exception:
        time.sleep(1)

if data:
    results = []
    for q in data:
        results.append({
            "symbol":        q.get("symbol", ""),
            "name":          q.get("shortName", q.get("symbol", "")),
            "price":         round(q.get("regularMarketPrice", 0) or 0, 2),
            "change":        round(q.get("regularMarketChange", 0) or 0, 2),
            "changePercent": round(q.get("regularMarketChangePercent", 0) or 0, 2),
            "open":          round(q.get("regularMarketOpen", 0) or 0, 2),
            "high":          round(q.get("regularMarketDayHigh", 0) or 0, 2),
            "low":           round(q.get("regularMarketDayLow", 0) or 0, 2),
            "marketCap":     q.get("marketCap", 0) or 0,
            "currency":      q.get("currency", "USD"),
        })
    print(json.dumps(results, ensure_ascii=False))
    sys.exit(0)
else:
    print(json.dumps([]))
    sys.exit(1)
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ] && [ "$(cat "$TMP_FILE")" != "[]" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] FEHLER (Yahoo Finance blockiert oder kein Markt)" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
