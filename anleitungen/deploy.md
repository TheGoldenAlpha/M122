# Code deployen

## 1. Von Windows pushen

In PowerShell oder Git Bash:

```bash
cd C:\Users\flori\Desktop\Module\M122\AllMyDay
git add .
git commit -m "Beschreibung der Änderung"
git push
```

## 2. In WSL holen

```bash
cd ~/pr2/src/M122 && git pull && bash daily-dashboard/scripts/update.sh
```

Dann `http://localhost:8347/public/` neu laden.

## Automatisch (nach Cron-Setup)

Sobald der Cron läuft, macht WSL alle 10 Minuten automatisch `git pull`.  
Du pushst von Windows — WSL holt den Rest selbst.
