# Home Garbage Assistance Backend - PowerShell Start Script

param(
    [string]$Mode = "development"
)

Write-Host "==================================================" -ForegroundColor Green
Write-Host "  Home Garbage Assistance Backend - PowerShell" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Validate mode parameter
if ($Mode -eq "prod") { $Mode = "production" }
if ($Mode -notin @("development", "production", "termux")) {
    Write-Host "[WARNING] Invalid mode '$Mode'. Using 'development'" -ForegroundColor Yellow
    $Mode = "development"
}

Write-Host "Mode: $Mode" -ForegroundColor Yellow
Write-Host

# Check Python installation
try {
    $pythonVersion = python --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
    Write-Host "[SUCCESS] Python is installed: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.8+ and add it to PATH" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if virtual environment exists
if (-not (Test-Path "venv")) {
    Write-Host "[INFO] Creating virtual environment..." -ForegroundColor Blue
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to create virtual environment" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "[SUCCESS] Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "[INFO] Virtual environment already exists" -ForegroundColor Blue
}

# Activate virtual environment
Write-Host "[INFO] Activating virtual environment..." -ForegroundColor Blue
try {
    & ".\venv\Scripts\Activate.ps1"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to activate virtual environment"
    }
    Write-Host "[SUCCESS] Virtual environment activated" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to activate virtual environment" -ForegroundColor Red
    Write-Host "[INFO] Trying alternative activation method..." -ForegroundColor Yellow
    try {
        & ".\venv\Scripts\activate.bat"
    } catch {
        Write-Host "[ERROR] Could not activate virtual environment" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Upgrade pip
Write-Host "[INFO] Upgrading pip..." -ForegroundColor Blue
python -m pip install --upgrade pip | Out-Null

# Install dependencies
Write-Host "[INFO] Installing dependencies..." -ForegroundColor Blue
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[SUCCESS] Dependencies installed successfully" -ForegroundColor Green

# Set environment variables
Write-Host "[INFO] Setting environment variables..." -ForegroundColor Blue
$env:FLASK_ENV = $Mode
$env:FLASK_APP = "app.py"
$env:PYTHONPATH = (Get-Location).Path

# Display configuration
Write-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "- Environment: $Mode" -ForegroundColor White
Write-Host "- Python: $(python --version)" -ForegroundColor White
Write-Host "- Flask App: $($env:FLASK_APP)" -ForegroundColor White
Write-Host "- Database: SQLite (garbage_assistant.db)" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Start the application
if ($Mode -eq "production") {
    Write-Host "[INFO] Starting Flask application in PRODUCTION mode..." -ForegroundColor Blue
    Write-Host "[WARN] Debug mode is disabled" -ForegroundColor Yellow
} else {
    Write-Host "[INFO] Starting Flask application in DEVELOPMENT mode..." -ForegroundColor Blue
    Write-Host "[INFO] Debug mode is enabled" -ForegroundColor Green
    Write-Host "[INFO] API will be available at: http://localhost:5100" -ForegroundColor Yellow
}

Write-Host
Write-Host "[INFO] Starting server... Press Ctrl+C to stop" -ForegroundColor Blue
Write-Host

try {
    python app.py
} catch {
    Write-Host "[ERROR] Application failed to start" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    Write-Host
    Write-Host "[INFO] Application stopped" -ForegroundColor Blue
    Read-Host "Press Enter to exit"
}
