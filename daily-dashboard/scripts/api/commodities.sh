#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/commodities.json"; TMP_FILE="$DATA_DIR/commodities.tmp"
TMPD=$(mktemp -d)

# Yahoo Finance futures symbols
COMMODITIES=(
  "GC=F" "SI=F" "PL=F" "PA=F"
  "HG=F" "CL=F" "BZ=F" "NG=F"
  "RB=F" "ZW=F" "ZC=F" "ZS=F"
  "ZO=F" "ZR=F" "CC=F" "SB=F"
  "CT=F"
)

fetch_commodity() {
  local sym="$1"
  local raw
  raw=$(curl -sf --max-time 12 \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    "https://query1.finance.yahoo.com/v8/finance/chart/${sym}?interval=1d&range=2d") || return
  echo "$raw" | jq -e --arg sy "$sym" '
    .chart.result[0] |
    .meta as $m |
    ($m.regularMarketPrice) as $cl |
    ((.indicators.quote[0].open // []) | last // $m.chartPreviousClose) as $op |
    select($cl != null and $cl != 0) | # Filter out invalid data points (leer)
    {
      symbol: $sy,
      price:  $cl,
      change: ($cl - $op),
      changePercent: (if ($op // 0) != 0 then ($cl - $op) / $op * 100 else 0 end),
      currency: $m.currency
    }
  ' 2>/dev/null > "$TMPD/${sym//[^a-zA-Z0-9]/_}.json"
}

fetch_electricity() {
  for bzn in CH DE-LU; do
    local raw
    raw=$(curl -sf --max-time 14 -A "Mozilla/5.0" \
      "https://api.energy-charts.info/price?bzn=${bzn}") || continue
    echo "$raw" | jq -e '
      (.price | to_entries | map(select(.value != null)) | last) as $last |
      (($last.key - 24) | if . >= 0 then . else null end) as $pi |
      {
        symbol:        "ELEC_EU",
        price:         $last.value,
        change:        (if $pi != null and .price[$pi] != null
                        then ($last.value - .price[$pi]) else 0 end),
        changePercent: (if $pi != null and (.price[$pi] // 0) != 0
                        then (($last.value - .price[$pi]) / .price[$pi] * 100)
                        else 0 end),
        currency:      "EUR"
      }
    ' 2>/dev/null > "$TMPD/ELEC_EU.json" && return
  done
}

batch=0
for sym in "${COMMODITIES[@]}"; do
  fetch_commodity "$sym" &
  (( ++batch % 6 == 0 )) && wait
done
fetch_electricity &
wait

jq -s '.' "$TMPD"/*.json 2>/dev/null > "$TMP_FILE"
rm -rf "$TMPD"

if [ -s "$TMP_FILE" ] && [ "$(cat "$TMP_FILE")" != "[]" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [commodities] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [commodities] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
