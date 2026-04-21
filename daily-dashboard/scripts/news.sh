#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"

TMP_FILE="$DATA_DIR/news.tmp"
OUT_FILE="$DATA_DIR/news.json"

curl -s "https://news.google.com/rss?hl=de&gl=CH&ceid=CH:de" \
| grep -oP '<title>.*?</title>' \
| sed 's/<title>//g; s/<\/title>//g' \
| tail -n +2 \
| head -n 10 \
| jq -R . \
| jq -s '{items: map({title: .})}' > "$TMP_FILE"

mv "$TMP_FILE" "$OUT_FILE"
