#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
TMP_FILE="$DATA_DIR/news.tmp"
OUT_FILE="$DATA_DIR/news.json"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, xml.etree.ElementTree as ET, sys
from concurrent.futures import ThreadPoolExecutor

FEEDS = [
    ("SRF News",    "https://www.srf.ch/news/bnf/rss/1646"),
    ("SRF Schweiz", "https://www.srf.ch/news/bnf/rss/1890"),
    ("Blick",       "https://www.blick.ch/news/rss"),
    ("20 Minuten",  "https://www.20min.ch/rss/rss.tmpl?type=channel&get=1"),
    ("NZZ",         "https://www.nzz.ch/recent.rss"),
    ("Watson",      "https://www.watson.ch/api/feeds/rss"),
]

HEADERS = {"User-Agent": "Mozilla/5.0 (compatible; RSS-Reader)"}

def fetch_feed(source_url):
    source, url = source_url
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=10) as r:
            root = ET.fromstring(r.read())
        results = []
        for item in root.findall("./channel/item")[:4]:
            title = item.findtext("title", "").strip()
            link  = item.findtext("link",  "").strip()
            # Sicherstellen dass es keine Google-URL ist
            if title and link and "google.com" not in link:
                results.append({"title": title, "url": link, "source": source})
        return results
    except Exception:
        return []

with ThreadPoolExecutor(max_workers=6) as ex:
    all_items = []
    for result in ex.map(fetch_feed, FEEDS):
        all_items.extend(result)

# Mischung: je 2-3 pro Quelle, max 20 total
seen_titles = set()
items = []
for item in all_items:
    key = item["title"][:40]
    if key not in seen_titles:
        seen_titles.add(key)
        items.append(item)
    if len(items) >= 20:
        break

print(json.dumps({"items": items}, ensure_ascii=False))
sys.exit(0 if items else 1)
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [news] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [news] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
