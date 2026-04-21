# Cronjob einrichten

## 1. Cron starten

```bash
sudo service cron start
```

## 2. Crontab öffnen

```bash
crontab -e
```

Beim ersten Mal fragt er nach einem Editor — wähle `1` (nano).

## 3. Diese zwei Zeilen ganz unten einfügen

```
*/2 * * * * cd /home/florianh/pr2/src/M122 && git pull >> /home/florianh/pr2/src/M122/daily-dashboard/logs/gitpull.log 2>&1

*/2 * * * * cd /home/florianh/pr2/src/M122/daily-dashboard && bash scripts/update.sh >> /home/florianh/pr2/src/M122/daily-dashboard/logs/cron-update.log 2>&1
```

Speichern: `Ctrl+O` → Enter → `Ctrl+X`

## Was passiert alle 2 Minuten

1. `git pull` — holt neuen Code von GitHub
2. `update.sh` — ruft news.sh, weather.sh, crypto.sh auf → schreibt JSON-Dateien

## Prüfen ob es läuft

```bash
# Läuft cron überhaupt?
sudo service cron status

# Wurden die Scripts ausgeführt?
cat /home/florianh/pr2/src/M122/daily-dashboard/logs/cron-update.log

# Wurden JSON-Dateien erstellt?
ls /home/florianh/pr2/src/M122/daily-dashboard/data/
```

## Einmalig manuell ausführen (zum Testen)

```bash
cd /home/florianh/pr2/src/M122/daily-dashboard
bash scripts/update.sh
ls data/
```

## Hinweis

Cron läuft nur solange WSL offen ist. Beim nächsten WSL-Start:

```bash
sudo service cron start
```
