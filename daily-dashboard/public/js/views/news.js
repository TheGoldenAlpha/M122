/**
 * news.js
 * nachrichtenliste aus news.json anzeigen
 * - übersicht: top 7 meldungen im startbildschirm
 * - vollständige liste im news-tab
 * - jede meldung als klickbarer link zur originalquelle
 */

// nachrichten in übersicht (top 7) und vollständige liste laden und rendern
async function loadNews() {
  try {
    const n = await loadJson("../../data/news.json");
    document.getElementById("ovNews").innerHTML = n.items.slice(0, 7).map((item, i) => `
      <a class="news-item" href="${item.url || '#'}" target="_blank" rel="noopener">
        <span class="news-num">${i + 1}</span>
        <span>${item.title}</span>
        <svg class="news-arrow" xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
      </a>
    `).join("");
    document.getElementById("newsFullList").innerHTML = n.items.map((item, i) => `
      <a class="news-full-item" href="${item.url || '#'}" target="_blank" rel="noopener">
        <span class="news-full-num">${i + 1}</span>
        <span class="news-full-text">${item.title}</span>
        <svg class="news-arrow" xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
      </a>
    `).join("");
  } catch {
    document.getElementById("ovNews").textContent = "Nachrichten nicht verfügbar.";
  }
}
