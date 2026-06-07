@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === Hermes ^<--^> Perplexity MCP Bridge v9.9.2 (Windows) ===
echo.

set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "DEBUG_PORT=9222"
set "SERVER_PORT=3456"
set "PROFILE_DIR=%USERPROFILE%\chrome-debug-profile"

if not exist "%PROJECT_DIR%\.venv\Scripts\python.exe" (
    echo [error] Python venv fehlt: "%PROJECT_DIR%\.venv\Scripts\python.exe"
    echo [error] Bitte erst Installation ausfuehren.
    pause
    exit /b 1
)

echo [cleanup] Beende alte Prozesse auf Port %SERVER_PORT% und %DEBUG_PORT% falls vorhanden ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($p in @(%SERVER_PORT%, %DEBUG_PORT%)) { Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Write-Host ('[cleanup] Stoppe PID ' + $_ + ' auf Port ' + $p); Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue } }" 

if not exist "%CHROME_PATH%" (
    echo [warn] Chrome nicht am Standardpfad gefunden:
    echo        %CHROME_PATH%
    echo [warn] Der Server faellt auf Playwright/Chromium zurueck.
) else (
    echo [chrome] Chrome gefunden: %CHROME_PATH%
    if not exist "%PROFILE_DIR%" mkdir "%PROFILE_DIR%"
    del /f /q "%PROFILE_DIR%\SingletonLock" "%PROFILE_DIR%\SingletonCookie" "%PROFILE_DIR%\SingletonSocket" >nul 2>nul

    echo [chrome] Starte Chrome mit Remote Debugging auf Port %DEBUG_PORT% ...
    start "Perplexity CDP Chrome" "%CHROME_PATH%" --remote-debugging-port=%DEBUG_PORT% --user-data-dir="%PROFILE_DIR%" --no-first-run --no-default-browser-check --disable-default-apps --window-size=1280,900 "https://www.perplexity.ai"

    echo [chrome] Warte bis Chrome-CDP bereit ist ...
    for /l %%I in (1,1,30) do (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 http://127.0.0.1:%DEBUG_PORT%/json/version; if ($r.StatusCode -eq 200) { exit 0 } } catch { exit 1 }" >nul 2>nul
        if !errorlevel! equ 0 goto cdp_ready
        timeout /t 1 /nobreak >nul
    )
    echo [warn] Chrome-CDP war nach 30 Sekunden nicht erreichbar; Server versucht Fallback.
    goto after_cdp_wait

    :cdp_ready
    echo [chrome] Chrome-CDP ist bereit.
)

:after_cdp_wait
echo.
echo [server] Starte FastAPI MCP Server auf http://localhost:%SERVER_PORT% ...
echo [server] Dashboard: http://localhost:%SERVER_PORT%/dashboard/
echo [server] Status:    http://localhost:%SERVER_PORT%/status
echo.

cd /d "%PROJECT_DIR%\server"
"%PROJECT_DIR%\.venv\Scripts\python.exe" -m uvicorn mcp_server:app --host 127.0.0.1 --port %SERVER_PORT%

endlocal
