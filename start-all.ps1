# Home Garbage Assistance - Full Stack PowerShell Start Script

param(
    [string]$Mode = "development"
)

Write-Host "==================================================" -ForegroundColor Green
Write-Host "    Home Garbage Assistance - Full Stack" -ForegroundColor Green
Write-Host "    PowerShell Edition" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Validate mode parameter
if ($Mode -eq "prod") { $Mode = "production" }

Write-Host "Environment: $Mode" -ForegroundColor Yellow
Write-Host

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to start backend
function Start-Backend {
    Write-Host "[INFO] Starting Backend Server..." -ForegroundColor Blue
    
    $backendPath = Join-Path $scriptDir "backend"
    $backendScript = Join-Path $backendPath "start.ps1"
    
    if (-not (Test-Path $backendScript)) {
        Write-Host "[ERROR] Backend PowerShell script not found: $backendScript" -ForegroundColor Red
        return $false
    }
    
    # Start backend in new PowerShell window
    $backendJob = Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$backendScript`"", $Mode `
        -WorkingDirectory $backendPath `
        -WindowStyle Normal `
        -PassThru
    
    if ($backendJob) {
        Write-Host "[SUCCESS] Backend server started (PID: $($backendJob.Id))" -ForegroundColor Green
        return $backendJob
    } else {
        Write-Host "[ERROR] Failed to start backend server" -ForegroundColor Red
        return $false
    }
}

# Function to start frontend
function Start-Frontend {
    Write-Host "[INFO] Starting Frontend Server..." -ForegroundColor Blue
    
    $frontendPath = Join-Path $scriptDir "frontend"
    $frontendScript = Join-Path $frontendPath "start.ps1"
    
    if (-not (Test-Path $frontendScript)) {
        Write-Host "[ERROR] Frontend PowerShell script not found: $frontendScript" -ForegroundColor Red
        return $false
    }
    
    # Start frontend in new PowerShell window
    $frontendJob = Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$frontendScript`"", "development" `
        -WorkingDirectory $frontendPath `
        -WindowStyle Normal `
        -PassThru
    
    if ($frontendJob) {
        Write-Host "[SUCCESS] Frontend server started (PID: $($frontendJob.Id))" -ForegroundColor Green
        return $frontendJob
    } else {
        Write-Host "[ERROR] Failed to start frontend server" -ForegroundColor Red
        return $false
    }
}

# Start backend
$backendProcess = Start-Backend
if (-not $backendProcess) {
    Write-Host "[ERROR] Cannot continue without backend server" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Wait a moment for backend to initialize
Write-Host "[INFO] Waiting for backend to initialize..." -ForegroundColor Blue
Start-Sleep -Seconds 3

# Start frontend
$frontendProcess = Start-Frontend
if (-not $frontendProcess) {
    Write-Host "[ERROR] Cannot start frontend server" -ForegroundColor Red
    Write-Host "[INFO] Backend server is still running" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Wait for frontend to initialize
Write-Host "[INFO] Waiting for frontend to initialize..." -ForegroundColor Blue
Start-Sleep -Seconds 3

Write-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Servers are running in separate windows:" -ForegroundColor Cyan
Write-Host "  - Backend:  http://localhost:5100" -ForegroundColor White
Write-Host "  - Frontend: http://localhost:5173" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

Write-Host "[SUCCESS] Application is ready!" -ForegroundColor Green
Write-Host "[INFO] Opening browser..." -ForegroundColor Blue

# Open browser
try {
    Start-Process "http://localhost:5173"
    Write-Host "[SUCCESS] Browser opened successfully" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not open browser automatically" -ForegroundColor Yellow
    Write-Host "[INFO] Please open: http://localhost:5173" -ForegroundColor Blue
}

Write-Host
Write-Host "[INFO] Application opened in browser!" -ForegroundColor Green
Write-Host "[INFO] Close the server windows to stop the application." -ForegroundColor Yellow
Write-Host "[INFO] Backend PID: $($backendProcess.Id)" -ForegroundColor Gray
Write-Host "[INFO] Frontend PID: $($frontendProcess.Id)" -ForegroundColor Gray

Read-Host "Press Enter to exit this launcher (servers will continue running)"
