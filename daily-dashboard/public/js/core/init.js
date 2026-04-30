/**
 * init.js
 * app-start und daten-refresh orchestrieren
 * - übersichtsdaten periodisch neu laden (wetter, news, crypto, rohstoffe)
 * - statische json-daten einmalig laden (broker, beschreibungen)
 * - uhr, navigation und dark mode initialisieren
 */

// übersichtsdaten laden und "aktualisiert"-zeitstempel setzen
async function refreshData() {
  const btn = document.querySelector(".refresh-btn");
  btn.classList.add("spinning");
  await Promise.all([loadWeather(), loadNews(), loadCrypto(), loadCommodities()]);
  btn.classList.remove("spinning");
  document.getElementById("lastUpdate").textContent =
    "Aktualisiert: " + new Date().toLocaleTimeString("de-CH");
}

// app initialisieren: statische daten laden, uhr starten, navigation einrichten
async function init() {
  initDarkMode();
  updateClock();
  setInterval(updateClock, 1000);
  setupNav();

  // broker- und beschreibungsdaten einmalig laden
  const brokersData = await loadJson("../../data/brokers.json").catch(() => ({ stocks: [], crypto: [] }));
  brokers       = brokersData.stocks || [];
  cryptoBrokers = brokersData.crypto || [];
  stockInfo     = await loadJson("../../data/stock_info.json").catch(() => ({}));
  coinInfo      = await loadJson("../../data/coin_info.json").catch(() => ({}));

  // übersichtsdaten sofort und dann jede minute neu laden
  refreshData();
  setInterval(refreshData, 60000);

  if (window.lucide) lucide.createIcons();
  window.addEventListener("load", () => { if (window.lucide) lucide.createIcons(); });
}

init();
