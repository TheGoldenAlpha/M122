#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/entertainment.json"; TMP_FILE="$DATA_DIR/entertainment.tmp"
TMPD=$(mktemp -d)

# Format: SOURCE|URL|CATEGORY
FEEDS=(
  "IGN|https://feeds.ign.com/ign/articles|gaming"
  "GameSpot|https://www.gamespot.com/feeds/news/|gaming"
  "Kotaku|https://kotaku.com/rss|gaming"
  "Eurogamer|https://www.eurogamer.net/?format=rss|gaming"
  "PC Gamer|https://www.pcgamer.com/rss/|gaming"
  "Screen Rant|https://screenrant.com/feed/|movies"
  "Collider|https://collider.com/feed/|movies"
  "Hollywood Reporter|https://www.hollywoodreporter.com/feed/|movies"
  "Variety|https://variety.com/feed/|movies"
)

# RSS/Atom parsen mit Node.js — gibt "title\turl\tdate\tdesc\timage" pro item aus (max 25)
rss_parse_ent() {
  node << 'EOF'
let raw = '';
process.stdin.on('data', d => raw += d);
process.stdin.on('end', () => {
  const tag   = (s, t) => (s.match(new RegExp(`<${t}[^>]*>(?:<!\\[CDATA\\[)?([\\s\\S]*?)(?:\\]\\]>)?<\\/${t}>`, 'i')) || [])[1] || '';
  const clean = s => s.replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/\s+/g, ' ').trim();
  const items = raw.split(/<item[ >]|<entry[ >]/i).slice(1);
  let count = 0;
  for (const item of items) {
    if (count >= 25) break;
    const title = clean(tag(item, 'title'));
    const url   = clean(tag(item, 'link')) || (item.match(/href="(https?[^"]+)"/) || [])[1] || '';
    const date  = clean(tag(item, 'pubDate') || tag(item, 'updated')).slice(0, 16);
    const desc  = clean(tag(item, 'description') || tag(item, 'summary')).slice(0, 200);
    const img   = (item.match(/url="(https?[^"]+\.(?:jpg|jpeg|png|webp))"/i) || [])[1] || '';
    if (title && url.startsWith('http')) {
      process.stdout.write(`${title}\t${url}\t${date}\t${desc}\t${img}\n`);
      count++;
    }
  }
});
EOF
}

fetch_feed() {
  local IFS='|'; read -r source url cat_name <<< "$1"
  local raw
  raw=$(curl -sf --max-time 14 -A "Mozilla/5.0 (AllMyDay Dashboard)" "$url") || return
  printf '%s\n' "$raw" | rss_parse_ent | while IFS=$'\t' read -r title link date desc img; do
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$source" "$cat_name" "$title" "$link" "$date" "$desc" "$img"
  done > "$TMPD/${2}.tsv"
}

for i in "${!FEEDS[@]}"; do
  fetch_feed "${FEEDS[$i]}" "$i" &
done
wait

find "$TMPD" -name "*.tsv" -exec cat {} \; 2>/dev/null > "$TMPD/all.tsv"

build_cat() {
  local cat="$1"
  awk -F'\t' -v c="$cat" '$2 == c && !seen[substr($3,1,55)]++' "$TMPD/all.tsv" \
    | head -30 \
    | jq -Rsc 'split("\n") | map(select(. != "") | split("\t") | select(length >= 7) |
        {source:.[0], title:.[2], url:.[3], date:.[4], desc:.[5], image:.[6]})'
}

printf '{"gaming":%s,"movies":%s}\n' "$(build_cat gaming)" "$(build_cat movies)" > "$TMP_FILE"

rm -rf "$TMPD"

if [ -s "$TMP_FILE" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [entertainment] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [entertainment] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
