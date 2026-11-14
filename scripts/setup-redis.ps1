$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "`n[1/4] Checking Redis Stack..." -ForegroundColor Cyan
docker exec school-erp-redis redis-cli PING
if ($LASTEXITCODE -ne 0) { throw "Redis container is not running. Start it with: docker compose up -d" }

Write-Host "`n[2/4] Creating Python environment..." -ForegroundColor Cyan
if (-not (Test-Path ".\.venv\Scripts\python.exe")) { python -m venv .venv }
$python = ".\.venv\Scripts\python.exe"

Write-Host "`n[3/4] Installing Redis and embedding dependencies..." -ForegroundColor Cyan
& $python -m pip install -r .\redis\requirements.txt
if ($LASTEXITCODE -ne 0) { throw "Dependency installation failed." }

Write-Host "`n[4/4] Creating index and loading demonstration resources..." -ForegroundColor Cyan
& $python .\redis\manage_resources.py setup
if ($LASTEXITCODE -ne 0) { throw "Redis setup failed." }

Write-Host "`nRedis setup completed." -ForegroundColor Green
Write-Host 'Try: .\.venv\Scripts\python.exe .\redis\manage_resources.py search "attendance"'
