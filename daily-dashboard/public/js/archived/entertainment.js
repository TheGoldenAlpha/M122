/**
 * entertainment.js
 * entertainment-nachrichten aus entertainment.json anzeigen
 * - tabs: gaming und filme/serien
 * - artikel-karten mit bild, titel, quelle, datum, kurzbeschreibung
 */

// zwischen gaming- und film-tab wechseln
function entSwitchTab(btn) {
  document.querySelectorAll(".ent-tab").forEach(b => b.classList.remove("active"));
  btn.classList.add("active");
  document.querySelectorAll(".ent-panel").forEach(p => p.style.display = "none");
  document.getElementById("ent-" + btn.dataset.tab).style.display = "block";
}

// einzelne artikel-karte als html-string erzeugen
function entArticleCard(item) {
  const imgHtml = item.image
    ? `<img class="ent-card-img" src="${item.image}" alt="" loading="lazy" onerror="this.style.display='none'" />`
    : "";
  const desc = item.desc
    ? `<div class="ent-card-desc">${item.desc.slice(0, 160)}${item.desc.length > 160 ? "…" : ""}</div>`
    : "";
  const meta = [item.source, item.date].filter(Boolean).join(" · ");
  return `<a class="ent-article-card" href="${item.url}" target="_blank" rel="noopener">
    ${imgHtml ? `<div class="ent-card-img-wrap">${imgHtml}</div>` : ""}
    <div class="ent-card-body">
      <div class="ent-card-title">${item.title}</div>
      ${meta ? `<div class="ent-card-meta">${meta}</div>` : ""}
      ${desc}
    </div>
  </a>`;
}

// artikel-liste in ein grid-element rendern
function entRenderGrid(gridId, items) {
  const el = document.getElementById(gridId);
  if (!el) return;
  el.innerHTML = items.length
    ? items.map(item => entArticleCard(item)).join("")
    : '<div class="ent-empty">Keine Artikel gefunden.</div>';
}

// entertainment-daten laden und beide grids rendern
async function loadEntertainment() {
  try {
    const data = await loadJson("../../data/entertainment.json");
    entRenderGrid("gamingGrid", data.gaming || []);
    entRenderGrid("moviesGrid", data.movies || []);
  } catch {
    document.getElementById("gamingGrid").innerHTML =
      '<div class="ent-error">Daten nicht verfügbar. <code>bash scripts/update.sh</code> ausführen.</div>';
  }
}
