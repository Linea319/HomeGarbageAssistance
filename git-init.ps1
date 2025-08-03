# Git Repository Setup Script

Write-Host "==================================================" -ForegroundColor Green
Write-Host "    Git Repository Setup" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check if Git is installed
try {
    $gitVersion = git --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Git not found"
    }
    Write-Host "[SUCCESS] Git is installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if already a git repository
if (Test-Path ".git") {
    Write-Host "[INFO] Git repository already exists" -ForegroundColor Yellow
    $reinit = Read-Host "Do you want to reinitialize? (y/N)"
    if ($reinit -notmatch '^[Yy]') {
        Write-Host "[INFO] Skipping git initialization" -ForegroundColor Blue
        exit 0
    }
}

# Initialize git repository
Write-Host "[INFO] Initializing Git repository..." -ForegroundColor Blue
git init
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to initialize Git repository" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Add all files
Write-Host "[INFO] Adding files to Git..." -ForegroundColor Blue
git add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to add files" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Initial commit
Write-Host "[INFO] Creating initial commit..." -ForegroundColor Blue
git commit -m "Initial commit: HomeGarbageAssistance project setup

- Flask backend with SQLAlchemy and SQLite
- Vue.js frontend with TypeScript and Vite
- PowerShell and Batch startup scripts
- Complete project structure and documentation"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create initial commit" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[SUCCESS] Git repository initialized successfully!" -ForegroundColor Green
Write-Host

# Show status
Write-Host "Repository Status:" -ForegroundColor Cyan
git status --short
git log --oneline -1

Write-Host
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "1. Create a repository on GitHub/GitLab" -ForegroundColor White
Write-Host "2. Add remote origin:" -ForegroundColor White
Write-Host "   git remote add origin <repository-url>" -ForegroundColor Gray
Write-Host "3. Push to remote:" -ForegroundColor White
Write-Host "   git branch -M main" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Green

Read-Host "Press Enter to exit"
