#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/sport.json"
TMP_FILE="$DATA_DIR/sport.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, urllib.parse, json, xml.etree.ElementTree as ET
import html, re, sys
from concurrent.futures import ThreadPoolExecutor, as_completed

SPORTS = [
    ("fussball",       "Fussball Schweiz"),
    ("eishockey",      "Eishockey Schweiz NLA"),
    ("unihockey",      "Unihockey Floorball Schweiz"),
    ("handball",       "Handball Schweiz"),
    ("tennis",         "Tennis ATP WTA"),
    ("ski",            "Ski Alpin Schweiz"),
    ("leichtathletik", "Leichtathletik"),
    ("basketball",     "Basketball NBA"),
    ("formel1",        "Formel 1 F1"),
    ("volleyball",     "Volleyball Schweiz"),
]

def fetch_sport(key_query):
    key, query = key_query
    try:
        url = (
            "https://news.google.com/rss/search?q="
            + urllib.parse.quote(query)
            + "&hl=de&gl=CH&ceid=CH:de"
        )
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=12) as r:
            xml_data = r.read()
        root = ET.fromstring(xml_data)
        items = []
        for item in root.findall("./channel/item")[:10]:
            title = item.findtext("title", "").strip()
            # Echte Artikel-URL aus der HTML-Description extrahieren
            desc  = html.unescape(item.findtext("description", ""))
            match = re.search(r'href="(https?://[^"]+)"', desc)
            link  = match.group(1) if match else item.findtext("link", "").strip()
            if title:
                items.append({"title": title, "url": link})
        return key, items
    except Exception:
        return key, []

result = {}
with ThreadPoolExecutor(max_workers=10) as pool:
    futures = {pool.submit(fetch_sport, sp): sp[0] for sp in SPORTS}
    for future in as_completed(futures):
        key, items = future.result()
        result[key] = items

print(json.dumps(result, ensure_ascii=False))
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [sport] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [sport] FEHLER" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
