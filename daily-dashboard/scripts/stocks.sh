#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/stocks.json"; TMP_FILE="$DATA_DIR/stocks.tmp"
TMPD=$(mktemp -d)

# Format: YAHOO|STOOQ|NAME|CURRENCY|MCAP
STOCKS=(
  "AAPL|aapl.us|Apple|USD|3000000000000"
  "NVDA|nvda.us|NVIDIA|USD|2800000000000"
  "MSFT|msft.us|Microsoft|USD|2900000000000"
  "GOOGL|googl.us|Alphabet|USD|2100000000000"
  "AMZN|amzn.us|Amazon|USD|2000000000000"
  "META|meta.us|Meta|USD|1400000000000"
  "TSLA|tsla.us|Tesla|USD|800000000000"
  "TSM|tsm.us|TSMC|USD|900000000000"
  "AVGO|avgo.us|Broadcom|USD|800000000000"
  "LLY|lly.us|Eli Lilly|USD|700000000000"
  "ORCL|orcl.us|Oracle|USD|400000000000"
  "NFLX|nflx.us|Netflix|USD|350000000000"
  "AMD|amd.us|AMD|USD|250000000000"
  "CRM|crm.us|Salesforce|USD|280000000000"
  "BRK-B|brk-b.us|Berkshire Hathaway|USD|1000000000000"
  "JPM|jpm.us|JPMorgan|USD|600000000000"
  "V|v.us|Visa|USD|500000000000"
  "MA|ma.us|Mastercard|USD|400000000000"
  "WMT|wmt.us|Walmart|USD|700000000000"
  "XOM|xom.us|ExxonMobil|USD|500000000000"
  "COST|cost.us|Costco|USD|400000000000"
  "HD|hd.us|Home Depot|USD|350000000000"
  "UNH|unh.us|UnitedHealth|USD|450000000000"
  "PG|pg.us|P&G|USD|350000000000"
  "JNJ|jnj.us|J&J|USD|380000000000"
  "BAC|bac.us|Bank of America|USD|300000000000"
  "KO|ko.us|Coca-Cola|USD|280000000000"
  "MCD|mcd.us|McDonald's|USD|220000000000"
  "DIS|dis.us|Disney|USD|190000000000"
  "NVO|nvo.us|Novo Nordisk|USD|400000000000"
  "NESN.SW|nesn.sw|Nestlé|CHF|250000000000"
  "NOVN.SW|novn.sw|Novartis|CHF|220000000000"
  "ROG.SW|rog.sw|Roche|CHF|200000000000"
  "ABBN.SW|abbn.sw|ABB|CHF|70000000000"
  "UBSG.SW|ubsg.sw|UBS|CHF|100000000000"
  "ASML.AS|asml.nl|ASML|EUR|300000000000"
  "SAP.DE|sap.de|SAP|EUR|250000000000"
  "MC.PA|mc.fr|LVMH|EUR|300000000000"
  "OR.PA|or.fr|L'Oréal|EUR|200000000000"
  "SIE.DE|sie.de|Siemens|EUR|150000000000"
)

fetch_stock() {
  local idx="$1"
  local IFS='|'
  read -r yahoo stooq name cur mcap <<< "${STOCKS[$idx]}"
  local raw row open high low close
  raw=$(curl -sf --max-time 12 -A "Mozilla/5.0" \
    "https://stooq.com/q/l/?s=${stooq}&f=sd2t2ohlcv&h&e=csv") || return
  row=$(printf '%s\n' "$raw" | sed -n '2p')
  open=$(printf '%s' "$row"  | cut -d, -f4)
  high=$(printf '%s' "$row"  | cut -d, -f5)
  low=$( printf '%s' "$row"  | cut -d, -f6)
  close=$(printf '%s' "$row" | cut -d, -f7)
  [[ -z "$close" || "$close" == "N/D" || "$close" == "0" ]] && return
  awk -v sy="$yahoo" -v nm="$name" -v op="$open" -v hi="$high" \
      -v lo="$low"   -v cl="$close" -v cu="$cur" -v mc="$mcap" 'BEGIN {
    ch  = cl - op
    chp = (op != 0) ? ch / op * 100 : 0
    printf "{\"symbol\":\"%s\",\"name\":\"%s\",\"price\":%.2f,\"change\":%.2f,\"changePercent\":%.2f,\"open\":%.2f,\"high\":%.2f,\"low\":%.2f,\"marketCap\":%s,\"currency\":\"%s\"}\n",
      sy, nm, cl+0, ch, chp, op+0, hi+0, lo+0, mc, cu
  }' > "$TMPD/${idx}.json"
}

# Parallel in 10er-Batches (wie Python max_workers=10)
batch=0
for i in "${!STOCKS[@]}"; do
  fetch_stock "$i" &
  (( ++batch % 10 == 0 )) && wait
done
wait

jq -s '.' "$TMPD"/*.json 2>/dev/null > "$TMP_FILE"
rm -rf "$TMPD"

if [ -s "$TMP_FILE" ] && [ "$(cat "$TMP_FILE")" != "[]" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
