@echo off
cd /d "%~dp0"
echo.
echo App:   http://localhost:5500/
echo Admin: http://localhost:5500/admin/admin.html
echo.
echo Para desligar: Ctrl+C
python -m http.server 5500
pause
