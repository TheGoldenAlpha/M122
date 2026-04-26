#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/sport.json"
TMP_FILE="$DATA_DIR/sport.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, xml.etree.ElementTree as ET
import html, re, sys
from concurrent.futures import ThreadPoolExecutor, as_completed

# Direkte Sport-RSS-Feeds (kein Google)
FEEDS = [
    "https://www.srf.ch/sport/bnf/rss/sport",
    "https://www.blick.ch/sport/rss",
    "https://www.nzz.ch/sport.rss",
    "https://www.watson.ch/sport/rss",
    "https://www.20min.ch/rss/rss.tmpl?type=channel&get=76",
    "https://feeds.bbci.co.uk/sport/rss.xml",
    "https://www.sport.de/news/ne4175943/rss.xml",
]

# Keyword-Klassifizierung: Artikel → Kategorie(n)
KEYWORDS = {
    "fussball": [
        "fussball", "fußball", "super league", "premier league", "bundesliga",
        "champions league", "europa league", "nationalteam", "nati ", "fc ", " fc",
        "goal", "tor ", "tore", "stürmer", "verteidiger", "fifa", "uefa",
        "serie a", "la liga", "ligue 1", "wm ", "em ", "weltmeister",
    ],
    "eishockey": [
        "eishockey", "ice hockey", "nhl", "nla", "swiss league",
        "playoff", "puck", "goalie", "schlittschuh", "power play",
    ],
    "unihockey": [
        "unihockey", "floorball", "nhc ",
    ],
    "handball": [
        "handball", "ehf", "ihf", "handballwm",
    ],
    "tennis": [
        "tennis", "atp ", " atp", "wta ", " wta", "wimbledon", "roland garros",
        "australian open", "us open", "davis cup", "federer", "nadal",
        "djokovic", "sinner", "alcaraz", "swiatek",
    ],
    "ski": [
        "ski alpin", "ski ", "slalom", "abfahrt", "super-g", "super g",
        "riesenslalom", "weltcup", "snowboard", "freeski", "skifahren",
        "kristoffersen", "hirscher", "odermatt", "gut-behrami",
    ],
    "leichtathletik": [
        "leichtathletik", "marathon", "sprint", "100 meter", "200 meter",
        "weitsprung", "hochsprung", "stabhochsprung", "diskus",
        "kugelstoß", "kugelstoessen", "athletics", "weltrekord lauf",
    ],
    "basketball": [
        "basketball", " nba", "nba-", "euroleague", "basket ",
    ],
    "formel1": [
        "formel 1", "formel1", " f1 ", "f1-", "grand prix", "gp ",
        "verstappen", "leclerc", "hamilton", "norris", "ferrari f1",
        "red bull racing", "mclaren f1", "mercedes f1", "motorsport",
    ],
    "volleyball": [
        "volleyball", "beachvolleyball", "beach volley",
    ],
}

def fetch_feed(url):
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "Mozilla/5.0 (AllMyDay Dashboard)"}
        )
        with urllib.request.urlopen(req, timeout=12) as r:
            raw = r.read()
        root = ET.fromstring(raw)
        items = []
        for item in root.findall("./channel/item"):
            title = item.findtext("title", "").strip()
            title = html.unescape(title)

            # Link: zuerst <link>, dann Atom-Style <link href="...">
            link = item.findtext("link", "").strip()
            if not link:
                link_el = item.find("link")
                if link_el is not None:
                    link = link_el.get("href", "").strip()

            # Fallback: hrefs aus description
            if not link or "google.com" in link:
                desc = html.unescape(item.findtext("description", ""))
                hrefs = re.findall(r'href="(https?://[^"]+)"', desc)
                link = next((h for h in hrefs if "google.com" not in h), None)

            if title and link and "google.com" not in link:
                items.append({"title": title, "url": link})
        return items
    except Exception as e:
        return []

def classify(title):
    t = title.lower()
    matched = []
    for cat, kws in KEYWORDS.items():
        if any(kw in t for kw in kws):
            matched.append(cat)
    return matched

# Alle Feeds parallel laden
all_items = []
with ThreadPoolExecutor(max_workers=7) as pool:
    futures = [pool.submit(fetch_feed, url) for url in FEEDS]
    for f in as_completed(futures):
        all_items.extend(f.result())

# Deduplizieren nach Titelstart (erste 50 Zeichen)
seen = set()
unique = []
for item in all_items:
    key = re.sub(r'\s+', ' ', item["title"])[:50].lower().strip()
    if key and key not in seen:
        seen.add(key)
        unique.append(item)

# In Kategorien einteilen (max. 15 pro Kategorie)
result = {cat: [] for cat in KEYWORDS}
for item in unique:
    for cat in classify(item["title"]):
        if len(result[cat]) < 15:
            result[cat].append(item)

print(json.dumps(result, ensure_ascii=False))
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [sport] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [sport] FEHLER (Status $STATUS)" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
