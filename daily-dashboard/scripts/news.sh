#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/news.json"; TMP_FILE="$DATA_DIR/news.tmp"
TMPD=$(mktemp -d)

# Format: SOURCE|URL
FEEDS=(
  "SRF News|https://www.srf.ch/news/bnf/rss/1646"
  "SRF Schweiz|https://www.srf.ch/news/bnf/rss/1890"
  "Blick|https://www.blick.ch/news/rss"
  "20 Minuten|https://www.20min.ch/rss/rss.tmpl?type=channel&get=1"
  "NZZ|https://www.nzz.ch/recent.rss"
  "Watson|https://www.watson.ch/api/feeds/rss"
)

# Parse RSS/Atom XML: outputs "title\tlink" per item (max 8)
rss_parse() {
  sed 's|<link\([^>]*\)href="\([^"]*\)"\([^/]*\)/>|<link>\2</link>|g' \
  | awk '
    /<item[ >]|<entry[ >]/ { in_item=1; t=""; l="" }
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
    /<\/item>|<\/entry>/ { if (in_item && t && l) print t "\t" l; in_item=0 }
  ' | head -8
}

fetch_feed() {
  local IFS='|'; read -r source url <<< "$1"
  local raw
  raw=$(curl -sf --max-time 10 -A "Mozilla/5.0 (compatible; RSS-Reader)" "$url") || return
  printf '%s\n' "$raw" | rss_parse | while IFS=$'\t' read -r title link; do
    printf '%s\t%s\t%s\n' "$title" "$link" "$source"
  done > "$TMPD/${2}.tsv"
}

for i in "${!FEEDS[@]}"; do
  fetch_feed "${FEEDS[$i]}" "$i" &
done
wait

# Deduplicate by title prefix (55 chars), limit 20, build JSON
find "$TMPD" -name "*.tsv" -exec cat {} \; 2>/dev/null \
  | awk -F'\t' '!seen[substr($1,1,55)]++ && NR<=60' \
  | head -20 \
  | jq -Rsc '
      split("\n") | map(select(. != "") | split("\t") | select(length >= 3) |
        {title: .[0], url: .[1], source: .[2]}) |
      {items: .}
    ' > "$TMP_FILE"

rm -rf "$TMPD"

if [ -s "$TMP_FILE" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [news] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [news] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
