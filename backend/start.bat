@echo off
chcp 65001 >nul
echo ==================================================
echo  Home Garbage Assistance Backend - Windows
echo ==================================================

REM Parse command line arguments
set "MODE=development"
if "%1"=="prod" set "MODE=production"
if "%1"=="production" set "MODE=production"

echo Mode: %MODE%
echo.

REM Check Python installation
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
    echo Please install Python 3.8+ and add it to PATH
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist "venv" (
    echo [INFO] Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
)

REM Activate virtual environment
echo [INFO] Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment
    pause
    exit /b 1
)

REM Upgrade pip
echo [INFO] Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo [INFO] Installing dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)

REM Set environment variables
echo [INFO] Setting environment variables...
set FLASK_ENV=%MODE%
set FLASK_APP=app.py
set PYTHONPATH=%CD%

REM Display configuration
echo.
echo ==================================================
echo Configuration:
echo - Environment: %MODE%
echo - Python: 
python --version
echo - Flask App: %FLASK_APP%
echo - Database: SQLite (garbage_assistant.db)
echo ==================================================
echo.

REM Start the application
if "%MODE%"=="production" (
    echo [INFO] Starting Flask application in PRODUCTION mode...
    echo [WARN] Debug mode is disabled
    python app.py
) else (
    echo [INFO] Starting Flask application in DEVELOPMENT mode...
    echo [INFO] Debug mode is enabled
    echo [INFO] API will be available at: http://localhost:5000
    python app.py
)

echo.
echo [INFO] Application stopped
pause
