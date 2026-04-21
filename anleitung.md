# Daily Dashboard – Anleitung

## Architektur

```
Windows VS Code
   ↓ git push
GitHub Repository
   ↓ git pull via cron
WSL Ubuntu
   ↓ bash scripts/update.sh
JSON Daten
   ↓ JavaScript fetch()
HTML Dashboard
   ↓ Python http.server
http://localhost:8000/public/
```

---

## Projektstruktur

```
daily-dashboard/
├── public/
│   ├── index.html
│   ├── style.css
│   └── app.js
├── scripts/
│   ├── update.sh
│   ├── news.sh
│   ├── weather.sh
│   └── crypto.sh
├── data/
│   ├── news.json
│   ├── weather.json
│   └── crypto.json
├── logs/
└── .gitignore
```

---

## Teil 1 – Windows vorbereiten

Installiere:

- **VS Code** – zum Schreiben
- **Git for Windows** – damit du von Windows aus pushen kannst
- **GitHub Account** – hast du schon oder neu erstellen
- **WSL Ubuntu** – hast du schon

---

## Teil 2 – GitHub Repository erstellen

Erstelle auf GitHub ein neues Repository, z. B. `daily-dashboard`.

Public oder Private ist egal. Du bekommst eine URL wie:

```
git@github.com:DEINNAME/daily-dashboard.git
```

Wir verwenden SSH, damit cron später ohne Passwort pullen kann.

---

## Teil 3 – Projekt auf Windows erstellen

Öffne Git Bash auf Windows:

```bash
cd ~/Documents
mkdir daily-dashboard
cd daily-dashboard
mkdir public scripts data logs
touch public/index.html public/style.css public/app.js
touch scripts/update.sh scripts/news.sh scripts/weather.sh scripts/crypto.sh
touch README.md
code .
```

---

## Teil 4 – HTML/CSS/JS

**public/index.html**

```html
<!DOCTYPE html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <title>Daily Dashboard</title>
    <link rel="stylesheet" href="style.css" />
  </head>
  <body>
    <h1>Daily Dashboard</h1>
    <p id="lastUpdate">Lade Daten...</p>

    <section class="card">
      <h2>News</h2>
      <div id="news">Lade News...</div>
    </section>

    <section class="card">
      <h2>Wetter</h2>
      <div id="weather">Lade Wetter...</div>
    </section>

    <section class="card">
      <h2>Krypto</h2>
      <div id="crypto">Lade Krypto...</div>
    </section>

    <script src="app.js"></script>
  </body>
</html>
```

**public/style.css**

```css
body {
  font-family: Arial, sans-serif;
  background: #111827;
  color: #f9fafb;
  margin: 30px;
}

h1 {
  margin-bottom: 5px;
}

.card {
  background: #1f2937;
  padding: 18px;
  border-radius: 12px;
  margin-top: 20px;
}

h2 {
  color: #93c5fd;
}

.item {
  padding: 6px 0;
  border-bottom: 1px solid #374151;
}

.small {
  color: #9ca3af;
}
```

**public/app.js**

```js
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
```

---

## Teil 5 – Bash-Skripte

Du schreibst sie in VS Code auf Windows, sie laufen später in Ubuntu.

**scripts/news.sh**

```bash
#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"

TMP_FILE="$DATA_DIR/news.tmp"
OUT_FILE="$DATA_DIR/news.json"

curl -s "https://news.google.com/rss?hl=de&gl=CH&ceid=CH:de" \
| grep -oP '<title>.*?</title>' \
| sed 's/<title>//g; s/<\/title>//g' \
| tail -n +2 \
| head -n 10 \
| jq -R . \
| jq -s '{items: map({title: .})}' > "$TMP_FILE"

mv "$TMP_FILE" "$OUT_FILE"
```

**scripts/weather.sh**

```bash
#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"
OUT_FILE="$DATA_DIR/weather.json"

DATA=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=47.3769&longitude=8.5417&current=temperature_2m,wind_speed_10m,precipitation&timezone=Europe%2FZurich")

TEMP=$(echo "$DATA" | jq -r '.current.temperature_2m')
WIND=$(echo "$DATA" | jq -r '.current.wind_speed_10m')
RAIN=$(echo "$DATA" | jq -r '.current.precipitation')

cat > "$OUT_FILE" <<EOF
{
  "city": "Zürich",
  "temperature": "$TEMP",
  "wind": "$WIND",
  "rain": "$RAIN"
}
EOF
```

**scripts/crypto.sh**

```bash
#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
mkdir -p "$DATA_DIR"
OUT_FILE="$DATA_DIR/crypto.json"

DATA=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=chf")

BTC=$(echo "$DATA" | jq -r '.bitcoin.chf')
ETH=$(echo "$DATA" | jq -r '.ethereum.chf')
SOL=$(echo "$DATA" | jq -r '.solana.chf')

cat > "$OUT_FILE" <<EOF
{
  "bitcoin_chf": "$BTC",
  "ethereum_chf": "$ETH",
  "solana_chf": "$SOL"
}
EOF
```

**scripts/update.sh**

```bash
#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

echo "Update gestartet: $(date)" >> "$LOG_DIR/update.log"
bash "$PROJECT_DIR/scripts/news.sh"
bash "$PROJECT_DIR/scripts/weather.sh"
bash "$PROJECT_DIR/scripts/crypto.sh"
echo "Update fertig: $(date)" >> "$LOG_DIR/update.log"
```

---

## Teil 6 – Zu GitHub pushen

In Git Bash auf Windows, im Projektordner:

```bash
cd C:\Users\flori\Desktop\Module\M122\AllMyDay
git init
git add .
git commit -m "Start daily dashboard"
git branch -M main
git remote add origin https://github.com/TheGoldenAlpha/M122.git
git push -u origin main
```

**Falls der Push mit `error: src refspec main does not match any` fehlschlägt** (passiert wenn Git den Branch `master` statt `main` nennt):

```bash
git branch -M main
git push -u origin main
```

---

## Teil 7 – WSL Ubuntu vorbereiten

```bash
sudo apt update
sudo apt install git curl jq python3 cron -y

git config --global user.name "DEIN NAME"
git config --global user.email "DEINE_EMAIL"
```

---

## Teil 8 – SSH-Key in WSL erstellen

```bash
ssh-keygen -t ed25519 -C "DEINE_EMAIL"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Den angezeigten Text kopieren und auf GitHub einfügen:

> Settings → SSH and GPG keys → New SSH key → Einfügen → Save

Verbindung testen:

```bash
ssh -T git@github.com
```

Wenn da steht `Hi DEINNAME! You've successfully authenticated...` passt es.

---

## Teil 9 – Repository in WSL klonen

```bash
cd ~
git clone git@github.com:DEINNAME/daily-dashboard.git
cd daily-dashboard
chmod +x scripts/*.sh
bash scripts/update.sh
ls data
cat data/weather.json
```

---

## Teil 10 – Webserver starten

Wichtig: Den Server im Projektordner starten, nicht in `public/`, weil `app.js` auf `../data/` zugreift.

```bash
cd ~/daily-dashboard
python3 -m http.server 8000 --bind 127.0.0.1
```

Dann im Windows-Browser:

```
http://localhost:8000/public/
```

---

## Teil 11 – Cron aktivieren

```bash
sudo service cron start
crontab -e
```

Ganz unten einfügen (Username mit `whoami` herausfinden):

```
*/10 * * * * cd /home/DEIN_USERNAME/daily-dashboard && git pull >> logs/gitpull.log 2>&1
*/10 * * * * cd /home/DEIN_USERNAME/daily-dashboard && bash scripts/update.sh >> logs/cron-update.log 2>&1
```

Alle 10 Minuten: neuen Code holen und Daten aktualisieren.

> Hinweis: Cron läuft nur, solange WSL offen ist. Für echten Dauerbetrieb bräuchtest du einen richtigen Server oder eine VM – für die Schule reicht das hier aber.

---

## Teil 12 – .gitignore

Erstelle auf Windows im Projektordner eine Datei `.gitignore`:

```
logs/
data/*.json
```

```bash
git add .gitignore
git commit -m "Ignore generated data and logs"
git push
```

Die JSON-Daten werden nur lokal erzeugt, nicht auf GitHub gespeichert.

---

## Häufige Fehler

**Seite lädt, aber keine Daten:**

```bash
bash scripts/update.sh
ls data
```

**`jq: command not found`:**

```bash
sudo apt install jq -y
```

**git pull fragt nach Passwort:**

```bash
git remote -v
# Wenn da https://... steht:
git remote set-url origin git@github.com:DEINNAME/daily-dashboard.git
```

**Cron läuft nicht:**

```bash
sudo service cron start
cat ~/daily-dashboard/logs/cron-update.log
```

**Port 8000 belegt:**

```bash
python3 -m http.server 8080 --bind 127.0.0.1
# Dann: http://localhost:8080/public/
```
