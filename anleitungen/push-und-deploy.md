# Push & Deploy

## 1. Windows — Code pushen

```bash
cd C:\Users\flori\Desktop\Module\M122\AllMyDay
git add .
git commit -m "Beschreibung"
git push
```

## 2. WSL — Code holen & Daten aktualisieren

```bash
cd ~/pr2/src/M122 && git pull && bash daily-dashboard/scripts/update.sh
```

## 3. Server starten (falls nicht läuft)

```bash
cd ~/pr2/src/M122/daily-dashboard
python3 -m http.server 8347 --bind 127.0.0.1
```

## Browser

```
http://localhost:8347/public/
```
