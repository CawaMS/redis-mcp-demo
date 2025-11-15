# Redis MCP Tool Filtering Demo Setup Script for Windows
# PowerShell version

$ErrorActionPreference = "Stop"

# Color functions
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Error-Custom { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Warning-Custom { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Redis MCP Tool Filtering Demo Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to find Python installation
function Find-Python {
    $pythonCommands = @("python", "python3", "py")
    $validPython = $null
    
    foreach ($cmd in $pythonCommands) {
        try {
            $version = & $cmd --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $version -match "Python (\d+)\.(\d+)\.(\d+)") {
                $major = [int]$matches[1]
                $minor = [int]$matches[2]
                
                # Return the command and version info
                return @{
                    Command = $cmd
                    Major = $major
                    Minor = $minor
                    Version = "$major.$minor"
                    FullVersion = $matches[0]
                }
            }
        } catch {
            continue
        }
    }
    
    return $null
}

# Check if Python 3 is installed
Write-Info "Checking Python installation..."
$pythonInfo = Find-Python

if ($null -eq $pythonInfo) {
    Write-Error-Custom "Python 3 is not installed or not in PATH"
    Write-Host ""
    Write-Host "Install Python 3.10-3.13 from https://python.org/" -ForegroundColor Yellow
    Write-Host "Make sure to check 'Add Python to PATH' during installation" -ForegroundColor Yellow
    exit 1
}

$pythonCmd = $pythonInfo.Command
$pythonMajor = $pythonInfo.Major
$pythonMinor = $pythonInfo.Minor
$pythonVersion = $pythonInfo.Version

# Check Python version requirements
if ($pythonMajor -lt 3 -or ($pythonMajor -eq 3 -and $pythonMinor -lt 10)) {
    Write-Error-Custom "Python 3.10+ required (found: Python $pythonVersion)"
    Write-Host ""
    Write-Host "The transformers library requires Python 3.10+ syntax." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Current version: $pythonVersion" -ForegroundColor Yellow
    Write-Host "Recommended: 3.10-3.13" -ForegroundColor Yellow
    Write-Host "Download: https://python.org/" -ForegroundColor Yellow
    exit 1
}

# Warn if Python is 3.14+ (known issues with numpy)
if ($pythonMajor -eq 3 -and $pythonMinor -ge 14) {
    Write-Warning-Custom "Python $pythonVersion detected"
    Write-Host ""
    Write-Host "Python 3.14+ has known issues with numpy/torch wheels." -ForegroundColor Yellow
    Write-Host "Recommended: Python 3.10-3.13" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Continue anyway? (y/n)"
    if ($response -notmatch '^[Yy]$') {
        Write-Host "Setup cancelled"
        exit 1
    }
}

Write-Success "Python $pythonVersion found (using '$pythonCmd' command)"

# Check if config.py exists, if not create it from example
if (-not (Test-Path "config.py")) {
    Write-Error-Custom "config.py not found"
    if (Test-Path "config.py.example") {
        Write-Info "Creating config.py from template"
        Copy-Item "config.py.example" "config.py"
        Write-Host ""
        Write-Warning-Custom "You must edit config.py and replace STUB_VALUE entries:"
        Write-Host "  - _redis_endpoint: your Redis Cloud endpoint" -ForegroundColor Yellow
        Write-Host "  - _redis_password: your Redis password" -ForegroundColor Yellow
        Write-Host "  - _azure_openai_endpoint: your Azure OpenAI endpoint" -ForegroundColor Yellow
        Write-Host "  - _azure_openai_chat_deployment: your chat model deployment" -ForegroundColor Yellow
        Write-Host "  - _azure_openai_embedding_deployment: your embedding model deployment" -ForegroundColor Yellow
        Write-Host ""
        Write-Error-Custom "Setup cannot continue with STUB_VALUE placeholders"
        Write-Host "After updating config.py, run .\setup.ps1 again"
        exit 1
    } else {
        Write-Error-Custom "config.py.example not found"
        exit 1
    }
}

Write-Success "Configuration file found"

# Validate config.py doesn't contain STUB_VALUE
Write-Info "Validating configuration..."
$configContent = Get-Content "config.py" -Raw
if ($configContent -match "STUB_VALUE") {
    Write-Error-Custom "config.py still contains STUB_VALUE placeholders"
    Write-Host ""
    Write-Host "Please edit config.py and replace all STUB_VALUE entries:" -ForegroundColor Yellow
    Write-Host "  - _redis_endpoint: your Redis Cloud endpoint" -ForegroundColor Yellow
    Write-Host "  - _redis_password: your Redis password" -ForegroundColor Yellow
    Write-Host "  - _azure_openai_endpoint: your Azure OpenAI endpoint" -ForegroundColor Yellow
    Write-Host "  - _azure_openai_chat_deployment: your chat model deployment" -ForegroundColor Yellow
    Write-Host "  - _azure_openai_embedding_deployment: your embedding model deployment" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After updating config.py, run .\setup.ps1 again"
    exit 1
}
Write-Success "Configuration validated"

# Create virtual environment if it doesn't exist
$venvDir = "venv"
if (-not (Test-Path $venvDir)) {
    Write-Info "Creating virtual environment..."
    & $pythonCmd -m venv $venvDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to create virtual environment"
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  1. Ensure Python was installed with 'Add to PATH' option" -ForegroundColor Yellow
        Write-Host "  2. Try running: $pythonCmd -m pip install --upgrade pip" -ForegroundColor Yellow
        Write-Host "  3. Restart PowerShell and try again" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "Virtual environment created"
} else {
    Write-Success "Virtual environment already exists"
}

# Activate virtual environment
Write-Info "Activating virtual environment..."
$activateScript = Join-Path $venvDir "Scripts\Activate.ps1"

if (Test-Path $activateScript) {
    # Check execution policy
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        Write-Warning-Custom "PowerShell execution policy is Restricted"
        Write-Host ""
        Write-Host "To activate the virtual environment, run:" -ForegroundColor Yellow
        Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or run this script with:" -ForegroundColor Yellow
        Write-Host "  PowerShell -ExecutionPolicy Bypass -File .\setup.ps1" -ForegroundColor Yellow
        exit 1
    }
    
    & $activateScript
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to activate virtual environment"
        exit 1
    }
} else {
    Write-Error-Custom "Activation script not found at: $activateScript"
    exit 1
}

Write-Success "Virtual environment activated"

# Upgrade pip to avoid dependency resolution issues
Write-Info "Upgrading pip..."
python -m pip install --upgrade pip --quiet
Write-Success "pip upgraded"

# Install dependencies
Write-Host ""
Write-Info "Installing dependencies (5-10 min, ~500MB download)"
Write-Host ""

# Install dependencies with progress
python -m pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to install dependencies"
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Network connection problems" -ForegroundColor Yellow
    Write-Host "  - Insufficient disk space" -ForegroundColor Yellow
    Write-Host "  - Missing build tools (install Visual Studio Build Tools)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Try running manually:" -ForegroundColor Yellow
    Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    Write-Host "  python -m pip install -r requirements.txt" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Success "All dependencies installed successfully"

# Verify azure-identity installation
Write-Info "Verifying azure-identity installation..."
$importTest = python -c "from azure.identity import DefaultAzureCredential; from openai import AzureOpenAI" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "azure-identity and openai verified"
} else {
    Write-Error-Custom "azure-identity or openai import failed"
    Write-Host ""
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $importTest | Select-Object -First 5
    Write-Host ""
    if ($importTest -match "unsupported operand type") {
        Write-Error-Custom "Python version incompatibility"
        Write-Host ""
        Write-Host "Current: Python $pythonVersion" -ForegroundColor Yellow
        Write-Host "Required: Python 3.10-3.13" -ForegroundColor Yellow
        Write-Host "Download: https://python.org/" -ForegroundColor Yellow
    } else {
        Write-Host "Please ensure azure-identity and openai packages are installed correctly." -ForegroundColor Yellow
    }
    exit 1
}

# Configuration validation
Write-Host ""
Write-Info "Validating configuration..."

# Check if config has stub values
$stubCheck = python -c @"
from config import REDIS_CONFIG, AZURE_OPENAI_CONFIG
stub_count = 0
if 'STUB_VALUE' in str(REDIS_CONFIG.get('endpoint', '')): stub_count += 1
if 'STUB_VALUE' in str(AZURE_OPENAI_CONFIG.get('endpoint', '')): stub_count += 1
if 'STUB_VALUE' in str(AZURE_OPENAI_CONFIG.get('chat_deployment', '')): stub_count += 1
if 'STUB_VALUE' in str(AZURE_OPENAI_CONFIG.get('embedding_deployment', '')): stub_count += 1
print(stub_count)
"@ 2>$null

if ($stubCheck -ne "0") {
    Write-Warning-Custom "Configuration incomplete (STUB_VALUE found)"
    Write-Host ""
    Write-Host "Update config.py with actual credentials:" -ForegroundColor Yellow
    Write-Host "  - Redis: endpoint, username, password" -ForegroundColor Yellow
    Write-Host "  - Azure OpenAI: endpoint, chat_deployment, embedding_deployment" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Demo will start but may run in limited mode" -ForegroundColor Yellow
    Write-Host ""
}

# Extract config for display
try {
    $redisEndpoint = python -c "from config import REDIS_CONFIG; print(REDIS_CONFIG.get('endpoint', REDIS_CONFIG.get('host', 'unknown')))" 2>$null
    $demoPort = python -c "from config import DEMO_CONFIG; print(DEMO_CONFIG['port'])" 2>$null
} catch {
    $demoPort = "3001"
}

Write-Success "Configuration loaded"

# Test Redis connection (optional)
Write-Host ""
Write-Info "Testing Redis connection..."

if ([string]::IsNullOrEmpty($redisEndpoint) -or $redisEndpoint -eq "STUB_VALUE") {
    Write-Warning-Custom "Redis not configured - demo will run in limited mode"
} else {
    Write-Info "redis-cli not available on Windows - skipping connection test"
    Write-Info "Connection will be tested when the application starts"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting server on port $demoPort" -ForegroundColor Green
Write-Host "URL: http://localhost:$demoPort" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start the application
python app.py
