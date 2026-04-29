#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/coins.json"; TMP_FILE="$DATA_DIR/coins.tmp"

IDS="bitcoin,ethereum,solana,binancecoin,ripple,cardano,avalanche-2,polkadot,chainlink,dogecoin,litecoin,uniswap"
URL="https://api.coingecko.com/api/v3/coins/markets?vs_currency=chf&ids=${IDS}&order=market_cap_desc&per_page=12&page=1&sparkline=false"

RAW=""
for i in 1 2 3; do
  RAW=$(curl -sf --max-time 20 -A "Mozilla/5.0" "$URL") && break
  sleep 3
done

if [ -n "$RAW" ] && echo "$RAW" | jq -e '.[0]' > /dev/null 2>&1; then
  echo "$RAW" | jq '[.[] | {
    id,
    symbol:        (.symbol | ascii_upcase),
    name,
    image,
    price:         (.current_price           // 0),
    change:        (.price_change_24h         // 0),
    changePercent: (.price_change_percentage_24h // 0),
    marketCap:     (.market_cap              // 0),
    volume24h:     (.total_volume            // 0),
    high24h:       (.high_24h                // 0),
    low24h:        (.low_24h                 // 0)
  }]' > "$TMP_FILE"
fi

if [ -s "$TMP_FILE" ] && [ "$(cat "$TMP_FILE")" != "[]" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [coins] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [coins] FEHLER (CoinGecko Rate-Limit oder Netzwerkfehler)" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
