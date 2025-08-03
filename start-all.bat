@echo off
chcp 65001 >nul
echo ==================================================
echo     Home Garbage Assistance - Full Stack
echo ==================================================

set "MODE=development"
if "%1"=="prod" set "MODE=production"

echo Environment: %MODE%
echo.

REM Start backend in new window
echo [INFO] Starting Backend Server...
start "Backend Server" /D "%~dp0backend" cmd /k "start.bat %MODE%"

REM Wait a moment for backend to start
timeout /t 3 /nobreak >nul

REM Start frontend in new window  
echo [INFO] Starting Frontend Server...
start "Frontend Server" /D "%~dp0frontend" cmd /k "start.bat dev"

echo.
echo ==================================================
echo  Servers are starting in separate windows:
echo  - Backend:  http://localhost:5100
echo  - Frontend: http://localhost:5173
echo ==================================================
echo.
echo Press any key to open the application in browser...
pause >nul

REM Open browser
start http://localhost:5173

echo.
echo Application opened in browser!
echo Close the server windows to stop the application.
pause
