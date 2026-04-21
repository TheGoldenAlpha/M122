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
      if (btn.dataset.section === "wetter") loadWeatherDetail();
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
