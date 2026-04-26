async function loadJson(path, timeoutMs = 8000) {
  const ctrl = new AbortController();
  const tid = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(path + "?t=" + Date.now(), { signal: ctrl.signal });
    if (!res.ok) throw new Error("Fehler: " + path);
    return res.json();
  } finally {
    clearTimeout(tid);
  }
}

async function fetchWithTimeout(url, timeoutMs = 8000) {
  const ctrl = new AbortController();
  const tid = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: ctrl.signal });
    return res.json();
  } finally {
    clearTimeout(tid);
  }
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
    window._weatherCache = w;
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
  return fetchWithTimeout(url, 10000);
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
    window._newsCache = n;

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

async function loadCrypto() {
  try {
    const c = await loadJson("../data/crypto.json");
    window._cryptoCache = c;
    document.getElementById("ovBtc").textContent = formatPrice(c.bitcoin_chf);
    document.getElementById("ovEth").textContent = formatPrice(c.ethereum_chf);
    document.getElementById("ovSol").textContent = formatPrice(c.solana_chf);
  } catch {
    ["ovBtc","ovEth","ovSol"].forEach(id => document.getElementById(id).textContent = "–");
  }
}

async function refreshData() {
  const btn = document.querySelector(".refresh-btn");
  btn.classList.add("spinning");
  await Promise.all([loadWeather(), loadNews(), loadCrypto(), loadCommodities()]);
  btn.classList.remove("spinning");
  document.getElementById("lastUpdate").textContent =
    "Aktualisiert: " + new Date().toLocaleTimeString("de-CH");
}

// ── Rohstoffe ──

const COMMODITY_META = {
  "GC=F": { emoji: "🥇", name: "Gold",           cat: "metalle", unit: "USD/oz" },
  "SI=F": { emoji: "🥈", name: "Silber",          cat: "metalle", unit: "USD/oz" },
  "PL=F": { emoji: "💎", name: "Platin",          cat: "metalle", unit: "USD/oz" },
  "PA=F": { emoji: "⚪", name: "Palladium",       cat: "metalle", unit: "USD/oz" },
  "HG=F": { emoji: "🔶", name: "Kupfer",          cat: "metalle", unit: "USD/lb" },
  "ELEC_EU": { emoji: "⚡", name: "Strom (Day-Ahead)", cat: "energie", unit: "EUR/MWh" },
  "CL=F": { emoji: "🛢️", name: "Rohöl (WTI)",    cat: "energie", unit: "USD/bbl" },
  "BZ=F": { emoji: "🛢️", name: "Rohöl (Brent)",  cat: "energie", unit: "USD/bbl" },
  "NG=F": { emoji: "🔥", name: "Erdgas",          cat: "energie", unit: "USD/MMBtu" },
  "RB=F": { emoji: "⛽", name: "Benzin (RBOB)",   cat: "energie", unit: "USD/gal" },
  "ZW=F": { emoji: "🌾", name: "Weizen",          cat: "agrar",   unit: "ct/bu" },
  "ZC=F": { emoji: "🌽", name: "Mais",            cat: "agrar",   unit: "ct/bu" },
  "ZS=F": { emoji: "🌱", name: "Sojabohnen",      cat: "agrar",   unit: "ct/bu" },
  "ZO=F": { emoji: "🌰", name: "Hafer",           cat: "agrar",   unit: "ct/bu" },
  "ZR=F": { emoji: "🍚", name: "Reis",            cat: "agrar",   unit: "ct/cwt" },
  "CC=F": { emoji: "🍫", name: "Kakao",           cat: "agrar",   unit: "USD/t" },
  "SB=F": { emoji: "🍬", name: "Zucker",          cat: "agrar",   unit: "ct/lb" },
  "CT=F": { emoji: "🧵", name: "Baumwolle",       cat: "agrar",   unit: "ct/lb" },
};

const COMMODITY_CATS = [
  { key: "energie", label: "Energie",     emoji: "⚡" },
  { key: "metalle", label: "Edelmetalle", emoji: "🥇" },
  { key: "agrar",   label: "Agrar",       emoji: "🌾" },
];

let commoditiesData = [];

function formatCommodityPrice(val, symbol) {
  const n = parseFloat(val);
  if (isNaN(n)) return "–";
  if (symbol === "ELEC_EU") return n.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  if (symbol === "RB=F") return n.toFixed(4);
  if (symbol === "NG=F") return n.toFixed(3);
  if (symbol === "HG=F") return n.toFixed(4);
  if (n >= 1000) return n.toLocaleString("de-CH", { maximumFractionDigits: 1 });
  if (n >= 10)   return n.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return n.toFixed(4);
}

function renderCommodities() {
  const el = document.getElementById("commodityContent");
  if (!commoditiesData.length) {
    el.innerHTML = '<div class="commodity-loading">Rohstoffdaten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
    return;
  }
  let html = "";
  for (const cat of COMMODITY_CATS) {
    const items = commoditiesData.filter(c => COMMODITY_META[c.symbol]?.cat === cat.key);
    if (!items.length) continue;
    html += `<div class="commodity-cat-block">
      <div class="commodity-cat-header">
        <span class="commodity-cat-emoji">${cat.emoji}</span>${cat.label}
      </div>
      <div class="commodity-grid">`;
    for (const c of items) {
      const meta = COMMODITY_META[c.symbol];
      const up = c.changePercent >= 0;
      html += `
        <div class="commodity-card">
          <div class="commodity-emoji-wrap ${cat.key}">${meta.emoji}</div>
          <div class="commodity-name">${meta.name}</div>
          <div class="commodity-price">${formatCommodityPrice(c.price, c.symbol)}</div>
          <div class="commodity-unit">${meta.unit}</div>
          <span class="commodity-change ${up ? "up" : "down"}">${up ? "▲" : "▼"} ${Math.abs(c.changePercent).toFixed(2)}%</span>
        </div>`;
    }
    html += `</div></div>`;
  }
  el.innerHTML = html;
}

async function loadCommodities() {
  try {
    commoditiesData = await loadJson("../data/commodities.json");
    window._commoditiesCache = commoditiesData;
    // Übersicht-Karten befüllen
    const gold   = commoditiesData.find(c => c.symbol === "GC=F");
    const silver = commoditiesData.find(c => c.symbol === "SI=F");
    const gEl = document.getElementById("ovGold");
    const sEl = document.getElementById("ovSilver");
    if (gEl && gold)   gEl.textContent   = formatPrice(gold.price, 0);
    if (sEl && silver) sEl.textContent   = formatPrice(silver.price, 2);
    renderCommodities();
  } catch {
    document.getElementById("commodityContent").innerHTML =
      '<div class="commodity-loading">Rohstoffdaten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
  }
}

// ── Aktien ──

const STOCK_INFO = {
  // ── US Technologie & Wachstum ──
  "AAPL":    { desc: "Apple entwickelt iPhones, Macs, iPads und Dienste wie iCloud und den App Store. Bekannt für sein geschlossenes Ökosystem gilt Apple als wertvollstes Unternehmen der Welt.", sector: "Technologie · USA" },
  "NVDA":    { desc: "NVIDIA ist führender Hersteller von KI-GPUs und gilt als zentraler Treiber der KI-Revolution. Nahezu jedes grosse KI-Modell – von ChatGPT bis Gemini – wird auf NVIDIA-Hardware trainiert.", sector: "Halbleiter · USA" },
  "MSFT":    { desc: "Microsoft betreibt Windows, Office und Azure – eine der grössten Cloud-Plattformen weltweit. Durch die Milliarden-Investition in OpenAI ist Microsoft führend in der KI-Integration.", sector: "Technologie · USA" },
  "GOOGL":   { desc: "Alphabet ist der Mutterkonzern von Google, YouTube, Android und Waymo. Das Unternehmen dominiert den globalen Suchmarkt und investiert stark in KI und autonomes Fahren.", sector: "Technologie · USA" },
  "AMZN":    { desc: "Amazon ist der grösste Online-Händler der Welt und betreibt mit AWS die führende Cloud-Infrastruktur. Das rasant wachsende Werbegeschäft wird zur dritten grossen Einnahmequelle.", sector: "E-Commerce / Cloud · USA" },
  "META":    { desc: "Meta betreibt Facebook, Instagram und WhatsApp und erreicht täglich über 3 Milliarden Menschen. Das Unternehmen investiert massiv in KI-Werbetechnologie und Virtual Reality (Meta Quest).", sector: "Soziale Medien · USA" },
  "TSLA":    { desc: "Tesla ist Pionier der Elektromobilität und produziert Elektroautos sowie Energiespeichersysteme. CEO Elon Musk prägt das Unternehmen stark, das auch an selbstfahrenden Robotaxis arbeitet.", sector: "Elektromobilität · USA" },
  "TSM":     { desc: "TSMC ist der weltgrösste Auftragschiphersteller und fertigt die Chips von Apple, NVIDIA, AMD und vielen anderen. Ohne TSMC würde ein Grossteil der Technologiewelt stillstehen.", sector: "Halbleiter · Taiwan" },
  "AVGO":    { desc: "Broadcom entwickelt Halbleiter und Infrastruktursoftware für Netzwerke, Rechenzentren und KI. Nach der VMware-Übernahme 2023 ist Broadcom auch im Enterprise-Software-Markt führend.", sector: "Halbleiter / Software · USA" },
  "LLY":     { desc: "Eli Lilly ist ein US-Pharmariese und bekannt für seine Diabetes- und Abnehmmedikamente wie Mounjaro und Zepbound. Das Unternehmen verzeichnet aussergewöhnliches Wachstum im GLP-1-Markt.", sector: "Pharma · USA" },
  "ORCL":    { desc: "Oracle ist weltführend in Unternehmensdatenbanken und Cloud-Infrastruktur. Im KI-Zeitalter baut Oracle massiv Rechenzentren aus und profitiert stark von der Nachfrage nach Cloud-Kapazitäten.", sector: "Software / Cloud · USA" },
  "NFLX":    { desc: "Netflix ist der grösste Streaming-Dienst der Welt mit über 300 Millionen Abonnenten. Das Unternehmen investiert Milliarden in Eigenproduktionen und expandiert in Werbefinanzierung und Gaming.", sector: "Streaming · USA" },
  "AMD":     { desc: "AMD entwickelt Prozessoren (Ryzen, EPYC) und KI-Grafikkarten (Instinct MI-Serie) als wichtigste Alternative zu NVIDIA. AMD gewinnt kontinuierlich Marktanteile in Rechenzentren.", sector: "Halbleiter · USA" },
  "CRM":     { desc: "Salesforce ist der weltgrösste Anbieter von CRM-Software und hilft Unternehmen, ihre Kundenbeziehungen digital zu verwalten. Salesforce integriert KI-Agenten direkt in den Verkaufsprozess.", sector: "Software · USA" },
  // ── US Finanzen / Konsum / Energie ──
  "BRK-B":   { desc: "Berkshire Hathaway ist das Investment-Konglomerat von Warren Buffett mit Beteiligungen an Apple, Coca-Cola und BNSF Railway. Gilt weltweit als Inbegriff des soliden Langzeit-Investments.", sector: "Finanzen / Holding · USA" },
  "JPM":     { desc: "JPMorgan Chase ist die grösste US-Bank nach Bilanzsumme und tätig in Investment Banking, Privatkundengeschäft und Asset Management. CEO Jamie Dimon gilt als einflussreichster Banker weltweit.", sector: "Banken · USA" },
  "V":       { desc: "Visa betreibt das weltweit grösste Zahlungsnetzwerk für Kredit- und Debitkarten und verarbeitet täglich Milliarden Transaktionen. Visa profitiert strukturell vom weltweiten Trend zu bargeldlosem Zahlen.", sector: "Zahlungstechnologie · USA" },
  "MA":      { desc: "Mastercard ist das zweitgrösste globale Zahlungsnetzwerk und direkte Konkurrenz zu Visa. Das Unternehmen verdient an jeder Transaktion eine kleine Gebühr – bei Milliarden Transaktionen täglich.", sector: "Zahlungstechnologie · USA" },
  "WMT":     { desc: "Walmart ist der grösste Einzelhändler der Welt nach Umsatz mit über 10'000 Filialen weltweit. Der Konzern baut sein E-Commerce- und Werbegeschäft massiv aus und wächst rasant in Indien (Flipkart).", sector: "Einzelhandel · USA" },
  "XOM":     { desc: "ExxonMobil ist der grösste westliche Öl- und Gaskonzern und investiert trotz Energiewende in neue Förderprojekte. Das Unternehmen engagiert sich zunehmend in CO₂-Abscheidung und Lithiumförderung.", sector: "Energie · USA" },
  "COST":    { desc: "Costco betreibt Mitglieder-Warenhäuser weltweit und ist bekannt für niedrige Preise und hohe Kundentreue. Die Mitgliedschaftsgebühren sind das eigentliche Geschäftsmodell – die Waren werden fast zum Selbstkostenpreis verkauft.", sector: "Einzelhandel · USA" },
  "HD":      { desc: "Home Depot ist die grösste Baumarkt-Kette der Welt und profitiert vom Boom im US-Heimwerker- und Renovierungsmarkt. Das Unternehmen bedient sowohl Privatpersonen als auch professionelle Handwerker.", sector: "Einzelhandel · USA" },
  "UNH":     { desc: "UnitedHealth ist das grösste US-Krankenversicherungsunternehmen und betreibt mit Optum auch einen führenden Gesundheitsdienstleister. Der Konzern bewegt jährlich Billionen von Dollar im US-Gesundheitssystem.", sector: "Krankenversicherung · USA" },
  "PG":      { desc: "Procter & Gamble produziert Konsumgüter wie Pampers, Gillette, Ariel und Oral-B. Als globaler Markenartikelkonzern profitiert P&G von der robusten Nachfrage nach Haushaltsprodukten.", sector: "Konsumgüter · USA" },
  "JNJ":     { desc: "Johnson & Johnson ist ein globaler Pharma- und Medizintechnikkonzern mit Fokus auf verschreibungspflichtige Medikamente und chirurgische Geräte. J&J ist für seine stabile Dividende bekannt.", sector: "Pharma / Medizintechnik · USA" },
  "BAC":     { desc: "Bank of America ist die zweitgrösste US-Bank und bedient über 65 Millionen Kunden. Das Unternehmen profitiert überproportional von hohen Zinsen durch sein riesiges Einlagenportfolio.", sector: "Banken · USA" },
  "KO":      { desc: "Coca-Cola ist der weltbekannte Getränkehersteller mit über 500 Marken in mehr als 200 Ländern. Das Unternehmen gilt als Paradebeispiel für eine Dividenden-Aktie mit jahrzehntelangem Wachstum.", sector: "Getränke · USA" },
  "MCD":     { desc: "McDonald's ist die grösste Fast-Food-Kette der Welt mit fast 40'000 Restaurants. Das eigentliche Geschäftsmodell ist Immobilien: McDonald's besitzt die Grundstücke, auf denen die Restaurants stehen.", sector: "Gastronomie · USA" },
  "DIS":     { desc: "Disney ist ein globaler Medien- und Unterhaltungskonzern mit Marken wie Marvel, Star Wars, Pixar und ESPN. Das Streaming-Geschäft Disney+ wächst stark, während die Freizeitpark-Sparte Rekordumsätze erzielt.", sector: "Medien / Unterhaltung · USA" },
  "NVO":     { desc: "Novo Nordisk ist ein dänischer Pharmariese und weltweiter Marktführer bei GLP-1-Medikamenten gegen Diabetes und Übergewicht (Ozempic, Wegovy). Das Unternehmen verzeichnet eines der schnellsten Wachstümer in der Pharmabranche.", sector: "Pharma · Dänemark" },
  // ── Schweiz ──
  "NESN.SW": { desc: "Nestlé ist der grösste Nahrungsmittelkonzern der Welt mit Marken wie Nescafé, KitKat, Maggi und Vittel. Das Unternehmen ist an der Schweizer Börse kotiert und zahlt seit Jahrzehnten Dividende.", sector: "Nahrungsmittel · Schweiz" },
  "NOVN.SW": { desc: "Novartis ist ein Schweizer Pharmariese, spezialisiert auf innovative Medikamente und Gentherapien. Das Unternehmen investiert massiv in Krebstherapien und seltene Krankheiten.", sector: "Pharma · Schweiz" },
  "ROG.SW":  { desc: "Roche ist Weltführer in der Onkologie und Diagnostik und entwickelt Krebsmedikamente sowie diagnostische Tests. Der Konzern ist an der Schweizer Börse kotiert und sehr dividendenfreundlich.", sector: "Pharma · Schweiz" },
  "ABBN.SW": { desc: "ABB ist ein Schweizer Elektrotechnik- und Automatisierungskonzern in Robotik, Energieeffizienz und industrieller Automatisierung. ABB beliefert Industrien weltweit mit Antriebstechnik.", sector: "Industrie · Schweiz" },
  "UBSG.SW": { desc: "UBS ist die grösste Schweizer Bank und global führend im Vermögensverwaltungsgeschäft. Nach der Übernahme der Credit Suisse 2023 verwaltet UBS über 5 Billionen Dollar Kundenvermögen.", sector: "Banken · Schweiz" },
  // ── Europa ──
  "ASML.AS": { desc: "ASML ist ein niederländischer Hersteller von EUV-Lithographiemaschinen – unverzichtbar für die Herstellung modernster Chips. ASML ist das einzige Unternehmen weltweit, das diese Schlüsseltechnologie liefert.", sector: "Halbleiter · Niederlande" },
  "SAP.DE":  { desc: "SAP ist Europas grösster Softwarekonzern und weltweiter Marktführer in Enterprise-Resource-Planning (ERP). Tausende Grosskonzerne steuern ihre Geschäftsprozesse mit SAP – der Wechsel zu Cloud-Abonnements treibt Wachstum.", sector: "Software · Deutschland" },
  "MC.PA":   { desc: "LVMH ist der weltgrösste Luxusgüterkonzern mit Marken wie Louis Vuitton, Dior, Moët & Chandon, Hennessy und Bulgari. Das Unternehmen profitiert vom globalen Wachstum der Luxusnachfrage aus Asien und dem Nahen Osten.", sector: "Luxusgüter · Frankreich" },
  "OR.PA":   { desc: "L'Oréal ist der weltgrösste Kosmetikkonzern mit Marken wie Lancôme, Maybelline, Garnier und Kérastase. Das Unternehmen ist in allen Preissegmenten vertreten und wächst stark in Asien und Nordafrika.", sector: "Kosmetik · Frankreich" },
  "SIE.DE":  { desc: "Siemens ist ein deutscher Industriekonzern tätig in Automatisierung, digitaler Industrie, Smart Infrastructure und Mobilität. Siemens gilt als Rückgrat der industriellen Digitalisierung in Europa.", sector: "Industrie · Deutschland" },
};

const BROKERS = [
  { name: "Swissquote",          url: "https://trade.swissquote.ch" },
  { name: "Interactive Brokers", url: "https://www.interactivebrokers.com" },
  { name: "DEGIRO",              url: "https://www.degiro.ch" },
  { name: "Neon Invest",         url: "https://www.neon-free.ch" },
];

let stocksData = [];

function formatPrice(val, decimals = null) {
  const n = parseFloat(val);
  if (isNaN(n)) return "–";
  if (decimals !== null) {
    return n.toLocaleString("de-CH", { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
  }
  if (Math.abs(n) >= 10000) return n.toLocaleString("de-CH", { maximumFractionDigits: 0 });
  if (Math.abs(n) >= 100)   return n.toLocaleString("de-CH", { maximumFractionDigits: 0 });
  return n.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatMcap(mcap) {
  if (!mcap) return "–";
  if (mcap >= 1e12) return (mcap / 1e12).toFixed(2) + " Bio.";
  if (mcap >= 1e9)  return (mcap / 1e9).toFixed(1) + " Mrd.";
  return (mcap / 1e6).toFixed(0) + " Mio.";
}

function cleanSymbol(sym) {
  return sym.replace(/\.(SW|AS|DE|PA|CO)$/, "");
}

function renderStocksOverview() {
  const sorted = [...stocksData].sort((a, b) => (b.marketCap || 0) - (a.marketCap || 0));
  const up = s => s.changePercent >= 0;
  document.getElementById("stocksGrid").innerHTML = sorted.map(s => `
    <div class="stock-card" onclick="openStockDetail('${s.symbol}')">
      <div class="stock-card-top">
        <span class="stock-card-symbol">${cleanSymbol(s.symbol)}</span>
        <span class="stock-card-badge ${up(s) ? "up" : "down"}">${up(s) ? "▲" : "▼"} ${Math.abs(s.changePercent).toFixed(2)}%</span>
      </div>
      <div class="stock-card-name">${s.name}</div>
      <div class="stock-card-price">${formatPrice(s.price, 2)} <span class="stock-card-cur">${s.currency}</span></div>
      <div class="stock-card-change ${up(s) ? "up" : "down"}">${up(s) ? "+" : ""}${formatPrice(s.change, 2)}</div>
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
  document.getElementById("detPrice").textContent = formatPrice(s.price, 2) + " " + s.currency;
  document.getElementById("detChange").textContent = (up ? "▲ +" : "▼ ") + formatPrice(s.change, 2) + " (" + (up ? "+" : "") + s.changePercent.toFixed(2) + "%)";
  document.getElementById("detChange").className = "stock-detail-change " + (up ? "up" : "down");
  document.getElementById("detOpen").textContent  = formatPrice(s.open, 2)  + " " + s.currency;
  document.getElementById("detHigh").textContent  = formatPrice(s.high, 2)  + " " + s.currency;
  document.getElementById("detLow").textContent   = formatPrice(s.low, 2)   + " " + s.currency;
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
  { name: "Swissquote Crypto", url: "https://trade.swissquote.ch" },
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

const SPORT_META = {
  fussball:       { emoji: "⚽", label: "Fussball" },
  eishockey:      { emoji: "🏒", label: "Eishockey" },
  unihockey:      { emoji: "🏑", label: "Unihockey" },
  handball:       { emoji: "🤾", label: "Handball" },
  tennis:         { emoji: "🎾", label: "Tennis" },
  ski:            { emoji: "⛷️", label: "Ski Alpin" },
  leichtathletik: { emoji: "🏃", label: "Leichtathletik" },
  basketball:     { emoji: "🏀", label: "Basketball" },
  formel1:        { emoji: "🏎️", label: "Formel 1" },
  volleyball:     { emoji: "🏐", label: "Volleyball" },
};

let sportData = null;
let activeSport = "fussball";

function parseSportTitle(raw) {
  const idx = raw.lastIndexOf(" - ");
  if (idx > 10) return { title: raw.slice(0, idx), source: raw.slice(idx + 3) };
  return { title: raw, source: "" };
}

function renderSportList(key) {
  activeSport = key;
  document.querySelectorAll(".sport-tile").forEach(b =>
    b.classList.toggle("active", b.dataset.sport === key));

  const meta = SPORT_META[key] || { emoji: "🏅", label: key };
  document.getElementById("sportEmoji").textContent = meta.emoji;
  document.getElementById("sportTitle").textContent = meta.label;

  const list = document.getElementById("sportList");
  if (!sportData) { list.innerHTML = '<div class="sport-loading">Lade...</div>'; return; }

  const items = sportData[key] || [];
  if (items.length === 0) {
    list.innerHTML = '<div class="sport-empty">Keine Nachrichten gefunden.</div>';
    return;
  }

  list.innerHTML = items.map((item, i) => {
    const { title, source } = parseSportTitle(item.title);
    return `
      <a class="sport-news-item" href="${item.url || '#'}" target="_blank" rel="noopener">
        <span class="sport-news-num">${i + 1}</span>
        <div class="sport-news-body">
          <div class="sport-news-title-text">${title}</div>
          ${source ? `<span class="sport-news-source">${source}</span>` : ""}
        </div>
        <svg class="sport-news-arrow" xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
      </a>
    `;
  }).join("");
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

// ── Dark Mode ──
function initDarkMode() {
  const saved = localStorage.getItem("theme");
  const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  if (saved === "dark" || (!saved && prefersDark)) {
    document.body.classList.add("dark");
    const cb = document.getElementById("darkToggleSidebar");
    if (cb) cb.checked = true;
  }
}

function toggleDarkMode() {
  const isDark = document.body.classList.toggle("dark");
  localStorage.setItem("theme", isDark ? "dark" : "light");
  const cb = document.getElementById("darkToggleSidebar");
  if (cb) cb.checked = isDark;
}

// ── Mobile Sidebar ──
function openSidebar() {
  document.getElementById("mobileSidebar").classList.add("open");
  document.getElementById("sidebarOverlay").classList.add("open");
  document.body.style.overflow = "hidden";
}

function closeSidebar() {
  document.getElementById("mobileSidebar").classList.remove("open");
  document.getElementById("sidebarOverlay").classList.remove("open");
  document.body.style.overflow = "";
}

function sidebarNav(section) {
  document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
  document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
  const topBtn = document.querySelector(`.nav-btn[data-section="${section}"]`);
  if (topBtn) topBtn.classList.add("active");
  document.getElementById(section).classList.add("active");
  document.querySelectorAll(".sidebar-nav-btn").forEach(b => b.classList.remove("active"));
  const sideBtn = document.querySelector(`.sidebar-nav-btn[data-section="${section}"]`);
  if (sideBtn) sideBtn.classList.add("active");
  if (section === "wetter")        loadWeatherDetail();
  if (section === "sport")         loadSport();
  if (section === "rohstoffe")     loadCommodities();
  if (section === "aktien")        loadStocks();
  if (section === "coins")         loadCoins();
  if (section === "entertainment") loadEntertainment();
  closeSidebar();
}

function setupNav() {
  document.querySelectorAll(".nav-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
      document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
      btn.classList.add("active");
      document.getElementById(btn.dataset.section).classList.add("active");
      document.querySelectorAll(".sidebar-nav-btn").forEach(b => b.classList.remove("active"));
      const sideBtn = document.querySelector(`.sidebar-nav-btn[data-section="${btn.dataset.section}"]`);
      if (sideBtn) sideBtn.classList.add("active");
      if (btn.dataset.section === "wetter")    loadWeatherDetail();
      if (btn.dataset.section === "sport")     loadSport();
      if (btn.dataset.section === "rohstoffe") loadCommodities();
      if (btn.dataset.section === "aktien")    loadStocks();
      if (btn.dataset.section === "coins")         loadCoins();
      if (btn.dataset.section === "entertainment") loadEntertainment();
    });
  });

  document.querySelectorAll(".sport-tile").forEach(btn => {
    btn.addEventListener("click", () => renderSportList(btn.dataset.sport));
  });
}

// ── Entertainment ──

function entSwitchTab(btn) {
  document.querySelectorAll(".ent-tab").forEach(b => b.classList.remove("active"));
  btn.classList.add("active");
  document.querySelectorAll(".ent-panel").forEach(p => p.style.display = "none");
  document.getElementById("ent-" + btn.dataset.tab).style.display = "block";
}

async function loadEntertainment() {
  try {
    const data = await loadJson("../data/entertainment.json");
    entRenderGrid("gamingGrid", data.gaming || [], "🎮");
    entRenderGrid("moviesGrid", data.movies || [], "🎬");
  } catch {
    document.getElementById("gamingGrid").innerHTML =
      '<div class="ent-error">Daten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
    document.getElementById("moviesGrid").innerHTML = "";
  }
}

function entRenderGrid(gridId, items, fallbackEmoji) {
  const el = document.getElementById(gridId);
  if (!el) return;
  if (!items.length) {
    el.innerHTML = '<div class="ent-empty">Keine Artikel gefunden.</div>';
    return;
  }
  el.innerHTML = items.map(item => entArticleCard(item, fallbackEmoji)).join("");
}

function entArticleCard(item, fallbackEmoji) {
  const imgHtml = item.image
    ? "<img class=\"ent-card-img\" src=\"" + item.image + "\" alt=\"\" loading=\"lazy\" onerror=\"this.style.display='none'\" />"
    : "";
  const desc = item.desc
    ? "<div class=\"ent-card-desc\">" + item.desc.slice(0, 160) + (item.desc.length > 160 ? "…" : "") + "</div>"
    : "";
  const meta = [item.source, item.date].filter(Boolean).join(" · ");
  return "<a class=\"ent-article-card\" href=\"" + item.url + "\" target=\"_blank\" rel=\"noopener\">" +
    (imgHtml ? "<div class=\"ent-card-img-wrap\">" + imgHtml + "</div>" : "") +
    "<div class=\"ent-card-body\">" +
      "<div class=\"ent-card-title\">" + item.title + "</div>" +
      (meta ? "<div class=\"ent-card-meta\">" + meta + "</div>" : "") +
      desc +
    "</div>" +
  "</a>";
}

initDarkMode();
updateClock();
setInterval(updateClock, 1000);
setupNav();
refreshData();
setInterval(refreshData, 60000);

if (window.lucide) lucide.createIcons();
window.addEventListener("load", () => { if (window.lucide) lucide.createIcons(); });
