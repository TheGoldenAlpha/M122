/**
 * sport.js
 * sportnachrichten aus sport.json anzeigen
 * - kategorien: fussball, eishockey, tennis, ski, formel1, usw.
 * - seitenleiste zum wechseln der kategorie
 * - quellenangabe aus titel extrahieren (format: "titel - quelle")
 */

// metadaten je sportkategorie: emoji und anzeigename
const SPORT_META = {
  fussball:       { emoji: "⚽", label: "Fussball"       },
  eishockey:      { emoji: "🏒", label: "Eishockey"      },
  unihockey:      { emoji: "🏑", label: "Unihockey"      },
  handball:       { emoji: "🤾", label: "Handball"       },
  tennis:         { emoji: "🎾", label: "Tennis"         },
  ski:            { emoji: "⛷️", label: "Ski Alpin"      },
  leichtathletik: { emoji: "🏃", label: "Leichtathletik" },
  basketball:     { emoji: "🏀", label: "Basketball"     },
  formel1:        { emoji: "🏎️", label: "Formel 1"       },
  volleyball:     { emoji: "🏐", label: "Volleyball"     },
};

let sportData   = null;
let activeSport = "fussball";

// quelle aus titelstring trennen (format: "titel - quelle")
function parseSportTitle(raw) {
  const idx = raw.lastIndexOf(" - ");
  if (idx > 10) return { title: raw.slice(0, idx), source: raw.slice(idx + 3) };
  return { title: raw, source: "" };
}

// nachrichten-liste für gewählte sportkategorie rendern
function renderSportList(key) {
  activeSport = key;
  document.querySelectorAll(".sport-tile").forEach(b =>
    b.classList.toggle("active", b.dataset.sport === key));
  const meta  = SPORT_META[key] || { emoji: "🏅", label: key };
  document.getElementById("sportEmoji").textContent = meta.emoji;
  document.getElementById("sportTitle").textContent = meta.label;
  const list  = document.getElementById("sportList");
  if (!sportData) { list.innerHTML = '<div class="sport-loading">Lade...</div>'; return; }
  const items = sportData[key] || [];
  if (!items.length) { list.innerHTML = '<div class="sport-empty">Keine Nachrichten gefunden.</div>'; return; }
  list.innerHTML = items.map((item, i) => {
    const { title, source } = parseSportTitle(item.title);
    return `
      <a class="sport-news-item" href="${item.url || '#'}" target="_blank" rel="noopener">
        <span class="sport-news-num">${i + 1}</span>
        <div class="sport-news-body">
          <div class="sport-news-title-text">${title}</div>
          ${source ? `<span class="sport-news-source">${source}</span>` : ""}
        </div>
        <svg class="sport-news-arrow" xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h10v10"/><path d="M7 17 17 7"/></svg>
      </a>`;
  }).join("");
}

// sportdaten laden und aktive kategorie rendern
async function loadSport() {
  try {
    sportData = await loadJson("../../data/sport.json");
    renderSportList(activeSport);
  } catch {
    document.getElementById("sportList").innerHTML =
      '<div class="sport-empty">Sportdaten nicht verfügbar. <code>bash scripts/update.sh</code></div>';
  }
}
