# Home Garbage Assistance Frontend - PowerShell Start Script

Write-Host "==================================================" -ForegroundColor Green
Write-Host "  Home Garbage Assistance Frontend - PowerShell" -ForegroundColor Green  
Write-Host "==================================================" -ForegroundColor Green

# Parse command line arguments
$MODE = "development"
if ($args[0] -eq "build") { $MODE = "build" }
if ($args[0] -eq "preview") { $MODE = "preview" }

Write-Host "Mode: $MODE" -ForegroundColor Yellow
Write-Host

# Check Node.js installation
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Node.js not found"
    }
    Write-Host "[SUCCESS] Node.js is installed" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check npm installation
try {
    $npmVersion = npm --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "npm not found"
    }
    Write-Host "[SUCCESS] npm is available" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] npm is not installed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Install dependencies if node_modules doesn't exist
if (-not (Test-Path "node_modules")) {
    Write-Host "[INFO] Installing dependencies..." -ForegroundColor Blue
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "[SUCCESS] Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "[INFO] Dependencies already installed" -ForegroundColor Blue
}

# Display configuration
Write-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "- Mode: $MODE" -ForegroundColor White
Write-Host "- Node.js: $(node --version)" -ForegroundColor White
Write-Host "- npm: $(npm --version)" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host

# Execute based on mode
switch ($MODE) {
    "build" {
        Write-Host "[INFO] Building for production..." -ForegroundColor Blue
        npm run build
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Build failed" -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
        Write-Host "[SUCCESS] Build completed! Check ./dist folder" -ForegroundColor Green
    }
    "preview" {
        Write-Host "[INFO] Starting preview server..." -ForegroundColor Blue
        Write-Host "[INFO] Preview will be available at: http://localhost:3000" -ForegroundColor Yellow
        npm run preview
    }
    default {
        Write-Host "[INFO] Starting development server..." -ForegroundColor Blue
        Write-Host "[INFO] Frontend will be available at: http://localhost:5173" -ForegroundColor Yellow
        Write-Host "[INFO] Backend proxy: http://localhost:5100" -ForegroundColor Yellow
        Write-Host "[DEBUG] Running: npm run dev" -ForegroundColor Gray
        npm run dev
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to start development server" -ForegroundColor Red
            Write-Host "[DEBUG] Check if package.json has correct scripts" -ForegroundColor Gray
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
}

Write-Host
Write-Host "[INFO] Process completed" -ForegroundColor Blue
if ($MODE -ne "build") {
    Write-Host "[INFO] Server stopped" -ForegroundColor Blue
}
Read-Host "Press Enter to exit"
