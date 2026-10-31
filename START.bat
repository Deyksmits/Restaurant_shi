@echo off
setlocal enabledelayedexpansion
title TasteMatch - Lokale Testserver voor iPhone
cd /d "%~dp0"
cls

echo ======================================================================
echo             TASTEMATCH - LOKALE TESTSERVER VOOR IPHONE
echo ======================================================================
echo.

:: Oude lockfile opruimen indien aanwezig
if exist "C:\Users\dosmi\flutter\bin\cache\lockfile" (
    del /f /q "C:\Users\dosmi\flutter\bin\cache\lockfile" >nul 2>&1
)

:: Zoek lokaal IPv4-adres via ipconfig
set LOCAL_IP=192.168.2.10
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set LOCAL_IP=%%b
    )
)

echo [1] Zorg dat je iPhone met hetzelfde Wi-Fi-netwerk verbonden is.
echo [2] Open Safari op je iPhone en ga naar:
echo.
echo        http://!LOCAL_IP!:8080
echo.
echo [3] Tik in Safari onderaan op het Deel-icoon (vierkantje met pijl omhoog)
echo     en kies: "Zet op beginscherm".
echo.
echo ======================================================================
echo Flutter webserver wordt gestart op 0.0.0.0:8080...
echo Typ 'r' voor Hot Reload of 'q' om af te sluiten.
echo ======================================================================
echo.

flutter.bat run -d web-server --web-hostname=0.0.0.0 --web-port=8080

echo.
echo ======================================================================
echo De server is gestopt.
echo ======================================================================
pause
