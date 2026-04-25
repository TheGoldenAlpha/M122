#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/commodities.json"
TMP_FILE="$DATA_DIR/commodities.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, urllib.parse, json, sys, time, http.cookiejar

SYMBOLS = ["GC=F","SI=F","PL=F","PA=F","HG=F","CL=F","BZ=F","NG=F","RB=F","ZW=F","ZC=F"]

HEADERS = {
    "User-Agent":      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept":          "application/json,text/html,*/*;q=0.9",
    "Accept-Language": "de-CH,de;q=0.9,en;q=0.8",
    "Referer":         "https://finance.yahoo.com/",
}

# Session mit Cookie-Unterstützung
cj = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))

# Yahoo-Homepage besuchen → Cookies holen
try:
    opener.open(urllib.request.Request("https://finance.yahoo.com/", headers=HEADERS), timeout=12)
except Exception:
    pass

# Crumb holen
crumb = ""
for crumb_url in [
    "https://query1.finance.yahoo.com/v1/test/getcrumb",
    "https://query2.finance.yahoo.com/v1/test/getcrumb",
]:
    try:
        with opener.open(urllib.request.Request(crumb_url, headers=HEADERS), timeout=10) as r:
            crumb = r.read().decode().strip()
        if crumb:
            break
    except Exception:
        pass

symbols_str = urllib.parse.quote(",".join(SYMBOLS))
fields = "regularMarketPrice,regularMarketChange,regularMarketChangePercent,currency,shortName"
crumb_param = f"&crumb={urllib.parse.quote(crumb)}" if crumb else ""

data = None
for base in ["https://query1.finance.yahoo.com", "https://query2.finance.yahoo.com"]:
    for ver in ["v8", "v7"]:
        url = f"{base}/{ver}/finance/quote?symbols={symbols_str}&fields={fields}{crumb_param}"
        try:
            with opener.open(urllib.request.Request(url, headers=HEADERS), timeout=20) as r:
                raw = json.loads(r.read())
            quotes = raw.get("quoteResponse", {}).get("result", [])
            if quotes:
                data = quotes
                break
        except Exception:
            time.sleep(1)
    if data:
        break

if data:
    results = []
    for q in data:
        results.append({
            "symbol":        q.get("symbol", ""),
            "price":         round(q.get("regularMarketPrice", 0) or 0, 4),
            "change":        round(q.get("regularMarketChange", 0) or 0, 4),
            "changePercent": round(q.get("regularMarketChangePercent", 0) or 0, 2),
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
    echo "$(date '+%Y-%m-%d %H:%M:%S') [commodities] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [commodities] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
