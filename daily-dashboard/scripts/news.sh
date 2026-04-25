#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
TMP_FILE="$DATA_DIR/news.tmp"
OUT_FILE="$DATA_DIR/news.json"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, xml.etree.ElementTree as ET, sys

url = "https://news.google.com/rss?hl=de&gl=CH&ceid=CH:de"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    with urllib.request.urlopen(req, timeout=15) as r:
        xml_data = r.read()
    root = ET.fromstring(xml_data)
    items = []
    for item in root.findall("./channel/item")[:15]:
        title = item.findtext("title", "").strip()
        link  = item.findtext("link",  "").strip()
        if title:
            items.append({"title": title, "url": link})
    print(json.dumps({"items": items}, ensure_ascii=False))
    sys.exit(0)
except Exception as e:
    print(json.dumps({"items": []}), file=sys.stderr)
    print(json.dumps({"items": []}))
    sys.exit(1)
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [news] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [news] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
