#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"
OUT_FILE="$DATA_DIR/sport.json"
TMP_FILE="$DATA_DIR/sport.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, urllib.parse, json, xml.etree.ElementTree as ET

SPORTS = [
    ("fussball",        "Fussball Schweiz"),
    ("eishockey",       "Eishockey Schweiz NLA"),
    ("unihockey",       "Unihockey Floorball Schweiz"),
    ("handball",        "Handball Schweiz"),
    ("tennis",          "Tennis ATP WTA"),
    ("ski",             "Ski Alpin Schweiz"),
    ("leichtathletik",  "Leichtathletik"),
    ("basketball",      "Basketball NBA Schweiz"),
    ("formel1",         "Formel 1 F1"),
    ("volleyball",      "Volleyball Schweiz"),
]

result = {}
for key, query in SPORTS:
    try:
        url = ("https://news.google.com/rss/search?q="
               + urllib.parse.quote(query)
               + "&hl=de&gl=CH&ceid=CH:de")
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            xml_data = r.read()
        root = ET.fromstring(xml_data)
        items = []
        for item in root.findall("./channel/item")[:10]:
            title = item.findtext("title", "").strip()
            link  = item.findtext("link",  "").strip()
            if title:
                items.append({"title": title, "url": link})
        result[key] = items
    except Exception:
        result[key] = []

print(json.dumps(result, ensure_ascii=False))
PYEOF

mv "$TMP_FILE" "$OUT_FILE"
