/**
 * coins.js
 * kryptowährungen aus coins.json anzeigen
 * - übersicht: alle coins als karten mit bild, preis, 24h-veränderung
 * - detailansicht: 24h-hoch/tief, marktkapitalisierung, volumen, beschreibung
 * - beschreibungen aus coin_info.json, exchange-links aus brokers.json
 */

let coinsData     = [];
let coinInfo      = {};
let cryptoBrokers = [];

// coin-preis formatieren je nach grössenordnung (bis 6 nachkommastellen)
function formatCoinPrice(val) {
  if (!val && val !== 0) return "–";
  const abs = Math.abs(val);
  if (abs >= 1000) return val.toLocaleString("de-CH", { maximumFractionDigits: 0 });
  if (abs >= 1)    return val.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  if (abs >= 0.01) return val.toLocaleString("de-CH", { minimumFractionDigits: 4, maximumFractionDigits: 4 });
  return val.toLocaleString("de-CH", { minimumFractionDigits: 6, maximumFractionDigits: 6 });
}

// alle coin-karten rendern
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
      </div>`;
  }).join("");
}

// detailansicht für einen coin öffnen
function openCoinDetail(symbol) {
  const c    = coinsData.find(x => x.symbol === symbol);
  if (!c) return;
  const info = coinInfo[symbol] || { desc: "Keine Beschreibung verfügbar.", tag: "–" };
  const up   = c.changePercent >= 0;

  document.getElementById("detCoinImg").src            = c.image;
  document.getElementById("detCoinImg").alt            = c.name;
  document.getElementById("detCoinSymbol").textContent = c.symbol;
  document.getElementById("detCoinName").textContent   = c.name;
  document.getElementById("detCoinSector").textContent = info.tag;
  document.getElementById("detCoinPrice").textContent  = formatCoinPrice(c.price)  + " CHF";
  document.getElementById("detCoinChange").textContent =
    (up ? "▲ +" : "▼ ") + formatCoinPrice(c.change) + " (" + (up ? "+" : "") + c.changePercent.toFixed(2) + "%)";
  document.getElementById("detCoinChange").className   = "stock-detail-change " + (up ? "up" : "down");
  document.getElementById("detCoinHigh").textContent   = formatCoinPrice(c.high24h) + " CHF";
  document.getElementById("detCoinLow").textContent    = formatCoinPrice(c.low24h)  + " CHF";
  document.getElementById("detCoinMcap").textContent   = formatMcap(c.marketCap)   + " CHF";
  document.getElementById("detCoinVol").textContent    = formatMcap(c.volume24h)   + " CHF";
  document.getElementById("detCoinDesc").textContent   = info.desc;

  // exchange-links + coingecko als info-link
  document.getElementById("detCoinBuy").innerHTML =
    [...cryptoBrokers, { name: "CoinGecko (Infos)", url: `https://www.coingecko.com/de/munze/${c.id}` }]
    .map(b => `<a class="buy-link" href="${b.url}" target="_blank" rel="noopener">${b.name}
      <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
    </a>`).join("");

  document.getElementById("coinsOverview").classList.add("hidden");
  document.getElementById("coinDetail").classList.remove("hidden");
  if (window.lucide) lucide.createIcons();
}

// detailansicht schliessen, übersicht einblenden
function closeCoinDetail() {
  document.getElementById("coinDetail").classList.add("hidden");
  document.getElementById("coinsOverview").classList.remove("hidden");
}

// coin-daten laden und übersicht rendern
async function loadCoins() {
  try {
    coinsData = await loadJson("../../data/coins.json");
    renderCoinsOverview();
  } catch {
    document.getElementById("coinsGrid").innerHTML =
      '<div style="padding:24px;color:var(--text-muted)">Coin-Daten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
  }
}
