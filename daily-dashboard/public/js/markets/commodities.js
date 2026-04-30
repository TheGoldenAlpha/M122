/**
 * commodities.js
 * rohstoffpreise aus commodities.json anzeigen
 * - kategorien: energie, edelmetalle, agrar
 * - preis, einheit, tagesveränderung pro rohstoff
 * - gold/silber auch im übersicht-widget
 */

// metadaten je rohstoff-symbol: emoji, name, kategorie, einheit
const COMMODITY_META = {
  "GC=F":    { emoji: "🥇", name: "Gold",             cat: "metalle", unit: "USD/oz"    },
  "SI=F":    { emoji: "🥈", name: "Silber",            cat: "metalle", unit: "USD/oz"    },
  "PL=F":    { emoji: "💎", name: "Platin",            cat: "metalle", unit: "USD/oz"    },
  "PA=F":    { emoji: "⚪", name: "Palladium",         cat: "metalle", unit: "USD/oz"    },
  "HG=F":    { emoji: "🔶", name: "Kupfer",            cat: "metalle", unit: "USD/lb"    },
  "ELEC_EU": { emoji: "⚡", name: "Strom (Day-Ahead)", cat: "energie", unit: "EUR/MWh"   },
  "CL=F":    { emoji: "🛢️", name: "Rohöl (WTI)",      cat: "energie", unit: "USD/bbl"   },
  "BZ=F":    { emoji: "🛢️", name: "Rohöl (Brent)",    cat: "energie", unit: "USD/bbl"   },
  "NG=F":    { emoji: "🔥", name: "Erdgas",            cat: "energie", unit: "USD/MMBtu" },
  "RB=F":    { emoji: "⛽", name: "Benzin (RBOB)",     cat: "energie", unit: "USD/gal"   },
  "ZW=F":    { emoji: "🌾", name: "Weizen",            cat: "agrar",   unit: "ct/bu"     },
  "ZC=F":    { emoji: "🌽", name: "Mais",              cat: "agrar",   unit: "ct/bu"     },
  "ZS=F":    { emoji: "🌱", name: "Sojabohnen",        cat: "agrar",   unit: "ct/bu"     },
  "ZO=F":    { emoji: "🌰", name: "Hafer",             cat: "agrar",   unit: "ct/bu"     },
  "ZR=F":    { emoji: "🍚", name: "Reis",              cat: "agrar",   unit: "ct/cwt"    },
  "CC=F":    { emoji: "🍫", name: "Kakao",             cat: "agrar",   unit: "USD/t"     },
  "SB=F":    { emoji: "🍬", name: "Zucker",            cat: "agrar",   unit: "ct/lb"     },
  "CT=F":    { emoji: "🧵", name: "Baumwolle",         cat: "agrar",   unit: "ct/lb"     },
};

// anzeigereihenfolge der kategorien
const COMMODITY_CATS = [
  { key: "energie", label: "Energie",     emoji: "⚡" },
  { key: "metalle", label: "Edelmetalle", emoji: "🥇" },
  { key: "agrar",   label: "Agrar",       emoji: "🌾" },
];

let commoditiesData = [];

// preis je symbol sauber formatieren (unterschiedliche nachkommastellen je rohstoff)
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

// alle rohstoff-karten nach kategorie gruppiert rendern
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
      <div class="commodity-cat-header"><span class="commodity-cat-emoji">${cat.emoji}</span>${cat.label}</div>
      <div class="commodity-grid">`;
    for (const c of items) {
      const meta = COMMODITY_META[c.symbol];
      const up   = c.changePercent >= 0;
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

// rohstoffdaten laden, gold/silber in übersicht schreiben, karten rendern
async function loadCommodities() {
  try {
    commoditiesData = await loadJson("../../data/commodities.json");
    const gold   = commoditiesData.find(c => c.symbol === "GC=F");
    const silver = commoditiesData.find(c => c.symbol === "SI=F");
    if (gold)   document.getElementById("ovGold").textContent   = formatPrice(gold.price, 0);
    if (silver) document.getElementById("ovSilver").textContent = formatPrice(silver.price, 2);
    renderCommodities();
  } catch {
    document.getElementById("commodityContent").innerHTML =
      '<div class="commodity-loading">Rohstoffdaten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
  }
}
