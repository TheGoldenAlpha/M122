# Server starten

In WSL:

```bash
cd ~/pr2/src/M122/daily-dashboard
python3 -m http.server 8347 --bind 127.0.0.1
```

Browser: `http://localhost:8347/public/`

## Stoppen

`Ctrl + C` im WSL-Terminal.

Falls Terminal geschlossen:

```bash
pkill -f "http.server"
```
