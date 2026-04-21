async function loadJson(path) {
  const res = await fetch(path + "?t=" + Date.now());
  if (!res.ok) throw new Error("Fehler: " + path);
  return res.json();
}

function updateClock() {
  const now = new Date();
  document.getElementById("headerTime").textContent =
    now.toLocaleTimeString("de-CH", { hour: "2-digit", minute: "2-digit" });
  document.getElementById("headerDate").textContent =
    now.toLocaleDateString("de-CH", { weekday: "long", day: "numeric", month: "long", year: "numeric" });
}

async function loadWeather() {
  try {
    const w = await loadJson("../data/weather.json");
    document.getElementById("ovTemp").textContent = w.temperature + "°";
    document.getElementById("ovWind").textContent = w.wind;
    document.getElementById("ovRain").textContent = w.rain;
  } catch {
    document.getElementById("ovTemp").textContent = "–";
  }
}

// ── Live-Wetter für Wetter-Sektion ──

let liveWeatherData = null;
let selectedHour = -1; // -1 = Jetzt

async function fetchOpenMeteo(lat, lon) {
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` +
    `&hourly=temperature_2m,wind_speed_10m,precipitation` +
    `&current=temperature_2m,wind_speed_10m,precipitation` +
    `&timezone=Europe%2FZurich&forecast_days=1`;
  const res = await fetch(url);
  return res.json();
}

function displayWeatherForHour(data, hour) {
  let temp, wind, rain;
  if (hour === -1) {
    temp = data.current.temperature_2m;
    wind = data.current.wind_speed_10m;
    rain = data.current.precipitation;
  } else {
    temp = data.hourly.temperature_2m[hour];
    wind = data.hourly.wind_speed_10m[hour];
    rain = data.hourly.precipitation[hour];
  }
  document.getElementById("detTemp").textContent = Math.round(temp * 10) / 10;
  document.getElementById("detWind").textContent = Math.round(wind);
  document.getElementById("detRain").textContent = rain.toFixed(1);
}

function buildHourSelector(data) {
  const hours = [-1, 0, 3, 6, 9, 12, 15, 18, 21];
  document.getElementById("hourSelector").innerHTML = hours.map(h => {
    const label = h === -1 ? "Jetzt" : `${String(h).padStart(2, "0")}:00`;
    const temp = h === -1
      ? Math.round(data.current.temperature_2m)
      : Math.round(data.hourly.temperature_2m[h]);
    const active = h === selectedHour ? "active" : "";
    return `<button class="hour-btn ${active}" onclick="selectHour(${h})">
      <span class="hour-label">${label}</span>
      <span class="hour-temp">${temp}°</span>
    </button>`;
  }).join("");
}

function selectHour(hour) {
  selectedHour = hour;
  document.querySelectorAll(".hour-btn").forEach(b => b.classList.remove("active"));
  event.currentTarget.classList.add("active");
  if (liveWeatherData) displayWeatherForHour(liveWeatherData, hour);
}

async function loadWeatherDetail() {
  const select = document.getElementById("citySelect");
  const [lat, lon] = select.value.split(",").map(Number);
  document.getElementById("weatherCityLabel").textContent =
    select.options[select.selectedIndex].text;
  document.getElementById("detTemp").textContent = "…";
  document.getElementById("detWind").textContent = "…";
  document.getElementById("detRain").textContent = "…";
  try {
    liveWeatherData = await fetchOpenMeteo(lat, lon);
    selectedHour = -1;
    buildHourSelector(liveWeatherData);
    displayWeatherForHour(liveWeatherData, -1);
  } catch {
    document.getElementById("detTemp").textContent = "–";
  }
}

async function loadNews() {
  try {
    const n = await loadJson("../data/news.json");

    document.getElementById("ovNews").innerHTML = n.items.slice(0, 7)
      .map((item, i) => `
        <a class="news-item" href="${item.url || '#'}" target="_blank" rel="noopener">
          <span class="news-num">${i + 1}</span>
          <span>${item.title}</span>
          <svg class="news-arrow" xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
        </a>
      `).join("");

    document.getElementById("newsFullList").innerHTML = n.items
      .map((item, i) => `
        <a class="news-full-item" href="${item.url || '#'}" target="_blank" rel="noopener">
          <span class="news-full-num">${i + 1}</span>
          <span class="news-full-text">${item.title}</span>
          <svg class="news-arrow" xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
        </a>
      `).join("");
  } catch {
    document.getElementById("ovNews").textContent = "Nachrichten nicht verfügbar.";
    document.getElementById("newsFullList").textContent = "Nachrichten nicht verfügbar.";
  }
}

function formatPrice(val) {
  const n = parseFloat(val);
  if (isNaN(n)) return "–";
  if (n >= 10000) return n.toLocaleString("de-CH", { maximumFractionDigits: 0 });
  if (n >= 100)   return n.toLocaleString("de-CH", { maximumFractionDigits: 0 });
  return n.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

async function loadCrypto() {
  try {
    const c = await loadJson("../data/crypto.json");
    document.getElementById("ovBtc").textContent  = formatPrice(c.bitcoin_chf);
    document.getElementById("ovEth").textContent  = formatPrice(c.ethereum_chf);
    document.getElementById("ovSol").textContent  = formatPrice(c.solana_chf);
    document.getElementById("detBtc").textContent = formatPrice(c.bitcoin_chf);
    document.getElementById("detEth").textContent = formatPrice(c.ethereum_chf);
    document.getElementById("detSol").textContent = formatPrice(c.solana_chf);
  } catch {
    ["ovBtc","ovEth","ovSol"].forEach(id => document.getElementById(id).textContent = "–");
  }
}

async function refreshData() {
  const btn = document.querySelector(".refresh-btn");
  btn.classList.add("spinning");
  await Promise.all([loadWeather(), loadNews(), loadCrypto()]);
  btn.classList.remove("spinning");
  document.getElementById("lastUpdate").textContent =
    "Aktualisiert: " + new Date().toLocaleTimeString("de-CH");
}

// ── Aktien ──

const STOCK_INFO = {
  "AAPL":    { desc: "Apple entwickelt iPhones, Macs, iPads und Dienste wie iCloud und den App Store. Das Unternehmen ist bekannt für sein geschlossenes Ökosystem und gilt als wertvollstes Unternehmen der Welt.", sector: "Technologie · USA" },
  "MSFT":    { desc: "Microsoft ist Hersteller von Windows und Office und betreibt mit Azure eine der grössten Cloud-Plattformen weltweit. Durch die Investition in OpenAI ist Microsoft führend in der KI-Integration.", sector: "Technologie · USA" },
  "NVDA":    { desc: "NVIDIA ist führender Hersteller von Grafikprozessoren (GPUs) und gilt als zentraler Treiber der KI-Revolution. Nahezu jedes grosse KI-Modell wird auf NVIDIA-Hardware trainiert.", sector: "Halbleiter · USA" },
  "GOOGL":   { desc: "Alphabet ist der Mutterkonzern von Google, YouTube und Waymo. Das Unternehmen dominiert den globalen Suchmarkt und investiert stark in KI, Cloud und autonomes Fahren.", sector: "Technologie · USA" },
  "AMZN":    { desc: "Amazon ist der grösste Online-Händler der Welt und betreibt mit AWS die führende Cloud-Infrastruktur. Daneben wächst das Werbegeschäft stark.", sector: "E-Commerce / Cloud · USA" },
  "META":    { desc: "Meta betreibt Facebook, Instagram und WhatsApp und erreicht täglich über 3 Milliarden Menschen. Das Unternehmen investiert stark in Virtual Reality und KI-Werbetechnologie.", sector: "Soziale Medien · USA" },
  "TSLA":    { desc: "Tesla ist Pionier der Elektromobilität und produziert Elektroautos sowie Energiespeichersysteme. CEO Elon Musk prägt das Unternehmen stark – sowohl positiv als auch kontrovers.", sector: "Elektromobilität · USA" },
  "BRK-B":   { desc: "Berkshire Hathaway ist das Investment-Konglomerat von Warren Buffett und hält grosse Beteiligungen an Apple, Coca-Cola und Bank of America. Gilt als einer der solidesten Langzeit-Investments.", sector: "Finanzen / Holding · USA" },
  "JPM":     { desc: "JPMorgan Chase ist die grösste US-Bank nach Bilanzsumme und tätig in Investment Banking, Privatkundengeschäft und Asset Management. Gilt als 'fortress balance sheet'.", sector: "Banken · USA" },
  "V":       { desc: "Visa betreibt das weltweit grösste Zahlungsnetzwerk für Kredit- und Debitkarten. Das Unternehmen verarbeitet täglich Milliarden von Transaktionen und profitiert vom Wachstum des bargeldlosen Zahlens.", sector: "Finanztechnologie · USA" },
  "NESN.SW": { desc: "Nestlé ist der grösste Nahrungsmittelkonzern der Welt mit Marken wie Nescafé, KitKat, Maggi und Vittel. Das Unternehmen ist an der Schweizer Börse kotiert und zahlt seit Jahrzehnten Dividende.", sector: "Nahrungsmittel · Schweiz" },
  "NOVN.SW": { desc: "Novartis ist ein Schweizer Pharmariese, spezialisiert auf innovative Medikamente und Gentherapien. Das Unternehmen investiert massiv in die Entwicklung von Krebstherapien und seltenen Krankheiten.", sector: "Pharma · Schweiz" },
  "ROG.SW":  { desc: "Roche ist Weltführer in der Onkologie und Diagnostik und entwickelt Krebsmedikamente sowie diagnostische Tests. Der Konzern ist an der Schweizer Börse kotiert und sehr dividendenfreundlich.", sector: "Pharma · Schweiz" },
  "ABBN.SW": { desc: "ABB ist ein Schweizer Elektrotechnik- und Automatisierungskonzern, tätig in Robotik, Energieeffizienz und industrieller Automatisierung. ABB beliefert Industrien weltweit mit Antriebstechnik.", sector: "Industrie · Schweiz" },
  "UBSG.SW": { desc: "UBS ist die grösste Schweizer Bank und global führend im Vermögensverwaltungsgeschäft. Nach der Übernahme der Credit Suisse 2023 ist UBS noch bedeutsamer für die Schweizer Wirtschaft.", sector: "Banken · Schweiz" },
  "ASML.AS": { desc: "ASML ist ein niederländischer Hersteller von EUV-Lithographiemaschinen – unverzichtbar für die Herstellung modernster Chips. Ohne ASML gibt es keine fortschrittlichen Halbleiter.", sector: "Halbleiter · Niederlande" },
  "SAP.DE":  { desc: "SAP ist Europas grösster Softwarekonzern und führend in Enterprise-Resource-Planning (ERP). Tausende Grosskonzerne weltweit steuern ihre Geschäftsprozesse mit SAP-Software.", sector: "Software · Deutschland" },
  "MC.PA":   { desc: "LVMH ist der weltgrösste Luxusgüterkonzern und besitzt Marken wie Louis Vuitton, Dior, Moët & Chandon, Hennessy und Bulgari. Das Unternehmen profitiert vom globalen Wachstum der Luxusnachfrage.", sector: "Luxusgüter · Frankreich" },
};

const BROKERS = [
  { name: "Swissquote",          url: "https://www.swissquote.ch" },
  { name: "Interactive Brokers", url: "https://www.interactivebrokers.com" },
  { name: "DEGIRO",              url: "https://www.degiro.ch" },
  { name: "Neon Invest",         url: "https://www.neon-free.ch" },
];

let stocksData = [];

function formatPrice(val, decimals = 2) {
  return val.toLocaleString("de-CH", { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
}

function formatMcap(mcap) {
  if (!mcap) return "–";
  if (mcap >= 1e12) return (mcap / 1e12).toFixed(2) + " Bio.";
  if (mcap >= 1e9)  return (mcap / 1e9).toFixed(1) + " Mrd.";
  return (mcap / 1e6).toFixed(0) + " Mio.";
}

function renderStocksOverview() {
  const up = s => s.changePercent >= 0;
  document.getElementById("stocksGrid").innerHTML = stocksData.map(s => `
    <div class="stock-card" onclick="openStockDetail('${s.symbol}')">
      <div class="stock-card-top">
        <span class="stock-card-symbol">${s.symbol.replace(".SW","").replace(".AS","").replace(".DE","").replace(".PA","")}</span>
        <span class="stock-card-badge ${up(s) ? "up" : "down"}">${up(s) ? "▲" : "▼"} ${Math.abs(s.changePercent).toFixed(2)}%</span>
      </div>
      <div class="stock-card-name">${s.name}</div>
      <div class="stock-card-price">${formatPrice(s.price)} <span class="stock-card-cur">${s.currency}</span></div>
      <div class="stock-card-change ${up(s) ? "up" : "down"}">${up(s) ? "+" : ""}${formatPrice(s.change)}</div>
    </div>
  `).join("");
}

function openStockDetail(symbol) {
  const s = stocksData.find(x => x.symbol === symbol);
  if (!s) return;
  const info = STOCK_INFO[symbol] || { desc: "Keine Beschreibung verfügbar.", sector: "–" };
  const up = s.changePercent >= 0;

  document.getElementById("detSymbol").textContent = symbol;
  document.getElementById("detName").textContent = s.name;
  document.getElementById("detSector").textContent = info.sector;
  document.getElementById("detPrice").textContent = formatPrice(s.price) + " " + s.currency;
  document.getElementById("detChange").textContent = (up ? "▲ +" : "▼ ") + formatPrice(s.change) + " (" + (up ? "+" : "") + s.changePercent.toFixed(2) + "%)";
  document.getElementById("detChange").className = "stock-detail-change " + (up ? "up" : "down");
  document.getElementById("detOpen").textContent  = formatPrice(s.open)  + " " + s.currency;
  document.getElementById("detHigh").textContent  = formatPrice(s.high)  + " " + s.currency;
  document.getElementById("detLow").textContent   = formatPrice(s.low)   + " " + s.currency;
  document.getElementById("detMcap").textContent  = formatMcap(s.marketCap) + " " + s.currency;
  document.getElementById("detDesc").textContent  = info.desc;

  const yahooUrl = `https://finance.yahoo.com/quote/${symbol}`;
  document.getElementById("detBuy").innerHTML =
    [...BROKERS, { name: "Yahoo Finance (Infos)", url: yahooUrl }]
    .map(b => `
      <a class="buy-link" href="${b.url}" target="_blank" rel="noopener">
        ${b.name}
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
      </a>
    `).join("");

  document.getElementById("stocksOverview").classList.add("hidden");
  document.getElementById("stockDetail").classList.remove("hidden");
  if (window.lucide) lucide.createIcons();
}

function closeStockDetail() {
  document.getElementById("stockDetail").classList.add("hidden");
  document.getElementById("stocksOverview").classList.remove("hidden");
}

async function loadStocks() {
  try {
    stocksData = await loadJson("../data/stocks.json");
    renderStocksOverview();
  } catch {
    document.getElementById("stocksGrid").innerHTML =
      '<div style="padding:24px;color:var(--text-muted)">Aktiendaten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
  }
}

// ── Coins ──

const COIN_INFO = {
  "BTC":  { desc: "Bitcoin ist die erste und bekannteste Kryptowährung, erschaffen 2009 von Satoshi Nakamoto. Sie gilt als digitales Gold – begrenzt auf 21 Millionen Einheiten und zunehmend als Wertaufbewahrungsmittel anerkannt.", tag: "Store of Value" },
  "ETH":  { desc: "Ethereum ist die führende Plattform für Smart Contracts und dezentrale Anwendungen (DApps). Die native Währung Ether treibt das gesamte Ökosystem an – von DeFi bis NFTs.", tag: "Smart Contracts" },
  "SOL":  { desc: "Solana ist eine Hochleistungs-Blockchain mit extrem schnellen Transaktionen und sehr niedrigen Gebühren. Sie ist besonders beliebt für NFT-Marktplätze und dezentrale Anwendungen.", tag: "High Performance" },
  "BNB":  { desc: "BNB ist die native Währung der Binance-Börse und der BNB Chain. Sie bietet Rabatte auf Handelsgebühren und ist zentraler Bestandteil des Binance-Ökosystems.", tag: "Exchange Token" },
  "XRP":  { desc: "XRP wurde von Ripple entwickelt und dient als Brücken-Währung für schnelle, kostengünstige grenzüberschreitende Zahlungen zwischen Finanzinstituten weltweit.", tag: "Zahlungen" },
  "ADA":  { desc: "Cardano ist eine wissenschaftlich entwickelte Blockchain mit starkem Fokus auf Sicherheit, Nachhaltigkeit und Peer-Review. Entwickelt vom Ethereum-Mitgründer Charles Hoskinson.", tag: "Proof of Stake" },
  "AVAX": { desc: "Avalanche ist eine schnelle, flexible Blockchain-Plattform für dezentrale Anwendungen. Besonders bekannt für die Möglichkeit, eigene Subnets (eigene Blockchains) zu erstellen.", tag: "DeFi / Subnets" },
  "DOT":  { desc: "Polkadot verbindet verschiedene Blockchains miteinander und ermöglicht echte Interoperabilität. Entwickelt vom Ethereum-Mitgründer Gavin Wood.", tag: "Interoperabilität" },
  "LINK": { desc: "Chainlink ist das führende dezentrale Oracle-Netzwerk. Es verbindet Smart Contracts mit realen Daten aus der Aussenwelt – von Preisen bis Wetterdaten.", tag: "Oracle" },
  "DOGE": { desc: "Dogecoin begann 2013 als Internet-Meme und wuchs zur bekanntesten Meme-Coin. Wird von Elon Musk unterstützt und hat eine aktive Community.", tag: "Meme Coin" },
  "LTC":  { desc: "Litecoin ist eine der ältesten Kryptowährungen und gilt als 'Silber zu Bitcoins Gold'. Schnellere Transaktionen und günstigere Gebühren als Bitcoin.", tag: "Payments" },
  "UNI":  { desc: "Uniswap ist das grösste dezentrale Tauschprotokoll (DEX) auf Ethereum. Es ermöglicht automatisierten Token-Tausch ohne Mittelsmänner durch Liquidity Pools.", tag: "DeFi / DEX" },
};

const CRYPTO_EXCHANGES = [
  { name: "Swissquote Crypto", url: "https://www.swissquote.ch/trading/crypto.html" },
  { name: "Kraken",            url: "https://www.kraken.com" },
  { name: "Coinbase",          url: "https://www.coinbase.com" },
  { name: "Binance",           url: "https://www.binance.com" },
];

let coinsData = [];

function renderCoinsOverview() {
  document.getElementById("coinsGrid").innerHTML = coinsData.map(c => {
    const up = c.changePercent >= 0;
    return `
      <div class="stock-card coin-card" onclick="openCoinDetail('${c.symbol}')">
        <div class="stock-card-top">
          <div style="display:flex;align-items:center;gap:8px;">
            <img src="${c.image}" alt="${c.name}" class="coin-card-img" />
            <span class="stock-card-symbol">${c.symbol}</span>
          </div>
          <span class="stock-card-badge ${up ? "up" : "down"}">${up ? "▲" : "▼"} ${Math.abs(c.changePercent).toFixed(2)}%</span>
        </div>
        <div class="stock-card-name">${c.name}</div>
        <div class="stock-card-price">${formatCoinPrice(c.price)} <span class="stock-card-cur">CHF</span></div>
        <div class="stock-card-change ${up ? "up" : "down"}">${up ? "+" : ""}${formatCoinPrice(c.change)}</div>
      </div>
    `;
  }).join("");
}

function formatCoinPrice(val) {
  if (!val && val !== 0) return "–";
  const abs = Math.abs(val);
  if (abs >= 1000) return val.toLocaleString("de-CH", { maximumFractionDigits: 0 });
  if (abs >= 1)    return val.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  if (abs >= 0.01) return val.toLocaleString("de-CH", { minimumFractionDigits: 4, maximumFractionDigits: 4 });
  return val.toLocaleString("de-CH", { minimumFractionDigits: 6, maximumFractionDigits: 6 });
}

function openCoinDetail(symbol) {
  const c = coinsData.find(x => x.symbol === symbol);
  if (!c) return;
  const info = COIN_INFO[symbol] || { desc: "Keine Beschreibung verfügbar.", tag: "–" };
  const up = c.changePercent >= 0;

  document.getElementById("detCoinImg").src    = c.image;
  document.getElementById("detCoinImg").alt    = c.name;
  document.getElementById("detCoinSymbol").textContent = c.symbol;
  document.getElementById("detCoinName").textContent   = c.name;
  document.getElementById("detCoinSector").textContent = info.tag;
  document.getElementById("detCoinPrice").textContent  = formatCoinPrice(c.price) + " CHF";
  document.getElementById("detCoinChange").textContent =
    (up ? "▲ +" : "▼ ") + formatCoinPrice(c.change) + " (" + (up ? "+" : "") + c.changePercent.toFixed(2) + "%)";
  document.getElementById("detCoinChange").className = "stock-detail-change " + (up ? "up" : "down");
  document.getElementById("detCoinHigh").textContent = formatCoinPrice(c.high24h) + " CHF";
  document.getElementById("detCoinLow").textContent  = formatCoinPrice(c.low24h)  + " CHF";
  document.getElementById("detCoinMcap").textContent = formatMcap(c.marketCap) + " CHF";
  document.getElementById("detCoinVol").textContent  = formatMcap(c.volume24h) + " CHF";
  document.getElementById("detCoinDesc").textContent = info.desc;

  const cgUrl = `https://www.coingecko.com/de/munze/${c.id}`;
  document.getElementById("detCoinBuy").innerHTML =
    [...CRYPTO_EXCHANGES, { name: "CoinGecko (Infos)", url: cgUrl }]
    .map(b => `
      <a class="buy-link" href="${b.url}" target="_blank" rel="noopener">
        ${b.name}
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
      </a>
    `).join("");

  document.getElementById("coinsOverview").classList.add("hidden");
  document.getElementById("coinDetail").classList.remove("hidden");
  if (window.lucide) lucide.createIcons();
}

function closeCoinDetail() {
  document.getElementById("coinDetail").classList.add("hidden");
  document.getElementById("coinsOverview").classList.remove("hidden");
}

async function loadCoins() {
  try {
    coinsData = await loadJson("../data/coins.json");
    renderCoinsOverview();
  } catch {
    document.getElementById("coinsGrid").innerHTML =
      '<div style="padding:24px;color:var(--text-muted)">Coin-Daten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
  }
}

// ── Sport ──

let sportData = null;
let activeSport = "fussball";

function renderSportList(key) {
  activeSport = key;
  document.querySelectorAll(".sport-cat").forEach(b =>
    b.classList.toggle("active", b.dataset.sport === key));

  const list = document.getElementById("sportList");
  if (!sportData) { list.innerHTML = '<div class="sport-empty">Lade...</div>'; return; }

  const items = sportData[key] || [];
  if (items.length === 0) {
    list.innerHTML = '<div class="sport-empty">Keine Nachrichten gefunden.</div>';
    return;
  }

  list.innerHTML = items.map((item, i) => `
    <a class="news-full-item" href="${item.url || '#'}" target="_blank" rel="noopener">
      <span class="news-full-num">${i + 1}</span>
      <span class="news-full-text">${item.title}</span>
      <svg class="news-arrow" xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
    </a>
  `).join("");
}

async function loadSport() {
  try {
    sportData = await loadJson("../data/sport.json");
    renderSportList(activeSport);
  } catch {
    document.getElementById("sportList").innerHTML =
      '<div class="sport-empty">Sportdaten nicht verfügbar. Script ausführen: <code>bash scripts/update.sh</code></div>';
  }
}

function setupNav() {
  document.querySelectorAll(".nav-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
      document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
      btn.classList.add("active");
      document.getElementById(btn.dataset.section).classList.add("active");
      if (btn.dataset.section === "wetter") loadWeatherDetail();
      if (btn.dataset.section === "sport")   loadSport();
      if (btn.dataset.section === "aktien") loadStocks();
      if (btn.dataset.section === "coins")  loadCoins();
    });
  });

  document.querySelectorAll(".sport-cat").forEach(btn => {
    btn.addEventListener("click", () => renderSportList(btn.dataset.sport));
  });
}

updateClock();
setInterval(updateClock, 1000);
setupNav();
refreshData();
setInterval(refreshData, 60000);

if (window.lucide) lucide.createIcons();
window.addEventListener("load", () => { if (window.lucide) lucide.createIcons(); });
