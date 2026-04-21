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
    document.getElementById("detTemp").textContent = w.temperature;
    document.getElementById("detWind").textContent = w.wind;
    document.getElementById("detRain").textContent = w.rain;
  } catch {
    document.getElementById("ovTemp").textContent = "–";
  }
}

async function loadNews() {
  try {
    const n = await loadJson("../data/news.json");

    document.getElementById("ovNews").innerHTML = n.items.slice(0, 7)
      .map((item, i) => `
        <div class="news-item">
          <span class="news-num">${i + 1}</span>
          <span>${item.title}</span>
        </div>
      `).join("");

    document.getElementById("newsFullList").innerHTML = n.items
      .map((item, i) => `
        <div class="news-full-item">
          <span class="news-full-num">${i + 1}</span>
          <span class="news-full-text">${item.title}</span>
        </div>
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

function setupNav() {
  document.querySelectorAll(".nav-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
      document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
      btn.classList.add("active");
      document.getElementById(btn.dataset.section).classList.add("active");
    });
  });
}

updateClock();
setInterval(updateClock, 1000);
setupNav();
refreshData();
setInterval(refreshData, 60000);

if (window.lucide) lucide.createIcons();
window.addEventListener("load", () => { if (window.lucide) lucide.createIcons(); });
