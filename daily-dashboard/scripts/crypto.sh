#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"
OUT_FILE="$DATA_DIR/crypto.json"

DATA=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=chf")

BTC=$(echo "$DATA" | jq -r '.bitcoin.chf')
ETH=$(echo "$DATA" | jq -r '.ethereum.chf')
SOL=$(echo "$DATA" | jq -r '.solana.chf')

cat > "$OUT_FILE" <<EOF
{
  "bitcoin_chf": "$BTC",
  "ethereum_chf": "$ETH",
  "solana_chf": "$SOL"
}
EOF
