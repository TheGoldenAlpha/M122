@echo off
cd /d C:\Users\flori\Desktop\Module\M122\AllMyDay
git add .
git commit -m "Update %date% %time%"
git push
echo.
echo Fertig! Code wurde auf GitHub geladen.
pause
