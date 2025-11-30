@echo off
REM Windows batch script to test web version

echo 🍋 Testing Lemon Math Web Version
echo ==================================

cd web
if errorlevel 1 (
    echo ❌ web directory not found
    exit /b 1
)

echo Checking files...
if exist index.html (echo ✅ index.html exists) else (echo ❌ index.html missing)
if exist app.js (echo ✅ app.js exists) else (echo ❌ app.js missing)
if exist styles.css (echo ✅ styles.css exists) else (echo ❌ styles.css missing)

echo.
echo Starting test server on http://localhost:8000
echo Press Ctrl+C to stop
echo.

REM Try Python first
python --version >nul 2>&1
if errorlevel 1 (
    python3 --version >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Python not found. Install Python or use another HTTP server
        echo You can also open index.html directly in a browser
        pause
        exit /b 1
    ) else (
        python3 -m http.server 8000
    )
) else (
    python -m http.server 8000
)

