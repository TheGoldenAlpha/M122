/**
 * nav.js
 * navigation, sidebar und modals steuern
 * - top-navigation: tab wechseln, aktiven zustand setzen
 * - mobile sidebar: öffnen/schliessen mit overlay
 * - datenquellen-modal: öffnen/schliessen (auch per escape-taste)
 * - sidebar-navigation synchron mit top-navigation halten
 */

// mobile sidebar öffnen
function openSidebar() {
  document.getElementById("mobileSidebar").classList.add("open");
  document.getElementById("sidebarOverlay").classList.add("open");
  document.body.style.overflow = "hidden";
}

// mobile sidebar schliessen
function closeSidebar() {
  document.getElementById("mobileSidebar").classList.remove("open");
  document.getElementById("sidebarOverlay").classList.remove("open");
  document.body.style.overflow = "";
}

// datenquellen-modal öffnen
function openSourcesModal() {
  document.getElementById("sourcesOverlay").classList.add("open");
  document.body.style.overflow = "hidden";
}

// datenquellen-modal schliessen
function closeSourcesModal() {
  document.getElementById("sourcesOverlay").classList.remove("open");
  document.body.style.overflow = "";
}

// modal mit escape-taste schliessen
document.addEventListener("keydown", e => { if (e.key === "Escape") closeSourcesModal(); });

// section wechseln via sidebar (top- und sidebar-nav synchron halten)
function sidebarNav(section) {
  document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
  document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
  const topBtn  = document.querySelector(`.nav-btn[data-section="${section}"]`);
  if (topBtn) topBtn.classList.add("active");
  document.getElementById(section).classList.add("active");
  document.querySelectorAll(".sidebar-nav-btn").forEach(b => b.classList.remove("active"));
  const sideBtn = document.querySelector(`.sidebar-nav-btn[data-section="${section}"]`);
  if (sideBtn) sideBtn.classList.add("active");
  if (section === "wetter")        loadWeatherDetail();
  if (section === "sport")         loadSport();
  if (section === "rohstoffe")     loadCommodities();
  if (section === "aktien")        loadStocks();
  if (section === "coins")         loadCoins();
  closeSidebar();
}

// klick-events für top-nav und sport-tiles registrieren
function setupNav() {
  document.querySelectorAll(".nav-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
      document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
      btn.classList.add("active");
      document.getElementById(btn.dataset.section).classList.add("active");
      document.querySelectorAll(".sidebar-nav-btn").forEach(b => b.classList.remove("active"));
      const sideBtn = document.querySelector(`.sidebar-nav-btn[data-section="${btn.dataset.section}"]`);
      if (sideBtn) sideBtn.classList.add("active");
      if (btn.dataset.section === "wetter")        loadWeatherDetail();
      if (btn.dataset.section === "sport")         loadSport();
      if (btn.dataset.section === "rohstoffe")     loadCommodities();
      if (btn.dataset.section === "aktien")        loadStocks();
      if (btn.dataset.section === "coins")         loadCoins();
    });
  });
  // sport-kacheln in der seitenleiste
  document.querySelectorAll(".sport-tile").forEach(btn => {
    btn.addEventListener("click", () => renderSportList(btn.dataset.sport));
  });
}
