#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/sport.json"; TMP_FILE="$DATA_DIR/sport.tmp"
TMPD=$(mktemp -d)

FEEDS=(
  "https://www.srf.ch/sport/bnf/rss/sport"
  "https://www.blick.ch/sport/rss"
  "https://www.nzz.ch/sport.rss"
  "https://www.watson.ch/sport/rss"
  "https://www.20min.ch/rss/rss.tmpl?type=channel&get=76"
  "https://feeds.bbci.co.uk/sport/rss.xml"
  "https://www.sport.de/news/ne4175943/rss.xml"
)

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
  '
}

classify() {
  local t="${1,,}"
  echo "$t" | grep -qE 'fussball|fußball|super league|premier league|bundesliga|champions league|europa league|nati | fc |goal|tor |stürmer|fifa|uefa|serie a|la liga|wm |em ' && echo fussball
  echo "$t" | grep -qE 'eishockey|ice hockey|nhl|nla|swiss league|puck|goalie|power play' && echo eishockey
  echo "$t" | grep -qE 'unihockey|floorball' && echo unihockey
  echo "$t" | grep -qE 'handball|ehf |ihf ' && echo handball
  echo "$t" | grep -qE 'tennis|wimbledon|roland garros|australian open|us open|davis cup|federer|nadal|djokovic|sinner|alcaraz|swiatek' && echo tennis
  echo "$t" | grep -qE 'ski alpin|slalom|abfahrt|super-g|riesenslalom|snowboard|odermatt|gut-behrami|kristoffersen' && echo ski
  echo "$t" | grep -qE 'leichtathletik|marathon|sprint|100 meter|weitsprung|hochsprung|athletics' && echo leichtathletik
  echo "$t" | grep -qE 'basketball| nba|nba-|euroleague' && echo basketball
  echo "$t" | grep -qE 'formel 1|formel1| f1 |grand prix|verstappen|leclerc|hamilton|norris|motorsport' && echo formel1
  echo "$t" | grep -qE 'volleyball|beachvolleyball' && echo volleyball
}

for i in "${!FEEDS[@]}"; do
  ( raw=$(curl -sf --max-time 12 -A "Mozilla/5.0" "${FEEDS[$i]}") || exit
    printf '%s\n' "$raw" | rss_parse > "$TMPD/$i.tsv" ) &
done
wait

# Deduplicate all items
ALL="$TMPD/all.tsv"
find "$TMPD" -name "*.tsv" -exec cat {} \; 2>/dev/null \
  | awk -F'\t' '!seen[substr($1,1,50)]++' > "$ALL"

# Per-category buckets
CATS=(fussball eishockey unihockey handball tennis ski leichtathletik basketball formel1 volleyball)
declare -A cat_buf cat_cnt
for c in "${CATS[@]}"; do cat_buf[$c]=""; cat_cnt[$c]=0; done

while IFS=$'\t' read -r title url; do
  for cat in $(classify "$title"); do
    [ "${cat_cnt[$cat]}" -lt 15 ] || continue
    cat_buf[$cat]+=$(printf '{"title":%s,"url":%s},' \
      "$(printf '%s' "$title" | jq -Rsc '.')" \
      "$(printf '%s' "$url"   | jq -Rsc '.')")
    ((cat_cnt[$cat]++))
  done
done < "$ALL"

# Build JSON object
{
  printf '{'
  first=1
  for c in "${CATS[@]}"; do
    [ "$first" = "1" ] || printf ','
    first=0
    items="${cat_buf[$c]%,}"
    printf '"%s":[%s]' "$c" "$items"
  done
  printf '}'
} > "$TMP_FILE"

rm -rf "$TMPD"

if [ -s "$TMP_FILE" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [sport] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [sport] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi