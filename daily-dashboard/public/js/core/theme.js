/**
 * theme.js
 * dark/light mode verwalten
 * - zustand in localStorage speichern
 * - beim laden aus localStorage wiederherstellen
 * - sidebar-toggle synchron halten
 */

// gespeicherten theme-zustand beim start anwenden
function initDarkMode() {
  if (localStorage.getItem("theme") === "dark") {
    document.body.classList.add("dark");
    const cb = document.getElementById("darkToggleSidebar");
    if (cb) cb.checked = true;
  }
}

// dark/light umschalten und in localStorage speichern
function toggleDarkMode() {
  const isDark = document.body.classList.toggle("dark");
  localStorage.setItem("theme", isDark ? "dark" : "light");
  const cb = document.getElementById("darkToggleSidebar");
  if (cb) cb.checked = isDark;
}
