#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"; LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$DATA_DIR" "$LOG_DIR"
OUT_FILE="$DATA_DIR/stocks.json"; TMP_FILE="$DATA_DIR/stocks.tmp"
TMPD=$(mktemp -d)

# Format: YAHOO|NAME|CURRENCY|MCAP
STOCKS=(
  # ── USA · Technologie ───────────────────────────────────────────
  "AAPL|Apple|USD|3000000000000"
  "NVDA|NVIDIA|USD|2800000000000"
  "MSFT|Microsoft|USD|2900000000000"
  "GOOGL|Alphabet|USD|2100000000000"
  "AMZN|Amazon|USD|2000000000000"
  "META|Meta|USD|1400000000000"
  "TSLA|Tesla|USD|800000000000"
  "AVGO|Broadcom|USD|800000000000"
  "ORCL|Oracle|USD|400000000000"
  "NFLX|Netflix|USD|350000000000"
  "AMD|AMD|USD|250000000000"
  "CRM|Salesforce|USD|280000000000"
  "ADBE|Adobe|USD|230000000000"
  "CSCO|Cisco|USD|200000000000"
  "IBM|IBM|USD|200000000000"
  "ACN|Accenture|USD|200000000000"
  "INTC|Intel|USD|90000000000"
  "QCOM|Qualcomm|USD|170000000000"
  "TXN|Texas Instruments|USD|160000000000"
  "MU|Micron Technology|USD|100000000000"
  "AMAT|Applied Materials|USD|140000000000"
  "NOW|ServiceNow|USD|200000000000"
  "INTU|Intuit|USD|170000000000"
  "PANW|Palo Alto Networks|USD|120000000000"
  "CRWD|CrowdStrike|USD|80000000000"
  "SHOP|Shopify|USD|130000000000"
  "UBER|Uber|USD|160000000000"
  "PLTR|Palantir|USD|200000000000"
  "ARM|ARM Holdings|USD|150000000000"
  "LRCX|Lam Research|USD|90000000000"
  "KLAC|KLA Corp|USD|80000000000"
  "SNPS|Synopsys|USD|90000000000"
  "CDNS|Cadence Design|USD|85000000000"
  "MRVL|Marvell Technology|USD|60000000000"
  "COIN|Coinbase|USD|60000000000"
  "SPOT|Spotify|USD|90000000000"
  "NET|Cloudflare|USD|40000000000"
  "DDOG|Datadog|USD|40000000000"
  "ZS|Zscaler|USD|30000000000"
  "WDAY|Workday|USD|55000000000"
  "SNOW|Snowflake|USD|45000000000"
  "DELL|Dell Technologies|USD|55000000000"
  "APP|AppLovin|USD|120000000000"
  # ── USA · Finanzen ──────────────────────────────────────────────
  "BRK-B|Berkshire Hathaway|USD|1000000000000"
  "JPM|JPMorgan|USD|600000000000"
  "V|Visa|USD|500000000000"
  "MA|Mastercard|USD|400000000000"
  "BAC|Bank of America|USD|300000000000"
  "GS|Goldman Sachs|USD|180000000000"
  "MS|Morgan Stanley|USD|160000000000"
  "C|Citigroup|USD|130000000000"
  "WFC|Wells Fargo|USD|220000000000"
  "AXP|American Express|USD|200000000000"
  "BLK|BlackRock|USD|140000000000"
  "SCHW|Charles Schwab|USD|130000000000"
  "BX|Blackstone|USD|180000000000"
  "SPGI|S&P Global|USD|140000000000"
  "ICE|Intercontinental Exchange|USD|80000000000"
  "MSCI|MSCI Inc|USD|40000000000"
  "PYPL|PayPal|USD|70000000000"
  # ── USA · Konsum / Handel ───────────────────────────────────────
  "WMT|Walmart|USD|700000000000"
  "COST|Costco|USD|400000000000"
  "HD|Home Depot|USD|350000000000"
  "MCD|McDonald's|USD|220000000000"
  "KO|Coca-Cola|USD|280000000000"
  "PG|P&G|USD|350000000000"
  "DIS|Disney|USD|190000000000"
  "PEP|PepsiCo|USD|200000000000"
  "TGT|Target|USD|60000000000"
  "LOW|Lowe's|USD|150000000000"
  "SBUX|Starbucks|USD|100000000000"
  "NKE|Nike|USD|120000000000"
  "TJX|TJX Companies|USD|130000000000"
  "BKNG|Booking Holdings|USD|150000000000"
  "ABNB|Airbnb|USD|85000000000"
  "CMG|Chipotle|USD|90000000000"
  "PM|Philip Morris|USD|200000000000"
  "MO|Altria|USD|90000000000"
  "F|Ford|USD|45000000000"
  "GM|General Motors|USD|55000000000"
  # ── USA · Gesundheit / Pharma ───────────────────────────────────
  "UNH|UnitedHealth|USD|450000000000"
  "JNJ|J&J|USD|380000000000"
  "LLY|Eli Lilly|USD|700000000000"
  "ABBV|AbbVie|USD|350000000000"
  "MRK|Merck|USD|250000000000"
  "PFE|Pfizer|USD|160000000000"
  "AMGN|Amgen|USD|150000000000"
  "GILD|Gilead Sciences|USD|100000000000"
  "REGN|Regeneron|USD|100000000000"
  "VRTX|Vertex Pharma|USD|120000000000"
  "ISRG|Intuitive Surgical|USD|180000000000"
  "TMO|Thermo Fisher|USD|200000000000"
  "DHR|Danaher|USD|150000000000"
  "MDT|Medtronic|USD|100000000000"
  "ZTS|Zoetis|USD|80000000000"
  "NVO|Novo Nordisk|USD|400000000000"
  # ── USA · Industrie / Energie ───────────────────────────────────
  "XOM|ExxonMobil|USD|500000000000"
  "CVX|Chevron|USD|290000000000"
  "COP|ConocoPhillips|USD|130000000000"
  "SLB|Schlumberger|USD|60000000000"
  "RTX|RTX Corp|USD|180000000000"
  "LMT|Lockheed Martin|USD|140000000000"
  "NOC|Northrop Grumman|USD|70000000000"
  "GE|GE Aerospace|USD|240000000000"
  "CAT|Caterpillar|USD|170000000000"
  "DE|John Deere|USD|130000000000"
  "HON|Honeywell|USD|130000000000"
  "BA|Boeing|USD|120000000000"
  "UPS|UPS|USD|100000000000"
  "FDX|FedEx|USD|60000000000"
  "ETN|Eaton|USD|120000000000"
  "MMM|3M|USD|50000000000"
  "LIN|Linde|USD|220000000000"
  "UNP|Union Pacific|USD|150000000000"
  "WM|Waste Management|USD|80000000000"
  "NEE|NextEra Energy|USD|140000000000"
  "AMT|American Tower|USD|90000000000"
  "PLD|Prologis|USD|100000000000"
  "SHW|Sherwin-Williams|USD|90000000000"
  # ── USA · Telekommunikation ─────────────────────────────────────
  "T|AT&T|USD|170000000000"
  "VZ|Verizon|USD|160000000000"
  "TMUS|T-Mobile|USD|250000000000"
  # ── USA · Emerging (US-kotiert) ─────────────────────────────────
  "TSM|TSMC|USD|900000000000"
  "BABA|Alibaba|USD|250000000000"
  "PDD|PDD Holdings|USD|150000000000"
  "MELI|MercadoLibre|USD|90000000000"
  "SE|Sea Limited|USD|40000000000"
  "INFY|Infosys|USD|70000000000"
  "HDB|HDFC Bank|USD|150000000000"
  "VALE|Vale|USD|60000000000"
  "PBR|Petrobras|USD|70000000000"
  "ITUB|Itaú Unibanco|USD|60000000000"
  # ── Schweiz ─────────────────────────────────────────────────────
  "NESN.SW|Nestlé|CHF|250000000000"
  "NOVN.SW|Novartis|CHF|220000000000"
  "ROG.SW|Roche|CHF|200000000000"
  "ABBN.SW|ABB|CHF|70000000000"
  "UBSG.SW|UBS|CHF|100000000000"
  "ZURN.SW|Zurich Insurance|CHF|70000000000"
  "SREN.SW|Swiss Re|CHF|35000000000"
  "LONN.SW|Lonza|CHF|40000000000"
  "GIVN.SW|Givaudan|CHF|25000000000"
  "SCMN.SW|Swisscom|CHF|25000000000"
  "BAER.SW|Julius Bär|CHF|12000000000"
  "PGHN.SW|Partners Group|CHF|20000000000"
  "SIKA.SW|Sika|CHF|35000000000"
  "GEBN.SW|Geberit|CHF|20000000000"
  "SLHN.SW|Swiss Life|CHF|15000000000"
  "LOGN.SW|Logitech|CHF|18000000000"
  # ── Deutschland ─────────────────────────────────────────────────
  "SAP.DE|SAP|EUR|250000000000"
  "SIE.DE|Siemens|EUR|150000000000"
  "ALV.DE|Allianz|EUR|120000000000"
  "BMW.DE|BMW|EUR|60000000000"
  "MBG.DE|Mercedes-Benz|EUR|60000000000"
  "VOW3.DE|Volkswagen|EUR|60000000000"
  "BAS.DE|BASF|EUR|40000000000"
  "BAY.DE|Bayer|EUR|30000000000"
  "ADS.DE|Adidas|EUR|35000000000"
  "DTE.DE|Deutsche Telekom|EUR|100000000000"
  "MUV2.DE|Munich Re|EUR|60000000000"
  "DBK.DE|Deutsche Bank|EUR|30000000000"
  "IFX.DE|Infineon|EUR|30000000000"
  "RWE.DE|RWE|EUR|25000000000"
  "P911.DE|Porsche AG|EUR|50000000000"
  # ── Frankreich ──────────────────────────────────────────────────
  "MC.PA|LVMH|EUR|300000000000"
  "OR.PA|L'Oréal|EUR|200000000000"
  "TTE.PA|TotalEnergies|EUR|150000000000"
  "BNP.PA|BNP Paribas|EUR|80000000000"
  "SAN.PA|Sanofi|EUR|120000000000"
  "AIR.PA|Airbus|EUR|120000000000"
  "RMS.PA|Hermès|EUR|200000000000"
  "SU.PA|Schneider Electric|EUR|120000000000"
  "CS.PA|AXA|EUR|80000000000"
  "AI.PA|Air Liquide|EUR|90000000000"
  "DSY.PA|Dassault Systèmes|EUR|35000000000"
  "BN.PA|Danone|EUR|40000000000"
  "KER.PA|Kering|EUR|30000000000"
  "HO.PA|Thales|EUR|30000000000"
  "SGO.PA|Saint-Gobain|EUR|25000000000"
  # ── Niederlande ─────────────────────────────────────────────────
  "ASML.AS|ASML|EUR|300000000000"
  "UNA.AS|Unilever|EUR|120000000000"
  "INGA.AS|ING|EUR|50000000000"
  "AD.AS|Ahold Delhaize|EUR|30000000000"
  "HEIA.AS|Heineken|EUR|40000000000"
  "REN.AS|RELX|EUR|80000000000"
  "WKL.AS|Wolters Kluwer|EUR|25000000000"
  "PHIA.AS|Philips|EUR|15000000000"
  # ── Grossbritannien ─────────────────────────────────────────────
  "AZN.L|AstraZeneca|GBP|200000000000"
  "SHEL.L|Shell|GBP|180000000000"
  "HSBA.L|HSBC|GBP|170000000000"
  "BP.L|BP|GBP|90000000000"
  "ULVR.L|Unilever UK|GBP|120000000000"
  "GSK.L|GSK|GBP|70000000000"
  "DGE.L|Diageo|GBP|60000000000"
  "RIO.L|Rio Tinto|GBP|100000000000"
  "GLEN.L|Glencore|GBP|50000000000"
  "VOD.L|Vodafone|GBP|25000000000"
  "LLOY.L|Lloyds Banking|GBP|40000000000"
  # ── Italien ─────────────────────────────────────────────────────
  "ENI.MI|Eni|EUR|50000000000"
  "ENEL.MI|Enel|EUR|70000000000"
  "ISP.MI|Intesa Sanpaolo|EUR|60000000000"
  "UCG.MI|UniCredit|EUR|60000000000"
  "STM.MI|STMicroelectronics|EUR|25000000000"
  "LDO.MI|Leonardo|EUR|20000000000"
  # ── Spanien ─────────────────────────────────────────────────────
  "ITX.MC|Inditex|EUR|120000000000"
  "SAN.MC|Banco Santander|EUR|80000000000"
  "IBE.MC|Iberdrola|EUR|80000000000"
  "BBVA.MC|BBVA|EUR|60000000000"
  "TEF.MC|Telefónica|EUR|25000000000"
  # ── Skandinavien ────────────────────────────────────────────────
  "VOLV-B.ST|Volvo|SEK|500000000000"
  "ATCO-A.ST|Atlas Copco|SEK|500000000000"
  "ASSA-B.ST|ASSA ABLOY|SEK|300000000000"
  "SAND.ST|Sandvik|SEK|200000000000"
  "ORSTED.CO|Ørsted|DKK|100000000000"
  "CARLB.CO|Carlsberg|DKK|100000000000"
  # ── Japan ───────────────────────────────────────────────────────
  "7203.T|Toyota|JPY|35000000000000"
  "6758.T|Sony|JPY|15000000000000"
  "9984.T|SoftBank Group|JPY|14000000000000"
  "6861.T|Keyence|JPY|12000000000000"
  "8035.T|Tokyo Electron|JPY|10000000000000"
  "7267.T|Honda|JPY|8000000000000"
  "6501.T|Hitachi|JPY|12000000000000"
  "9432.T|NTT|JPY|15000000000000"
  "8306.T|Mitsubishi UFJ|JPY|18000000000000"
  "9983.T|Fast Retailing|JPY|10000000000000"
  "7974.T|Nintendo|JPY|7000000000000"
  "6954.T|Fanuc|JPY|4000000000000"
  "6367.T|Daikin Industries|JPY|5000000000000"
  "6098.T|Recruit Holdings|JPY|6000000000000"
  "6902.T|Denso|JPY|5000000000000"
  "9433.T|KDDI|JPY|4000000000000"
  # ── Hongkong / China ────────────────────────────────────────────
  "0700.HK|Tencent|HKD|3500000000000"
  "9988.HK|Alibaba HK|HKD|2000000000000"
  "3690.HK|Meituan|HKD|1000000000000"
  "1810.HK|Xiaomi|HKD|500000000000"
  "0941.HK|China Mobile|HKD|1500000000000"
  "2318.HK|Ping An Insurance|HKD|600000000000"
  "1299.HK|AIA Group|HKD|800000000000"
  "0388.HK|HK Exchanges|HKD|400000000000"
  "0005.HK|HSBC HK|HKD|1500000000000"
  "1398.HK|ICBC|HKD|2000000000000"
  "0883.HK|CNOOC|HKD|500000000000"
  "9618.HK|JD.com HK|HKD|300000000000"
  "2020.HK|ANTA Sports|HKD|200000000000"
  # ── Südkorea ────────────────────────────────────────────────────
  "005930.KS|Samsung Electronics|KRW|400000000000000"
  "000660.KS|SK Hynix|KRW|100000000000000"
  "035420.KS|NAVER|KRW|30000000000000"
  # ── Australien ──────────────────────────────────────────────────
  "BHP.AX|BHP Group|AUD|200000000000"
  "CBA.AX|Commonwealth Bank|AUD|200000000000"
  "CSL.AX|CSL Limited|AUD|100000000000"
  # ── Naher Osten ─────────────────────────────────────────────────
  "2222.SR|Saudi Aramco|SAR|7000000000000"
)

fetch_stock() {
  local idx="$1"
  local IFS='|'
  read -r yahoo name cur mcap <<< "${STOCKS[$idx]}"
  local raw
  raw=$(curl -sf --max-time 12 \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
    "https://query1.finance.yahoo.com/v8/finance/chart/${yahoo}?interval=1d&range=2d") || return
  jq -e --arg sy "$yahoo" --arg nm "$name" --arg cu "$cur" --arg mc "$mcap" '
    .chart.result[0] |
    .meta as $m |
    ($m.regularMarketPrice) as $cl |
    ((.indicators.quote[0].open // []) | last // $m.chartPreviousClose) as $op |
    ((.indicators.quote[0].high // []) | last // $cl) as $hi |
    ((.indicators.quote[0].low  // []) | last // $cl) as $lo |
    select($cl != null and $cl != 0) |
    {
      symbol:        $sy,
      name:          $nm,
      price:         ($cl * 100 | round / 100),
      change:        (($cl - $op) * 100 | round / 100),
      changePercent: (if ($op // 0) != 0 then (($cl - $op) / $op * 10000 | round / 100) else 0 end),
      open:          ($op * 100 | round / 100),
      high:          ($hi * 100 | round / 100),
      low:           ($lo * 100 | round / 100),
      marketCap:     ($mc | tonumber),
      currency:      ($m.currency // $cu)
    }
  ' <<< "$raw" 2>/dev/null > "$TMPD/${idx}.json"
}

# Parallel in 10er-Batches
batch=0
for i in "${!STOCKS[@]}"; do
  fetch_stock "$i" &
  (( ++batch % 10 == 0 )) && wait
done
wait

jq -s '.' "$TMPD"/*.json 2>/dev/null > "$TMP_FILE"
rm -rf "$TMPD"

if [ -s "$TMP_FILE" ] && [ "$(cat "$TMP_FILE")" != "[]" ]; then
  mv "$TMP_FILE" "$OUT_FILE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] OK" >> "$LOG_DIR/update.log"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') [stocks] FEHLER" >> "$LOG_DIR/update.log"
  rm -f "$TMP_FILE"
fi
