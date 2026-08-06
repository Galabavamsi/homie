param(
  [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$api = Join-Path $root 'apps\api'
$pidFile = Join-Path $root '.homie-api.pid'
$stdout = Join-Path $api 'api-local.out.log'
$stderr = Join-Path $api 'api-local.err.log'

docker info *> $null
docker compose -f (Join-Path $root 'compose.yaml') up -d --wait

if (-not (Test-Path -LiteralPath (Join-Path $api '.env'))) {
  Copy-Item -LiteralPath (Join-Path $api '.env.example') -Destination (Join-Path $api '.env')
}

if (-not $SkipInstall -or -not (Test-Path -LiteralPath (Join-Path $api 'node_modules'))) {
  npm install --prefix $api
}

$alreadyRunning = $false
try {
  $health = Invoke-RestMethod 'http://127.0.0.1:4000/api/health' -TimeoutSec 2
  $alreadyRunning = $health.service -eq 'homie-api'
} catch {
  $alreadyRunning = $false
}

if (-not $alreadyRunning) {
  $node = (Get-Command node).Source
  $process = Start-Process `
    -FilePath $node `
    -ArgumentList 'src/server.js' `
    -WorkingDirectory $api `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr `
    -WindowStyle Hidden `
    -PassThru
  Set-Content -LiteralPath $pidFile -Value $process.Id
}

$deadline = (Get-Date).AddSeconds(30)
do {
  try {
    $health = Invoke-RestMethod 'http://127.0.0.1:4000/api/health' -TimeoutSec 2
    if ($health.ok) { break }
  } catch {
    Start-Sleep -Milliseconds 500
  }
} while ((Get-Date) -lt $deadline)

if (-not $health.ok) {
  throw "Homie API did not become healthy. Read $stderr"
}

Write-Host "Homie API ready: http://127.0.0.1:4000"
Write-Host "Persistence: $($health.persistence); Swiggy MCP: $($health.mcpMode)"
Write-Host "Run .\scripts\run-android.ps1 in another terminal."
