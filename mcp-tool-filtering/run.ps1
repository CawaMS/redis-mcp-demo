# Redis MCP Tool Filtering Demo - Run Script for Windows
# PowerShell version

# Color functions
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Error-Custom { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Warning-Custom { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

Write-Host "Starting Redis MCP Tool Filtering Demo..." -ForegroundColor Cyan
Write-Host ""

# Check if virtual environment exists
if (-not (Test-Path "venv")) {
    Write-Error-Custom "Virtual environment not found"
    Write-Host ""
    Write-Host "Please run setup first:" -ForegroundColor Yellow
    Write-Host "  .\setup.ps1" -ForegroundColor Yellow
    exit 1
}

# Check if config.py exists
if (-not (Test-Path "config.py")) {
    Write-Error-Custom "config.py not found"
    Write-Host ""
    Write-Host "Please run setup first:" -ForegroundColor Yellow
    Write-Host "  .\setup.ps1" -ForegroundColor Yellow
    exit 1
}

# Activate virtual environment
Write-Info "Activating virtual environment..."
$activateScript = "venv\Scripts\Activate.ps1"

if (Test-Path $activateScript) {
    # Check execution policy
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        Write-Warning-Custom "PowerShell execution policy is Restricted"
        Write-Host ""
        Write-Host "Run this script with:" -ForegroundColor Yellow
        Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\run.ps1" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or change your execution policy:" -ForegroundColor Yellow
        Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        exit 1
    }
    
    & $activateScript
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to activate virtual environment"
        exit 1
    }
} else {
    Write-Error-Custom "Activation script not found: $activateScript"
    Write-Host ""
    Write-Host "Please run setup first:" -ForegroundColor Yellow
    Write-Host "  .\setup.ps1" -ForegroundColor Yellow
    exit 1
}

# Verify Python version in venv
try {
    $versionOutput = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>&1
    if ($versionOutput -match "(\d+)\.(\d+)") {
        $pythonMajor = [int]$matches[1]
        $pythonMinor = [int]$matches[2]
        $pythonVersion = "$pythonMajor.$pythonMinor"
        
        if ($pythonMajor -lt 3 -or ($pythonMajor -eq 3 -and $pythonMinor -lt 10)) {
            Write-Error-Custom "Python 3.10+ required (found: Python $pythonVersion)"
            Write-Host ""
            Write-Host "Your virtual environment was created with Python $pythonVersion" -ForegroundColor Yellow
            Write-Host "You need Python 3.10-3.13 for this demo." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Fix this by:" -ForegroundColor Yellow
            Write-Host "  1. Install Python 3.10-3.13 from https://python.org/" -ForegroundColor Yellow
            Write-Host "  2. Remove the old venv: Remove-Item -Recurse -Force venv" -ForegroundColor Yellow
            Write-Host "  3. Run setup again: .\setup.ps1" -ForegroundColor Yellow
            exit 1
        }
        
        if ($pythonMajor -eq 3 -and $pythonMinor -ge 14) {
            Write-Warning-Custom "Python $pythonVersion may have compatibility issues"
            Write-Host "Recommended: Python 3.10-3.13" -ForegroundColor Yellow
            Write-Host ""
        }
    }
} catch {
    Write-Warning-Custom "Could not verify Python version"
}

# Get port from config
try {
    $demoPort = python -c "from config import DEMO_CONFIG; print(DEMO_CONFIG['port'])" 2>$null
    if ([string]::IsNullOrEmpty($demoPort)) {
        $demoPort = "3001"
    }
} catch {
    $demoPort = "3001"
}

Write-Success "Environment ready"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Server will start on port $demoPort" -ForegroundColor White
Write-Host "  Visit: http://localhost:$demoPort" -ForegroundColor White
Write-Host "  Press Ctrl+C to stop" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start the application
python app.py
