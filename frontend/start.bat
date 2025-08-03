@echo off
chcp 65001 >nul

REM Check if running in PowerShell
if defined PSModulePath (
    echo [WARNING] This script is designed for Command Prompt (cmd.exe)
    echo [INFO] For PowerShell, use: start.ps1 or start-wrapper.ps1
    echo [INFO] Continuing with cmd compatibility mode...
    echo.
)

echo ==================================================
echo  Home Garbage Assistance Frontend - Windows
echo ==================================================

REM Parse command line arguments
set "MODE=development"
if "%1"=="build" set "MODE=build"
if "%1"=="preview" set "MODE=preview"

echo Mode: %MODE%
echo.

REM Check Node.js installation
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check npm installation
npm --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm is not installed
    pause
    exit /b 1
)

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo [INFO] Installing dependencies...
    npm install
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
    echo [SUCCESS] Dependencies installed successfully
) else (
    echo [INFO] Dependencies already installed
)

REM Display configuration
echo.
echo ==================================================
echo Configuration:
echo - Mode: %MODE%
echo - Node.js: 
node --version
echo - npm: 
npm --version
echo ==================================================
echo.

REM Execute based on mode
if "%MODE%"=="build" (
    echo [INFO] Building for production...
    npm run build
    if errorlevel 1 (
        echo [ERROR] Build failed
        pause
        exit /b 1
    )
    echo [SUCCESS] Build completed! Check ./dist folder
) else (
    if "%MODE%"=="preview" (
        echo [INFO] Starting preview server...
        echo [INFO] Preview will be available at: http://localhost:3000
        npm run preview
    ) else (
        echo [INFO] Starting development server...
        echo [INFO] Frontend will be available at: http://localhost:5173
        echo [INFO] Backend proxy: http://localhost:5100
        echo [DEBUG] Running: npm run dev
        npm run dev
        if errorlevel 1 (
            echo [ERROR] Failed to start development server
            echo [DEBUG] Check if package.json has correct scripts
            pause
            exit /b 1
        )
    )
)

echo.
echo [INFO] Process completed
if not "%MODE%"=="build" (
    echo [INFO] Server stopped
)
pause
