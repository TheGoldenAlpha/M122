/**
 * stocks.js
 * aktien aus stocks.json anzeigen
 * - übersicht: alle aktien als karten, sortiert nach marktkapitalisierung
 * - detailansicht: kurs, veränderung, open/high/low, marktkapitalisierung, beschreibung
 * - beschreibungen aus stock_info.json, broker-links aus brokers.json
 */

let stocksData = [];
let stockInfo  = {};
let brokers    = [];

// alle aktien-karten rendern, sortiert nach marktkapitalisierung
function renderStocksOverview() {
  const sorted = [...stocksData].sort((a, b) => (b.marketCap || 0) - (a.marketCap || 0));
  document.getElementById("stocksGrid").innerHTML = sorted.map(s => {
    const up = s.changePercent >= 0;
    return `
      <div class="stock-card" onclick="openStockDetail('${s.symbol}')">
        <div class="stock-card-top">
          <span class="stock-card-symbol">${cleanSymbol(s.symbol)}</span>
          <span class="stock-card-badge ${up ? "up" : "down"}">${up ? "▲" : "▼"} ${Math.abs(s.changePercent).toFixed(2)}%</span>
        </div>
        <div class="stock-card-name">${s.name}</div>
        <div class="stock-card-price">${formatPrice(s.price, 2)} <span class="stock-card-cur">${s.currency}</span></div>
        <div class="stock-card-change ${up ? "up" : "down"}">${up ? "+" : ""}${formatPrice(s.change, 2)}</div>
      </div>`;
  }).join("");
}

// detailansicht für eine aktie öffnen
function openStockDetail(symbol) {
  const s    = stocksData.find(x => x.symbol === symbol);
  if (!s) return;
  const info = stockInfo[symbol] || { desc: "Keine Beschreibung verfügbar.", sector: "–" };
  const up   = s.changePercent >= 0;

  document.getElementById("detSymbol").textContent = symbol;
  document.getElementById("detName").textContent   = s.name;
  document.getElementById("detSector").textContent = info.sector;
  document.getElementById("detPrice").textContent  = formatPrice(s.price, 2) + " " + s.currency;
  document.getElementById("detChange").textContent =
    (up ? "▲ +" : "▼ ") + formatPrice(s.change, 2) + " (" + (up ? "+" : "") + s.changePercent.toFixed(2) + "%)";
  document.getElementById("detChange").className   = "stock-detail-change " + (up ? "up" : "down");
  document.getElementById("detOpen").textContent   = formatPrice(s.open, 2)  + " " + s.currency;
  document.getElementById("detHigh").textContent   = formatPrice(s.high, 2)  + " " + s.currency;
  document.getElementById("detLow").textContent    = formatPrice(s.low, 2)   + " " + s.currency;
  document.getElementById("detMcap").textContent   = formatMcap(s.marketCap) + " " + s.currency;
  document.getElementById("detDesc").textContent   = info.desc;

  // broker-links + yahoo finance als info-link
  document.getElementById("detBuy").innerHTML =
    [...brokers, { name: "Yahoo Finance (Infos)", url: `https://finance.yahoo.com/quote/${symbol}` }]
    .map(b => `<a class="buy-link" href="${b.url}" target="_blank" rel="noopener">${b.name}
      <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
    </a>`).join("");

  document.getElementById("stocksOverview").classList.add("hidden");
  document.getElementById("stockDetail").classList.remove("hidden");
  if (window.lucide) lucide.createIcons();
}

// detailansicht schliessen, übersicht einblenden
function closeStockDetail() {
  document.getElementById("stockDetail").classList.add("hidden");
  document.getElementById("stocksOverview").classList.remove("hidden");
}

// aktiendaten laden und übersicht rendern
async function loadStocks() {
  try {
    stocksData = await loadJson("../../data/stocks.json");
    renderStocksOverview();
  } catch {
    document.getElementById("stocksGrid").innerHTML =
      '<div style="padding:24px;color:var(--text-muted)">Aktiendaten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
  }
}
