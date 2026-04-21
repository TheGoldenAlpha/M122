async function loadJson(path) {
  const response = await fetch(path + "?cache=" + Date.now());
  if (!response.ok) throw new Error("Konnte " + path + " nicht laden");
  return response.json();
}

async function loadDashboard() {
  document.getElementById("lastUpdate").textContent =
    "Letztes Laden: " + new Date().toLocaleString("de-CH");

  try {
    const news = await loadJson("../data/news.json");
    document.getElementById("news").innerHTML = news.items
      .map((item) => `<div class="item">${item.title}</div>`)
      .join("");
  } catch {
    document.getElementById("news").textContent = "Nicht verfügbar.";
  }

  try {
    const weather = await loadJson("../data/weather.json");
    document.getElementById("weather").innerHTML = `
      <p>Temperatur: ${weather.temperature} °C</p>
      <p>Wind: ${weather.wind} km/h</p>
      <p>Niederschlag: ${weather.rain} mm</p>
    `;
  } catch {
    document.getElementById("weather").textContent = "Nicht verfügbar.";
  }

  try {
    const crypto = await loadJson("../data/crypto.json");
    document.getElementById("crypto").innerHTML = `
      <p>Bitcoin: ${crypto.bitcoin_chf} CHF</p>
      <p>Ethereum: ${crypto.ethereum_chf} CHF</p>
      <p>Solana: ${crypto.solana_chf} CHF</p>
    `;
  } catch {
    document.getElementById("crypto").textContent = "Nicht verfügbar.";
  }
}

loadDashboard();
setInterval(loadDashboard, 60000);
