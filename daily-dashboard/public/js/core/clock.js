/**
 * clock.js
 * uhr und datum im header aktualisieren
 * - uhrzeit im format HH:MM (de-CH)
 * - datum mit wochentag, tag, monat, jahr (de-CH)
 */

// uhrzeit und datum in header-elemente schreiben
function updateClock() {
  const now = new Date();
  document.getElementById("headerTime").textContent =
    now.toLocaleTimeString("de-CH", { hour: "2-digit", minute: "2-digit" });
  document.getElementById("headerDate").textContent =
    now.toLocaleDateString("de-CH", { weekday: "long", day: "numeric", month: "long", year: "numeric" });
}
