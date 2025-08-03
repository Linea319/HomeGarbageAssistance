# Home Garbage Assistance - Full Stack PowerShell Service Manager

param(
    [string]$Command = "start",
    [string]$Mode = "development"
)

# Validate parameters
$validCommands = @("start", "stop", "restart", "status", "help")
$validModes = @("development", "production", "prod")

if ($Mode -eq "prod") { $Mode = "production" }

if ($Command -notin $validCommands) {
    Write-Host "[ERROR] Unknown command: $Command" -ForegroundColor Red
    Write-Host "Run 'start-all.ps1 help' for usage information" -ForegroundColor Yellow
    exit 1
}

# Show help
if ($Command -eq "help") {
    Write-Host "Home Garbage Assistance - Service Manager" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host
    Write-Host "Usage: .\start-all.ps1 [COMMAND] [MODE]" -ForegroundColor White
    Write-Host
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  start      Start both backend and frontend servers (default)" -ForegroundColor White
    Write-Host "  stop       Stop all running servers" -ForegroundColor White
    Write-Host "  restart    Restart all servers" -ForegroundColor White
    Write-Host "  status     Check server status" -ForegroundColor White
    Write-Host "  help       Show this help message" -ForegroundColor White
    Write-Host
    Write-Host "Modes (only for start/restart):" -ForegroundColor Cyan
    Write-Host "  development    Development mode (default)" -ForegroundColor White
    Write-Host "  production     Production mode" -ForegroundColor White
    Write-Host "  prod           Production mode (short form)" -ForegroundColor White
    Write-Host
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\start-all.ps1                     # Start in development mode" -ForegroundColor Gray
    Write-Host "  .\start-all.ps1 start production    # Start in production mode" -ForegroundColor Gray
    Write-Host "  .\start-all.ps1 stop                # Stop all servers" -ForegroundColor Gray
    Write-Host "  .\start-all.ps1 restart             # Restart in development mode" -ForegroundColor Gray
    Write-Host "  .\start-all.ps1 status              # Check server status" -ForegroundColor Gray
    Write-Host
    exit 0
}

Write-Host "==================================================" -ForegroundColor Green
Write-Host "    Home Garbage Assistance - Service Manager" -ForegroundColor Green
Write-Host "    PowerShell Edition" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Functions for port checking
function Test-Port {
    param([int]$Port)
    try {
        $listener = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
        return ($listener | Where-Object { $_.Port -eq $Port }) -ne $null
    }
    catch {
        return $false
    }
}

function Get-ProcessByPort {
    param([int]$Port)
    try {
        $netstat = netstat -ano 2>$null | Select-String ":$Port "
        if ($netstat) {
            foreach ($line in $netstat) {
                $parts = $line -split '\s+' | Where-Object { $_ -ne '' }
                if ($parts.Count -ge 5) {
                    $pid = $parts[-1]
                    if ($pid -match '^\d+$') {
                        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                        if ($process) {
                            return $process
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Host "[DEBUG] Error in Get-ProcessByPort: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
    return $null
}

function Stop-Services-Quiet {
    # Stop services without output
    $backendProcess = Get-ProcessByPort 5100
    if ($backendProcess) {
        try { Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue } catch { }
    }

    $frontendProcess = Get-ProcessByPort 5173
    if ($frontendProcess) {
        try { Stop-Process -Id $frontendProcess.Id -Force -ErrorAction SilentlyContinue } catch { }
    }

    Start-Sleep -Seconds 1
}

function Stop-Services {
    Write-Host "[INFO] Stopping Home Garbage Assistance servers..." -ForegroundColor Blue
    Write-Host

    # Stop backend
    Write-Host "[INFO] Stopping backend server..." -ForegroundColor Blue
    $backendProcess = Get-ProcessByPort 5100
    if ($backendProcess) {
        try {
            Stop-Process -Id $backendProcess.Id -Force
            Write-Host "[SUCCESS] Backend server stopped (PID: $($backendProcess.Id))" -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Failed to stop backend server" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[INFO] Backend server was not running" -ForegroundColor Yellow
    }

    # Stop frontend
    Write-Host "[INFO] Stopping frontend server..." -ForegroundColor Blue
    $frontendProcess = Get-ProcessByPort 5173
    if ($frontendProcess) {
        try {
            Stop-Process -Id $frontendProcess.Id -Force
            Write-Host "[SUCCESS] Frontend server stopped (PID: $($frontendProcess.Id))" -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Failed to stop frontend server" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[INFO] Frontend server was not running" -ForegroundColor Yellow
    }

    # Also try to kill by window title for additional cleanup
    #try {
    #    Get-Process | Where-Object { $_.MainWindowTitle -like "*HomeGarbageAssistance*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    #} catch {
    #    # Ignore errors
    #}

    Write-Host
    Write-Host "[SUCCESS] All servers stopped" -ForegroundColor Green
    
    # Don't use Read-Host for stop command as it can cause issues
    if ($Command -eq "stop") {
        Write-Host "[INFO] Stop operation completed" -ForegroundColor Blue
    }
    else {
        Read-Host "Press Enter to exit"
    }
}

function Restart-Services {
    Write-Host "[INFO] Restarting Home Garbage Assistance servers..." -ForegroundColor Blue
    Write-Host

    # Stop services first
    Stop-Services-Quiet

    # Wait a moment
    Write-Host "[INFO] Waiting before restart..." -ForegroundColor Blue
    Start-Sleep -Seconds 2

    # Start services
    Start-Services
}

function Check-Status {
    Write-Host "[INFO] Checking server status..." -ForegroundColor Blue
    Write-Host

    $backendRunning = Test-Port 5100
    $frontendRunning = Test-Port 5173

    Write-Host "Backend Server (port 5100):" -ForegroundColor Cyan
    if ($backendRunning) {
        $backendProcess = Get-ProcessByPort 5100
        Write-Host "  [RUNNING] Backend is responding" -ForegroundColor Green
        if ($backendProcess) {
            Write-Host "  Process ID: $($backendProcess.Id)" -ForegroundColor Gray
            Write-Host "  Process Name: $($backendProcess.ProcessName)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  [STOPPED] Backend is not running" -ForegroundColor Red
    }

    Write-Host
    Write-Host "Frontend Server (port 5173):" -ForegroundColor Cyan
    if ($frontendRunning) {
        $frontendProcess = Get-ProcessByPort 5173
        Write-Host "  [RUNNING] Frontend is responding" -ForegroundColor Green
        if ($frontendProcess) {
            Write-Host "  Process ID: $($frontendProcess.Id)" -ForegroundColor Gray
            Write-Host "  Process Name: $($frontendProcess.ProcessName)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  [STOPPED] Frontend is not running" -ForegroundColor Red
    }

    Write-Host
    if ($backendRunning -and $frontendRunning) {
        Write-Host "[SUCCESS] All services are running" -ForegroundColor Green
        Write-Host "  - Backend:  http://localhost:5100" -ForegroundColor White
        Write-Host "  - Frontend: http://localhost:5173" -ForegroundColor White
        Write-Host "  - Health:   http://localhost:5100/api/health" -ForegroundColor White
    }
    else {
        Write-Host "[INFO] Some services are not running" -ForegroundColor Yellow
        Write-Host "Use '.\start-all.ps1 start' to start services" -ForegroundColor White
    }

    Write-Host
    Read-Host "Press Enter to exit"
}

function Start-Services {
    Write-Host "Environment: $Mode" -ForegroundColor Yellow
    Write-Host

    # Check if services are already running
    $backendRunning = Test-Port 5100
    $frontendRunning = Test-Port 5173

    if ($backendRunning) {
        Write-Host "[WARNING] Backend server appears to be already running on port 5100" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -notmatch '^[Yy]') {
            Write-Host "[INFO] Startup cancelled" -ForegroundColor Blue
            exit 0
        }
    }

    if ($frontendRunning) {
        Write-Host "[WARNING] Frontend server appears to be already running on port 5173" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -notmatch '^[Yy]') {
            Write-Host "[INFO] Startup cancelled" -ForegroundColor Blue
            exit 0
        }
    }

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
        }
        else {
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
        }
        else {
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

    # Wait for backend to initialize
    Write-Host "[INFO] Waiting for backend to initialize..." -ForegroundColor Blue
    Start-Sleep -Seconds 5

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
    }
    catch {
        Write-Host "[WARNING] Could not open browser automatically" -ForegroundColor Yellow
        Write-Host "[INFO] Please open: http://localhost:5173" -ForegroundColor Blue
    }

    Write-Host
    Write-Host "[INFO] Application opened in browser!" -ForegroundColor Green
    Write-Host "[INFO] Close the server windows to stop the application." -ForegroundColor Yellow
    Write-Host "[INFO] Or use '.\start-all.ps1 stop' to stop all servers." -ForegroundColor Yellow
    Write-Host "[INFO] Backend PID: $($backendProcess.Id)" -ForegroundColor Gray
    Write-Host "[INFO] Frontend PID: $($frontendProcess.Id)" -ForegroundColor Gray

    Read-Host "Press Enter to exit this launcher (servers will continue running)"
}

# Execute command
switch ($Command.ToLower()) {
    "start" { Start-Services }
    "stop" { Stop-Services }
    "restart" { Restart-Services }
    "status" { Check-Status }
}