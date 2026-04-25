#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/commodities.json"
TMP_FILE="$DATA_DIR/commodities.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, csv, io, json, sys
from concurrent.futures import ThreadPoolExecutor

# Stooq-Symbole für Rohstoffe (Yahoo-Symbol → Stooq-Symbol)
SYMBOLS = {
    "GC=F": "xauusd",   # Gold (Spot USD/oz)
    "SI=F": "xagusd",   # Silber (Spot USD/oz)
    "PL=F": "xptusd",   # Platin (Spot)
    "PA=F": "xpdusd",   # Palladium (Spot)
    "HG=F": "hg.f",     # Kupfer Futures
    "CL=F": "cl.f",     # Rohöl WTI Futures
    "BZ=F": "co.f",     # Rohöl Brent Futures
    "NG=F": "ng.f",     # Erdgas Futures
    "RB=F": "rb.f",     # Benzin RBOB Futures
    "ZW=F": "w.f",      # Weizen Futures
    "ZC=F": "c.f",      # Mais Futures
    "ZS=F": "s.f",      # Sojabohnen Futures
    "KC=F": "kc.f",     # Kaffee Futures
    "CC=F": "cc.f",     # Kakao Futures
    "SB=F": "sb.f",     # Zucker Futures
    "CT=F": "ct.f",     # Baumwolle Futures
    "OJ=F": "oj.f",     # Orangensaft Futures
}

def fetch(yahoo_sym):
    stooq = SYMBOLS.get(yahoo_sym)
    if not stooq:
        return None
    url = f"https://stooq.com/q/l/?s={stooq}&f=sd2t2ohlcv&h&e=csv"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=12) as r:
            text = r.read().decode()
        row = next(csv.DictReader(io.StringIO(text)), None)
        if not row:
            return None
        close = float(row.get("Close") or 0)
        open_ = float(row.get("Open") or 0)
        if close == 0:
            return None
        ch  = round(close - open_, 4)
        chp = round((ch / open_ * 100) if open_ else 0, 2)
        return {
            "symbol":        yahoo_sym,
            "price":         round(close, 4),
            "change":        ch,
            "changePercent": chp,
            "currency":      "USD",
        }
    except Exception:
        return None

with ThreadPoolExecutor(max_workers=6) as ex:
    results = [r for r in ex.map(fetch, SYMBOLS.keys()) if r]

if results:
    print(json.dumps(results, ensure_ascii=False))
    sys.exit(0)
else:
    print(json.dumps([]))
    sys.exit(1)
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ] && [ "$(cat "$TMP_FILE")" != "[]" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [commodities] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [commodities] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
