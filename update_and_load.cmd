@echo off
chcp 65001 > nul
echo === Стягування змін з репозиторія ===
cd /d C:\utp
git pull
if %ERRORLEVEL% NEQ 0 (
    echo ПОМИЛКА: git pull завершився з помилкою
    pause
    exit /b 1
)

echo.
echo === Завантаження конфігурації в 1С ===
"C:\Program Files\1cv8\8.3.18.1483\bin\1cv8.exe" DESIGNER ^
  /IBConnectionString "Srvr=127.0.0.1;Ref=utp_dev;" ^
  /LoadConfigFromFiles "C:\utp" ^
  /UpdateDBCfg ^
  /DisableStartupDialogs ^
  /Out "C:\utp\load_log.txt" ^
  -NoTruncate

if %ERRORLEVEL% NEQ 0 (
    echo ПОМИЛКА завантаження конфігурації. Дивіться load_log.txt
    pause
    exit /b 1
)

echo.
echo === Готово ===
type "C:\utp\load_log.txt"
pause
