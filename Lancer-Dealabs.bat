@echo off
cd /d "%~dp0"

if not exist "Interface_graphique.ps1" (
    echo Erreur : Interface_graphique.ps1 est introuvable dans ce dossier.
    echo Dossier courant : %CD%
    echo.
    echo Fichiers PowerShell disponibles :
    dir /b *.ps1
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CD%\Interface_graphique.ps1"

if errorlevel 1 (
    echo.
    echo L'interface s'est arretee avec une erreur.
    pause
)
