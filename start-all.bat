@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

REM Parse command line arguments
set "COMMAND=%1"
set "MODE=%2"

REM Default values
if "%COMMAND%"=="" set "COMMAND=start"
if "%MODE%"=="" set "MODE=development"
if "%MODE%"=="prod" set "MODE=production"

REM Display help if requested
if /i "%COMMAND%"=="help" goto :show_help
if /i "%COMMAND%"=="-h" goto :show_help
if /i "%COMMAND%"=="--help" goto :show_help

echo ==================================================
echo     Home Garbage Assistance - Service Manager
echo ==================================================

REM Execute command
if /i "%COMMAND%"=="start" goto :start_services
if /i "%COMMAND%"=="stop" goto :stop_services
if /i "%COMMAND%"=="restart" goto :restart_services
if /i "%COMMAND%"=="status" goto :check_status

echo [ERROR] Unknown command: %COMMAND%
echo Run 'start-all.bat help' for usage information
pause
exit /b 1

:show_help
echo.
echo Usage: start-all.bat [COMMAND] [MODE]
echo.
echo Commands:
echo   start      Start both backend and frontend servers (default)
echo   stop       Stop all running servers
echo   restart    Restart all servers
echo   status     Check server status
echo   help       Show this help message
echo.
echo Modes (only for start/restart):
echo   development    Development mode (default)
echo   prod           Production mode
echo.
echo Examples:
echo   start-all.bat                    # Start in development mode
echo   start-all.bat start prod         # Start in production mode
echo   start-all.bat stop               # Stop all servers
echo   start-all.bat restart            # Restart in development mode
echo   start-all.bat status             # Check server status
echo.
pause
exit /b 0

:start_services
echo Environment: %MODE%
echo.

REM Check if services are already running
call :check_ports_quiet
if %backend_running%==1 (
    echo [WARNING] Backend server appears to be already running on port 5100
    set /p "continue=Continue anyway? (y/N): "
    if /i not "!continue!"=="y" (
        echo [INFO] Startup cancelled
        pause
        exit /b 0
    )
)
if %frontend_running%==1 (
    echo [WARNING] Frontend server appears to be already running on port 5173
    set /p "continue=Continue anyway? (y/N): "
    if /i not "!continue!"=="y" (
        echo [INFO] Startup cancelled
        pause
        exit /b 0
    )
)

REM Start backend in new window
echo [INFO] Starting Backend Server...
start "HomeGarbageAssistance-Backend" /D "%~dp0backend" cmd /k "start.bat %MODE%"

REM Wait a moment for backend to start
echo [INFO] Waiting for backend to initialize...
timeout /t 5 /nobreak >nul

REM Start frontend in new window  
echo [INFO] Starting Frontend Server...
start "HomeGarbageAssistance-Frontend" /D "%~dp0frontend" cmd /k "start.bat dev"

REM Wait for frontend to initialize
echo [INFO] Waiting for frontend to initialize...
timeout /t 3 /nobreak >nul

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
echo [SUCCESS] Application opened in browser!
echo [INFO] Close the server windows to stop the application.
echo [INFO] Or use 'start-all.bat stop' to stop all servers.
pause
exit /b 0

:stop_services
echo [INFO] Stopping Home Garbage Assistance servers...
echo.

REM Kill processes by window title
echo [INFO] Stopping backend server...
taskkill /FI "WINDOWTITLE eq HomeGarbageAssistance-Backend*" /F /T >nul 2>&1
if %errorlevel%==0 (
    echo [SUCCESS] Backend server stopped
) else (
    echo [INFO] Backend server was not running
)

echo [INFO] Stopping frontend server...
taskkill /FI "WINDOWTITLE eq HomeGarbageAssistance-Frontend*" /F /T >nul 2>&1
if %errorlevel%==0 (
    echo [SUCCESS] Frontend server stopped
) else (
    echo [INFO] Frontend server was not running
)

REM Also try to kill by port (more reliable)
echo [INFO] Ensuring ports are free...
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :5100') do taskkill /PID %%i /F >nul 2>&1
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :5173') do taskkill /PID %%i /F >nul 2>&1

echo.
echo [SUCCESS] All servers stopped
pause
exit /b 0

:restart_services
echo [INFO] Restarting Home Garbage Assistance servers...
echo.

REM Stop services first
call :stop_services_quiet

REM Wait a moment
echo [INFO] Waiting before restart...
timeout /t 2 /nobreak >nul

REM Start services
goto :start_services

:check_status
echo [INFO] Checking server status...
echo.

call :check_ports_quiet

echo Backend Server (port 5100):
if %backend_running%==1 (
    echo   [RUNNING] Backend is responding
    for /f "tokens=5" %%i in ('netstat -ano ^| findstr :5100 ^| findstr LISTENING') do (
        echo   Process ID: %%i
    )
) else (
    echo   [STOPPED] Backend is not running
)

echo.
echo Frontend Server (port 5173):
if %frontend_running%==1 (
    echo   [RUNNING] Frontend is responding  
    for /f "tokens=5" %%i in ('netstat -ano ^| findstr :5173 ^| findstr LISTENING') do (
        echo   Process ID: %%i
    )
) else (
    echo   [STOPPED] Frontend is not running
)

echo.
if %backend_running%==1 if %frontend_running%==1 (
    echo [SUCCESS] All services are running
    echo   - Backend:  http://localhost:5100
    echo   - Frontend: http://localhost:5173
    echo   - Health:   http://localhost:5100/api/health
) else (
    echo [INFO] Some services are not running
    echo Use 'start-all.bat start' to start services
)

echo.
pause
exit /b 0

:check_ports_quiet
set backend_running=0
set frontend_running=0

REM Check if ports are in use
netstat -ano | findstr :5100 | findstr LISTENING >nul 2>&1
if %errorlevel%==0 set backend_running=1

netstat -ano | findstr :5173 | findstr LISTENING >nul 2>&1
if %errorlevel%==0 set frontend_running=1
exit /b 0

:stop_services_quiet
REM Kill processes by window title (quiet mode)
taskkill /FI "WINDOWTITLE eq HomeGarbageAssistance-Backend*" /F /T >nul 2>&1
taskkill /FI "WINDOWTITLE eq HomeGarbageAssistance-Frontend*" /F /T >nul 2>&1

REM Also try to kill by port
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :5100') do taskkill /PID %%i /F >nul 2>&1
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :5173') do taskkill /PID %%i /F >nul 2>&1

timeout /t 1 /nobreak >nul
exit /b 0
