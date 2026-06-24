@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: ============================================================
::  dump_and_push.bat
::  Вивантажує конфігурацію 1С в файли, комітить і пушить
:: ============================================================

:: --- Налаштування -----------------------------------------------------------
:: Шлях до виконавчого файлу 1С (перевірте версію платформи)
set "V8="C:\Program Files\1cv8\8.3.18.1483\bin\1cv8.exe""

:: Тип підключення: FILE або SERVER
set "CONNECTION_TYPE=SERVER"

:: FILE: шлях до файлової бази (для файлового варіанту)
set "IB_PATH=C:\utp"

:: SERVER: сервер і ім'я бази (для серверного варіанту)
set "IB_SERVER=127.0.0.1"
set "IB_NAME=utp_dev"

:: Логін і пароль адміністратора конфігуратора (залиште порожніми якщо не потрібно)
set "IB_USER="
set "IB_PASS="

:: Шлях до репозиторію з конфігурацією (куди вивантажувати)
set "REPO_PATH=%~dp0"
:: Видаляємо зворотній слеш з кінця якщо є
if "!REPO_PATH:~-1!"=="\" set "REPO_PATH=!REPO_PATH:~0,-1!"

:: Git: повідомлення коміту (якщо не передано аргументом)
set "COMMIT_MSG=%~1"
if "!COMMIT_MSG!"=="" (
    for /f "tokens=1-3 delims=/ " %%a in ("%date%") do set "TODAY=%%c%%b%%a"
    for /f "tokens=1-2 delims=:." %%a in ("%time: =0%") do set "TIMESTR=%%a%%b"
    set "COMMIT_MSG=auto: dump !TODAY! !TIMESTR!"
)

:: ---------------------------------------------------------------------------
echo.
echo ============================================================
echo  1C UTP -- вивантаження + git push
echo ============================================================
echo  Репозиторій : !REPO_PATH!
echo  Повідомлення: !COMMIT_MSG!
echo ============================================================
echo.

:: --- Перевірка наявності 1С -------------------------------------------------
if not exist %V8% (
    echo [ПОМИЛКА] Виконавчий файл 1С не знайдено: %V8%
    echo Відредагуйте змінну V8 у батніку.
    pause
    exit /b 1
)

:: --- Формування рядка підключення -------------------------------------------
if /i "!CONNECTION_TYPE!"=="FILE" (
    set "IB_CONNECT=/F"!IB_PATH!""
) else (
    set "IB_CONNECT=/S"!IB_SERVER!\!IB_NAME!""
)

if "!IB_USER!"=="" (
    set "AUTH_PARAMS="
) else (
    if "!IB_PASS!"=="" (
        set "AUTH_PARAMS=/N"!IB_USER!""
    ) else (
        set "AUTH_PARAMS=/N"!IB_USER!" /P"!IB_PASS!""
    )
)

:: --- Вивантаження конфігурації в файли -------------------------------------
echo [1/3] Вивантаження конфігурації в файли...
echo.

%V8% CONFIG !IB_CONNECT! !AUTH_PARAMS! /DumpConfigToFiles "!REPO_PATH!" /UpdateDBCfg- 2>&1

if errorlevel 1 (
    echo.
    echo [ПОМИЛКА] Вивантаження завершилось з помилкою (код: %errorlevel%)
    echo Перевірте підключення до бази та параметри у батніку.
    pause
    exit /b 1
)

echo.
echo [OK] Вивантаження завершено.

:: --- Git commit -------------------------------------------------------------
echo.
echo [2/3] Git commit...

cd /d "!REPO_PATH!"

git add -A
if errorlevel 1 (
    echo [ПОМИЛКА] git add завершився з помилкою.
    pause
    exit /b 1
)

:: Перевіряємо чи є що комітити
git diff --cached --quiet
if %errorlevel%==0 (
    echo [INFO] Немає змін для коміту. Вивантаження не принесло нових даних.
    goto :done
)

git commit -m "!COMMIT_MSG!"
if errorlevel 1 (
    echo [ПОМИЛКА] git commit завершився з помилкою.
    pause
    exit /b 1
)

echo [OK] Коміт створено.

:: --- Git push ---------------------------------------------------------------
echo.
echo [3/3] Git push...

git push origin main
if errorlevel 1 (
    echo [ПОМИЛКА] git push завершився з помилкою.
    echo Перевірте SSH-ключ або мережеве з'єднання.
    pause
    exit /b 1
)

echo [OK] Push виконано.

:done
echo.
echo ============================================================
echo  Готово!
echo ============================================================
echo.
pause
endlocal
