#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/stocks.json"
TMP_FILE="$DATA_DIR/stocks.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, csv, io, json, sys
from concurrent.futures import ThreadPoolExecutor

# Stooq-Symbole (Yahoo-Symbol → Stooq-Symbol)
SYMBOLS = {
    "AAPL":    "aapl.us",   "NVDA":    "nvda.us",   "MSFT":  "msft.us",
    "GOOGL":   "googl.us",  "AMZN":    "amzn.us",   "META":  "meta.us",
    "TSLA":    "tsla.us",   "TSM":     "tsm.us",    "AVGO":  "avgo.us",
    "LLY":     "lly.us",    "ORCL":    "orcl.us",   "NFLX":  "nflx.us",
    "AMD":     "amd.us",    "CRM":     "crm.us",    "BRK-B": "brk-b.us",
    "JPM":     "jpm.us",    "V":       "v.us",      "MA":    "ma.us",
    "WMT":     "wmt.us",    "XOM":     "xom.us",    "COST":  "cost.us",
    "HD":      "hd.us",     "UNH":     "unh.us",    "PG":    "pg.us",
    "JNJ":     "jnj.us",    "BAC":     "bac.us",    "KO":    "ko.us",
    "MCD":     "mcd.us",    "DIS":     "dis.us",    "NVO":   "nvo.us",
    "NESN.SW": "nesn.sw",   "NOVN.SW": "novn.sw",   "ROG.SW":"rog.sw",
    "ABBN.SW": "abbn.sw",   "UBSG.SW": "ubsg.sw",
    "ASML.AS": "asml.nl",   "SAP.DE":  "sap.de",
    "MC.PA":   "mc.fr",     "OR.PA":   "or.fr",     "SIE.DE":"sie.de",
}

NAMES = {
    "AAPL":"Apple","NVDA":"NVIDIA","MSFT":"Microsoft","GOOGL":"Alphabet","AMZN":"Amazon",
    "META":"Meta","TSLA":"Tesla","TSM":"TSMC","AVGO":"Broadcom","LLY":"Eli Lilly",
    "ORCL":"Oracle","NFLX":"Netflix","AMD":"AMD","CRM":"Salesforce",
    "BRK-B":"Berkshire Hathaway","JPM":"JPMorgan","V":"Visa","MA":"Mastercard",
    "WMT":"Walmart","XOM":"ExxonMobil","COST":"Costco","HD":"Home Depot",
    "UNH":"UnitedHealth","PG":"P&G","JNJ":"J&J","BAC":"Bank of America",
    "KO":"Coca-Cola","MCD":"McDonald's","DIS":"Disney","NVO":"Novo Nordisk",
    "NESN.SW":"Nestlé","NOVN.SW":"Novartis","ROG.SW":"Roche","ABBN.SW":"ABB","UBSG.SW":"UBS",
    "ASML.AS":"ASML","SAP.DE":"SAP","MC.PA":"LVMH","OR.PA":"L'Oréal","SIE.DE":"Siemens",
}

CURRENCY = {
    "NESN.SW":"CHF","NOVN.SW":"CHF","ROG.SW":"CHF","ABBN.SW":"CHF","UBSG.SW":"CHF",
    "ASML.AS":"EUR","SAP.DE":"EUR","MC.PA":"EUR","OR.PA":"EUR","SIE.DE":"EUR",
}

# Ungefähre Marktkapitalisierung (für Sortierung, in USD)
MCAP = {
    "AAPL":3.0e12,"NVDA":2.8e12,"MSFT":2.9e12,"GOOGL":2.1e12,"AMZN":2.0e12,
    "META":1.4e12,"TSLA":8e11,"TSM":9e11,"AVGO":8e11,"LLY":7e11,
    "ORCL":4e11,"NFLX":3.5e11,"AMD":2.5e11,"CRM":2.8e11,
    "BRK-B":1.0e12,"JPM":6e11,"V":5e11,"MA":4e11,"WMT":7e11,"XOM":5e11,
    "COST":4e11,"HD":3.5e11,"UNH":4.5e11,"PG":3.5e11,"JNJ":3.8e11,
    "BAC":3e11,"KO":2.8e11,"MCD":2.2e11,"DIS":1.9e11,"NVO":4e11,
    "NESN.SW":2.5e11,"NOVN.SW":2.2e11,"ROG.SW":2.0e11,"ABBN.SW":7e10,"UBSG.SW":1.0e11,
    "ASML.AS":3e11,"SAP.DE":2.5e11,"MC.PA":3e11,"OR.PA":2.0e11,"SIE.DE":1.5e11,
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
        high  = float(row.get("High") or 0)
        low   = float(row.get("Low") or 0)
        if close == 0:
            return None
        ch  = round(close - open_, 2)
        chp = round((ch / open_ * 100) if open_ else 0, 2)
        return {
            "symbol":        yahoo_sym,
            "name":          NAMES.get(yahoo_sym, yahoo_sym),
            "price":         round(close, 2),
            "change":        ch,
            "changePercent": chp,
            "open":          round(open_, 2),
            "high":          round(high, 2),
            "low":           round(low, 2),
            "marketCap":     MCAP.get(yahoo_sym, 0),
            "currency":      CURRENCY.get(yahoo_sym, "USD"),
        }
    except Exception:
        return None

with ThreadPoolExecutor(max_workers=10) as ex:
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
    echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
