param(
  [switch]$KeepInfrastructure
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $root '.homie-api.pid'

if (Test-Path -LiteralPath $pidFile) {
  $processId = [int](Get-Content -LiteralPath $pidFile)
  $process = Get-CimInstance Win32_Process -Filter "ProcessId=$processId" -ErrorAction SilentlyContinue
  if ($process -and $process.Name -eq 'node.exe' -and $process.CommandLine -match 'src/server.js') {
    Stop-Process -Id $processId
  }
  Remove-Item -LiteralPath $pidFile
}

if (-not $KeepInfrastructure) {
  docker compose -f (Join-Path $root 'compose.yaml') down
}

Write-Host 'Homie local services stopped. PostgreSQL and Redis volumes were preserved.'
