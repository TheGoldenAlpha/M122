#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/crypto.json"; TMP_FILE="$DATA_DIR/crypto.tmp"

RAW=$(curl -sf --max-time 15 -A "Mozilla/5.0" \
  "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=chf")

if [ -n "$RAW" ] && echo "$RAW" | jq -e '.bitcoin' > /dev/null 2>&1; then
  echo "$RAW" | jq '{
    bitcoin_chf:  .bitcoin.chf,
    ethereum_chf: .ethereum.chf,
    solana_chf:   .solana.chf
  }' > "$TMP_FILE"
fi

if [ -s "$TMP_FILE" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [crypto] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [crypto] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
