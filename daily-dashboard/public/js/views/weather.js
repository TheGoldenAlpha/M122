/**
 * weather.js
 * wetterdaten anzeigen — übersicht und detailansicht
 * - übersicht: temperatur, wind, regen aus weather.json
 * - detail: stundenwerte aus weather_<stadt>.json (9 städte)
 * - stunden-buttons zum wechseln zwischen zeitpunkten
 */

let liveWeatherData = null;
let selectedHour    = -1; // -1 = aktuelle stunde

// übersicht-widget befüllen (zürich, aus weather.json)
async function loadWeather() {
  try {
    const w = await loadJson("../../data/weather.json");
    document.getElementById("ovTemp").textContent = w.temperature + "°";
    document.getElementById("ovWind").textContent = w.wind;
    document.getElementById("ovRain").textContent = w.rain;
  } catch {
    document.getElementById("ovTemp").textContent = "–";
  }
}

// temperatur, wind, regen für gewählte stunde anzeigen
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

// stunden-buttons (jetzt, 00:00–21:00) mit temperatur rendern
function buildHourSelector(data) {
  const hours = [-1, 0, 3, 6, 9, 12, 15, 18, 21];
  document.getElementById("hourSelector").innerHTML = hours.map(h => {
    const label  = h === -1 ? "Jetzt" : `${String(h).padStart(2, "0")}:00`;
    const temp   = h === -1
      ? Math.round(data.current.temperature_2m)
      : Math.round(data.hourly.temperature_2m[h]);
    const active = h === selectedHour ? "active" : "";
    return `<button class="hour-btn ${active}" onclick="selectHour(${h})">
      <span class="hour-label">${label}</span>
      <span class="hour-temp">${temp}°</span>
    </button>`;
  }).join("");
}

// stunde auswählen und wetterwerte aktualisieren
function selectHour(hour) {
  selectedHour = hour;
  document.querySelectorAll(".hour-btn").forEach(b => b.classList.remove("active"));
  event.currentTarget.classList.add("active");
  if (liveWeatherData) displayWeatherForHour(liveWeatherData, hour);
}

// detailansicht für gewählte stadt laden (aus weather_<key>.json)
async function loadWeatherDetail() {
  const select = document.getElementById("citySelect");
  const key    = select.value;
  document.getElementById("weatherCityLabel").textContent =
    select.options[select.selectedIndex].text;
  document.getElementById("detTemp").textContent = "…";
  document.getElementById("detWind").textContent = "…";
  document.getElementById("detRain").textContent = "…";
  try {
    liveWeatherData = await loadJson(`../../data/weather_${key}.json`);
    selectedHour    = -1;
    buildHourSelector(liveWeatherData);
    displayWeatherForHour(liveWeatherData, -1);
  } catch {
    document.getElementById("detTemp").textContent = "–";
  }
}
