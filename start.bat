@echo off
title All My Day – Server
echo.
echo  ========================================
echo   All My Day – Dashboard starten
echo  ========================================
echo.

echo  [1/3] WSL Netzwerk zuruecksetzen...
wsl --shutdown
timeout /t 3 /nobreak >nul

echo  [2/3] Alle Daten laden (bitte warten)...
wsl -e bash -c "cd /mnt/c/Users/flori/Desktop/Module/M122/AllMyDay/daily-dashboard && bash scripts/update.sh"
echo  Daten bereit!
echo.

echo  [3/3] Server starten...
start "" wsl -e bash -c "cd /mnt/c/Users/flori/Desktop/Module/M122/AllMyDay/daily-dashboard && python3 -m http.server 8347 --bind 127.0.0.1"
timeout /t 2 /nobreak >nul

start http://localhost:8347/public/
echo  Browser geoeffnet. Server laeuft.
echo  Dieses Fenster offen lassen (Server laeuft darin).
echo.
pause
