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

echo  [2/3] Daten aktualisieren (laeuft im Hintergrund)...
start "All My Day – Update" wsl -e bash -c "cd /mnt/c/Users/flori/Desktop/Module/M122/AllMyDay/daily-dashboard && bash scripts/update.sh && echo DONE"

timeout /t 5 /nobreak >nul

echo  [3/3] Webserver starten auf http://localhost:8347
echo.
echo  Oeffne http://localhost:8347 im Browser
echo  (Strg+C zum Beenden)
echo.
wsl -e bash -c "cd /mnt/c/Users/flori/Desktop/Module/M122/AllMyDay/daily-dashboard && python3 -m http.server 8347 --bind 127.0.0.1"

pause
