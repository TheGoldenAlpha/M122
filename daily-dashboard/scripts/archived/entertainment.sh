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

# Parse RSS/Atom: outputs "title\turl\tdate\tdesc\timage" per item (max 25)
rss_parse_ent() {
  sed 's|<link\([^>]*\)href="\([^"]*\)"\([^/]*\)/>|<link>\2</link>|g' \
  | awk '
    /<item[ >]|<entry[ >]/ { in_item=1; t=""; l=""; dt=""; ds=""; img="" }
    in_item && /<title/ {
      s=$0; gsub(/.*<title[^>]*>(<!\[CDATA\[)?/,"",s); gsub(/(\]\]>)?<\/title>.*/,"",s)
      gsub(/&amp;/,"\\&",s); gsub(/&lt;/,"<",s); gsub(/&gt;/,">",s)
      gsub(/^[[:space:]]*/,"",s); gsub(/[[:space:]]*$/,"",s)
      if (s) t=s
    }
    in_item && /<link>/ {
      s=$0; gsub(/.*<link>/,"",s); gsub(/<\/link>.*/,"",s)
      gsub(/^[[:space:]]*/,"",s)
      if (s ~ /^https?:/ && s !~ /google\.com/) l=s
    }
    in_item && /<pubDate/ && !dt {
      s=$0; gsub(/.*<pubDate>/,"",s); gsub(/<\/pubDate>.*/,"",s)
      gsub(/^[[:space:]]*/,"",s); dt=substr(s,1,16)
    }
    in_item && /<description/ && !ds {
      s=$0; gsub(/.*<description[^>]*>(<!\[CDATA\[)?/,"",s); gsub(/(\]\]>)?<\/description>.*/,"",s)
      gsub(/<[^>]*>/,"",s); gsub(/&amp;/,"\\&",s); gsub(/&lt;/,"<",s); gsub(/&gt;/,">",s)
      gsub(/[[:space:]]+/," ",s); gsub(/^[[:space:]]*/,"",s)
      ds=substr(s,1,200)
    }
    in_item && !img && /url="http/ {
      s=$0; gsub(/.*url="/,"",s); gsub(/".*/,"",s)
      if (s ~ /\.(jpg|jpeg|png|webp)/ && s !~ /\.gif/) img=s
    }
    /<\/item>|<\/entry>/ {
      if (in_item && t && l) print t "\t" l "\t" dt "\t" ds "\t" img
      in_item=0
    }
  ' | head -25
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
