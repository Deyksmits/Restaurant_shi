@echo off
title Push naar GitHub voor iOS IPA Build
cd /d "%~dp0"
cls

echo ======================================================================
echo          PUSH NAAR GITHUB OM DE IOS IPA TE BOUWEN
echo ======================================================================
echo.
echo De code is lokaal al gecommit met je Firebase Realtime Database
echo en 105 restaurants (55 in Den Haag).
echo.
echo Bezig met pushen naar GitHub...
echo (Als GitHub om inloggen vraagt, verschijnt er een inlogschermpje)
echo.

git push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo ======================================================================
    echo SUCCES! De code staat op GitHub.
    echo.
    echo Ga nu naar je browser:
    echo   1. Open: https://github.com/Sayk138/Restaurant_shi/actions
    echo   2. De virtuele Mac is nu automatisch bezig de IPA te bouwen!
    echo   3. Na ~5 minuten kun je de "TasteMatch-iOS-IPA" direct downloaden.
    echo ======================================================================
) else (
    echo ======================================================================
    echo ER IS EEN FOUT OPGETREDEN BIJ HET PUSHEN.
    echo Controleer of de repository https://github.com/Sayk138/Restaurant_shi
    echo bestaat op GitHub en of je bent ingelogd.
    echo Tip: Je kunt ook GitHub Desktop openen en op "Publish" / "Push" klikken!
    echo ======================================================================
)

pause
