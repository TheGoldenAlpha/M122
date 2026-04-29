#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/stocks.json"; TMP_FILE="$DATA_DIR/stocks.tmp"
TMPD=$(mktemp -d)

# Format: YAHOO|NAME|CURRENCY|MCAP
STOCKS=(
  "AAPL|Apple|USD|3000000000000"
  "NVDA|NVIDIA|USD|2800000000000"
  "MSFT|Microsoft|USD|2900000000000"
  "GOOGL|Alphabet|USD|2100000000000"
  "AMZN|Amazon|USD|2000000000000"
  "META|Meta|USD|1400000000000"
  "TSLA|Tesla|USD|800000000000"
  "TSM|TSMC|USD|900000000000"
  "AVGO|Broadcom|USD|800000000000"
  "LLY|Eli Lilly|USD|700000000000"
  "ORCL|Oracle|USD|400000000000"
  "NFLX|Netflix|USD|350000000000"
  "AMD|AMD|USD|250000000000"
  "CRM|Salesforce|USD|280000000000"
  "BRK-B|Berkshire Hathaway|USD|1000000000000"
  "JPM|JPMorgan|USD|600000000000"
  "V|Visa|USD|500000000000"
  "MA|Mastercard|USD|400000000000"
  "WMT|Walmart|USD|700000000000"
  "XOM|ExxonMobil|USD|500000000000"
  "COST|Costco|USD|400000000000"
  "HD|Home Depot|USD|350000000000"
  "UNH|UnitedHealth|USD|450000000000"
  "PG|P&G|USD|350000000000"
  "JNJ|J&J|USD|380000000000"
  "BAC|Bank of America|USD|300000000000"
  "KO|Coca-Cola|USD|280000000000"
  "MCD|McDonald's|USD|220000000000"
  "DIS|Disney|USD|190000000000"
  "NVO|Novo Nordisk|USD|400000000000"
  "NESN.SW|Nestlé|CHF|250000000000"
  "NOVN.SW|Novartis|CHF|220000000000"
  "ROG.SW|Roche|CHF|200000000000"
  "ABBN.SW|ABB|CHF|70000000000"
  "UBSG.SW|UBS|CHF|100000000000"
  "ASML.AS|ASML|EUR|300000000000"
  "SAP.DE|SAP|EUR|250000000000"
  "MC.PA|LVMH|EUR|300000000000"
  "OR.PA|L'Oréal|EUR|200000000000"
  "SIE.DE|Siemens|EUR|150000000000"
)

fetch_stock() {
  local idx="$1"
  local IFS='|'
  read -r yahoo name cur mcap <<< "${STOCKS[$idx]}"
  local raw
  raw=$(curl -sf --max-time 12 \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    "https://query1.finance.yahoo.com/v8/finance/chart/${yahoo}?interval=1d&range=2d") || return
  jq -e --arg sy "$yahoo" --arg nm "$name" --arg cu "$cur" --arg mc "$mcap" '
    .chart.result[0] |
    .meta as $m |
    ($m.regularMarketPrice) as $cl |
    ((.indicators.quote[0].open // []) | last // $m.chartPreviousClose) as $op |
    ((.indicators.quote[0].high // []) | last // $cl) as $hi |
    ((.indicators.quote[0].low  // []) | last // $cl) as $lo |
    select($cl != null and $cl != 0) |
    {
      symbol:        $sy,
      name:          $nm,
      price:         ($cl * 100 | round / 100),
      change:        (($cl - $op) * 100 | round / 100),
      changePercent: (if ($op // 0) != 0 then (($cl - $op) / $op * 10000 | round / 100) else 0 end),
      open:          ($op * 100 | round / 100),
      high:          ($hi * 100 | round / 100),
      low:           ($lo * 100 | round / 100),
      marketCap:     ($mc | tonumber),
      currency:      ($m.currency // $cu)
    }
  ' <<< "$raw" 2>/dev/null > "$TMPD/${idx}.json"
}

# Parallel in 10er-Batches
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
