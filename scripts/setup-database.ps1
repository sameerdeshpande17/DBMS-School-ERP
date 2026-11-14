[CmdletBinding()]
param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 3307,
    [string]$Database = "school_erp",
    [string]$MySqlExe = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $MySqlExe)) { throw "MySQL client not found: $MySqlExe" }
$repoRoot = Split-Path -Parent $PSScriptRoot
$sqlFiles = @("database/schema.sql","database/seed.sql","database/functions.sql","database/procedures.sql","database/triggers.sql","database/views.sql","database/queries.sql","database/tests.sql")
foreach ($relativePath in $sqlFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath))) { throw "Required SQL file missing: $relativePath" }
}
$tempSql = Join-Path ([System.IO.Path]::GetTempPath()) ("school-erp-setup-" + [guid]::NewGuid().ToString("N") + ".sql")
try {
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine("CREATE DATABASE IF NOT EXISTS $Database CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;")
    [void]$builder.AppendLine("USE $Database;")
    foreach ($relativePath in $sqlFiles) {
        [void]$builder.AppendLine("")
        [void]$builder.AppendLine("-- ===== $relativePath =====")
        [void]$builder.AppendLine([System.IO.File]::ReadAllText((Join-Path $repoRoot $relativePath)))
    }
    [System.IO.File]::WriteAllText($tempSql, $builder.ToString(), [System.Text.Encoding]::UTF8)
    Write-Host "Running School ERP SQL setup on $HostName port $Port..." -ForegroundColor Cyan
    Write-Host "Enter the MySQL root password when prompted."
    Get-Content -LiteralPath $tempSql -Raw | & $MySqlExe --default-character-set=utf8mb4 --host=$HostName --port=$Port --user=root --password
    if ($LASTEXITCODE -ne 0) { throw "MySQL setup failed with exit code $LASTEXITCODE. Fix the reported SQL error and rerun." }
    Write-Host "Database setup completed successfully." -ForegroundColor Green
    Write-Host "database/roles.sql was not run because it contains a placeholder password. Review and run it separately if needed."
}
finally {
    if (Test-Path -LiteralPath $tempSql) { Remove-Item -LiteralPath $tempSql -Force }
}
