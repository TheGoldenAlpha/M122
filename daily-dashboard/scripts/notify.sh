#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

CONFIG="$DATA_DIR/notify-config.json"
if [ ! -f "$CONFIG" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [notify] Kein Config ($CONFIG)" >> "$LOG_DIR/update.log"
    exit 0
fi

# Daten aktualisieren
bash "$PROJECT_DIR/scripts/update.sh" > /dev/null 2>&1

python3 << PYEOF
import json, smtplib, urllib.request
from email.mime.text import MIMEText

with open("$CONFIG", encoding="utf-8") as f:
    cfg = json.load(f)

def load(name):
    try:
        with open("$DATA_DIR/" + name + ".json", encoding="utf-8") as f:
            return json.load(f)
    except:
        return None

# Nachricht zusammenstellen
w   = load("weather")
n   = load("news")
c   = load("crypto")
com = load("commodities") or []

weather  = f"{w['temperature']}°C · {w['wind']} km/h Wind · {w['rain']} mm Regen" if w else "–"
headline = n["items"][0]["title"] if n and n.get("items") else "–"
btc      = f"{c['bitcoin_chf']:,.0f} CHF" if c else "–"
gold     = next((x for x in com if x["symbol"] == "GC=F"), None)
silver   = next((x for x in com if x["symbol"] == "SI=F"), None)
gold_p   = f"{gold['price']:,.0f} USD/oz"  if gold   else "–"
silver_p = f"{silver['price']:.2f} USD/oz" if silver else "–"

msg = f"""🌅 Guten Morgen!

🌤️ Wetter Zürich: {weather}

📰 Schlagzeile:
{headline}

💰 Märkte:
🥇 Gold: {gold_p}
🥈 Silber: {silver_p}
₿ Bitcoin: {btc}

Ich wünsche dir einen schönen Tag! Bis morgen 😊"""

# ── E-Mail ──
if cfg.get("email_enabled"):
    try:
        mail = MIMEText(msg, "plain", "utf-8")
        mail["Subject"] = "🌅 Guten Morgen – All My Day"
        mail["From"]    = cfg["email_from"]
        mail["To"]      = cfg["email_to"]
        with smtplib.SMTP(cfg.get("smtp_host","smtp.gmail.com"), cfg.get("smtp_port",587)) as s:
            s.starttls()
            s.login(cfg["email_from"], cfg["email_pass"])
            s.send_message(mail)
        print("E-Mail OK")
    except Exception as e:
        print(f"E-Mail FEHLER: {e}")

# ── Telegram ──
if cfg.get("tg_enabled"):
    try:
        url  = f"https://api.telegram.org/bot{cfg['tg_token']}/sendMessage"
        data = json.dumps({"chat_id": cfg["tg_chat_id"], "text": msg}).encode()
        req  = urllib.request.Request(url, data, {"Content-Type":"application/json"})
        urllib.request.urlopen(req, timeout=15)
        print("Telegram OK")
    except Exception as e:
        print(f"Telegram FEHLER: {e}")
PYEOF

echo "$(date '+%Y-%m-%d %H:%M:%S') [notify] fertig" >> "$LOG_DIR/update.log"
