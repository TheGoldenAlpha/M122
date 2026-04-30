/**
 * crypto.js
 * kryptowährungspreise im übersicht-widget anzeigen
 * - bitcoin, ethereum, solana in CHF
 * - daten aus crypto.json (via coingecko)
 */

// bitcoin, ethereum, solana preise in übersicht-widget schreiben
async function loadCrypto() {
  try {
    const c = await loadJson("../../data/crypto.json");
    document.getElementById("ovBtc").textContent = formatPrice(c.bitcoin_chf);
    document.getElementById("ovEth").textContent = formatPrice(c.ethereum_chf);
    document.getElementById("ovSol").textContent = formatPrice(c.solana_chf);
  } catch {
    ["ovBtc", "ovEth", "ovSol"].forEach(id =>
      document.getElementById(id).textContent = "–");
  }
}
