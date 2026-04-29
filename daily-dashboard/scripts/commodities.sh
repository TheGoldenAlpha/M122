#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/commodities.json"; TMP_FILE="$DATA_DIR/commodities.tmp"
TMPD=$(mktemp -d)

# Format: YAHOO|STOOQ
COMMODITIES=(
  "GC=F|xauusd"   "SI=F|xagusd"   "PL=F|xptusd"   "PA=F|xpdusd"
  "HG=F|hg.f"     "CL=F|cl.f"     "BZ=F|co.f"     "NG=F|ng.f"
  "RB=F|rb.f"     "ZW=F|w.f"      "ZC=F|c.f"       "ZS=F|s.f"
  "ZO=F|o.f"      "ZR=F|rr.f"     "CC=F|cc.f"      "SB=F|sb.f"
  "CT=F|ct.f"
)

fetch_commodity() {
  local IFS='|'
  read -r yahoo stooq <<< "$1"
  local raw row open close
  raw=$(curl -sf --max-time 12 -A "Mozilla/5.0" \
    "https://stooq.com/q/l/?s=${stooq}&f=sd2t2ohlcv&h&e=csv") || return
  row=$(printf '%s\n' "$raw" | sed -n '2p')
  open=$(printf '%s' "$row"  | cut -d, -f4)
  close=$(printf '%s' "$row" | cut -d, -f7)
  [[ -z "$close" || "$close" == "N/D" || "$close" == "0" ]] && return
  awk -v sy="$yahoo" -v op="$open" -v cl="$close" 'BEGIN {
    ch  = cl - op
    chp = (op != 0) ? ch / op * 100 : 0
    printf "{\"symbol\":\"%s\",\"price\":%.4f,\"change\":%.4f,\"changePercent\":%.2f,\"currency\":\"USD\"}\n",
      sy, cl+0, ch, chp
  }' > "$TMPD/${yahoo//[^a-zA-Z0-9]/_}.json"
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

for entry in "${COMMODITIES[@]}"; do
  fetch_commodity "$entry" &
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
