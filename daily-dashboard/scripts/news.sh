#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"

TMP_FILE="$DATA_DIR/news.tmp"
OUT_FILE="$DATA_DIR/news.json"

RSS=$(curl -s "https://news.google.com/rss?hl=de&gl=CH&ceid=CH:de")

echo "$RSS" | python3 -c "
import sys, json, xml.etree.ElementTree as ET
root = ET.fromstring(sys.stdin.read())
items = []
for item in root.findall('./channel/item')[:15]:
    title = item.findtext('title', '').strip()
    link  = item.findtext('link', '').strip()
    if title:
        items.append({'title': title, 'url': link})
print(json.dumps({'items': items}, ensure_ascii=False))
" > "$TMP_FILE"

mv "$TMP_FILE" "$OUT_FILE"
