#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/entertainment.json"
TMP_FILE="$DATA_DIR/entertainment.tmp"

python3 - << 'PYEOF' > "$TMP_FILE"
import urllib.request, json, xml.etree.ElementTree as ET
import html, re, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
import email.utils

GAMING_FEEDS = [
    ("IGN",               "https://feeds.ign.com/ign/articles"),
    ("GameSpot",          "https://www.gamespot.com/feeds/news/"),
    ("Kotaku",            "https://kotaku.com/rss"),
    ("Eurogamer",         "https://www.eurogamer.net/?format=rss"),
    ("Rock Paper Shotgun","https://www.rockpapershotgun.com/feed/"),
    ("PC Gamer",          "https://www.pcgamer.com/rss/"),
]

MOVIE_FEEDS = [
    ("Screen Rant",         "https://screenrant.com/feed/"),
    ("Collider",            "https://collider.com/feed/"),
    ("The Hollywood Reporter", "https://www.hollywoodreporter.com/feed/"),
    ("IGN Movies",          "https://feeds.ign.com/ign/articles"),
    ("Variety",             "https://variety.com/feed/"),
]

MOVIE_KEYWORDS = [
    "film", "movie", "kino", "trailer", "streaming", "netflix", "disney+",
    "amazon prime", "hbo", "serie", "series", "tv show", "season", "episode",
    "box office", "cast", "director", "premiere", "review", "cinema",
    "marvel", "dc comics", "pixar", "star wars", "oscar", "golden globe",
]

def parse_date(raw):
    if not raw:
        return ""
    try:
        dt = email.utils.parsedate_to_datetime(raw)
        return dt.strftime("%d.%m.%Y")
    except Exception:
        pass
    try:
        for fmt in ("%a, %d %b %Y %H:%M:%S %z", "%Y-%m-%dT%H:%M:%S%z"):
            try:
                return datetime.strptime(raw[:25], fmt).strftime("%d.%m.%Y")
            except Exception:
                pass
    except Exception:
        pass
    return raw[:10]

def clean_text(t):
    t = html.unescape(t or "")
    t = re.sub(r'<[^>]+>', '', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t

def get_image(item):
    # media:content
    for ns in [
        '{http://search.yahoo.com/mrss/}content',
        '{http://search.yahoo.com/mrss/}thumbnail',
    ]:
        el = item.find(ns)
        if el is not None:
            url = el.get('url', '')
            if url and not url.endswith('.gif'):
                return url
    # enclosure
    enc = item.find('enclosure')
    if enc is not None:
        url = enc.get('url', '')
        if url and re.search(r'\.(jpg|jpeg|png|webp)', url, re.I):
            return url
    # first img in description
    desc = item.findtext('description', '') or ''
    imgs = re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', desc, re.I)
    for img in imgs:
        if not img.endswith('.gif') and img.startswith('http'):
            return img
    return ""

def fetch_feed(name_url):
    name, url = name_url
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "Mozilla/5.0 (AllMyDay Dashboard)"}
        )
        with urllib.request.urlopen(req, timeout=14) as r:
            raw = r.read()
        ET.register_namespace('media', 'http://search.yahoo.com/mrss/')
        root = ET.fromstring(raw)
        items = []
        for item in root.findall("./channel/item")[:25]:
            title = clean_text(item.findtext("title", ""))
            link  = item.findtext("link", "").strip()
            if not link:
                link_el = item.find("link")
                if link_el is not None:
                    link = link_el.get("href", "").strip()
            desc  = clean_text(item.findtext("description", ""))[:200]
            date  = parse_date(item.findtext("pubDate", ""))
            image = get_image(item)
            if title and link and "google.com" not in link:
                items.append({
                    "title":  title,
                    "url":    link,
                    "source": name,
                    "date":   date,
                    "desc":   desc,
                    "image":  image,
                })
        return name, items
    except Exception as e:
        return name, []

def is_movie_article(title):
    t = title.lower()
    return any(kw in t for kw in MOVIE_KEYWORDS)

# Gaming-Feeds laden
gaming_items = []
with ThreadPoolExecutor(max_workers=6) as pool:
    futures = [pool.submit(fetch_feed, f) for f in GAMING_FEEDS]
    for f in as_completed(futures):
        _, items = f.result()
        gaming_items.extend(items)

# Movie-Feeds laden (IGN-Artikel nach Movie-Keywords filtern)
movie_items_raw = []
with ThreadPoolExecutor(max_workers=5) as pool:
    futures = [pool.submit(fetch_feed, f) for f in MOVIE_FEEDS]
    for f in as_completed(futures):
        name, items = f.result()
        for item in items:
            if name != "IGN Movies" or is_movie_article(item["title"]):
                movie_items_raw.append(item)

def dedup(items):
    seen = set()
    out = []
    for item in items:
        key = re.sub(r'\s+', ' ', item["title"])[:55].lower()
        if key not in seen:
            seen.add(key)
            out.append(item)
    return out[:30]

result = {
    "gaming": dedup(gaming_items),
    "movies": dedup(movie_items_raw),
}

print(json.dumps(result, ensure_ascii=False))
PYEOF

STATUS=$?
if [ $STATUS -eq 0 ] && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [entertainment] OK" >> "$LOG_DIR/update.log"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [entertainment] FEHLER (Status $STATUS)" >> "$LOG_DIR/update.log"
    rm -f "$TMP_FILE"
fi
