/**
 * utils.js
 * hilfsfunktionen die in mehreren modulen genutzt werden:
 * - json-daten von lokalem server laden
 * - zahlen formatieren (preise, marktkapitalisierung, börsensymbole)
 */

// lokale json-datei laden, cache-busting via timestamp
async function loadJson(path) {
  const res = await fetch(path + "?t=" + Date.now());
  if (!res.ok) throw new Error("Fehler: " + path);
  return res.json();
}

// zahl als preis formatieren, optionale nachkommastellen
function formatPrice(val, decimals = null) {
  const n = parseFloat(val);
  if (isNaN(n)) return "–";
  if (decimals !== null)
    return n.toLocaleString("de-CH", { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
  if (Math.abs(n) >= 100) return n.toLocaleString("de-CH", { maximumFractionDigits: 0 });
  return n.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// marktkapitalisierung in bio./mrd./mio. formatieren
function formatMcap(mcap) {
  if (!mcap) return "–";
  if (mcap >= 1e12) return (mcap / 1e12).toFixed(2) + " Bio.";
  if (mcap >= 1e9)  return (mcap / 1e9).toFixed(1)  + " Mrd.";
  return (mcap / 1e6).toFixed(0) + " Mio.";
}

// börsensuffix entfernen (.SW, .AS, .DE, .PA, .CO)
function cleanSymbol(sym) {
  return sym.replace(/\.(SW|AS|DE|PA|CO)$/, "");
}
