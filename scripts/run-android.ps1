$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root 'apps\mobile'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk'
$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_HOME = $sdk

Push-Location $mobile
try {
  flutter pub get
  $devices = flutter devices --machine | ConvertFrom-Json
  $android = $devices | Where-Object { $_.targetPlatform -like 'android-*' } | Select-Object -First 1

  if (-not $android) {
    $emulators = flutter emulators --machine | ConvertFrom-Json
    $emulator = $emulators | Where-Object { $_.id -eq 'fable_smoke' } | Select-Object -First 1
    if (-not $emulator) {
      $emulator = $emulators | Select-Object -First 1
    }
    if (-not $emulator) { throw 'No Android emulator is configured.' }
    flutter emulators --launch $emulator.id

    $deadline = (Get-Date).AddSeconds(90)
    do {
      Start-Sleep -Seconds 2
      $devices = flutter devices --machine | ConvertFrom-Json
      $android = $devices | Where-Object { $_.targetPlatform -like 'android-*' } | Select-Object -First 1
    } while (-not $android -and (Get-Date) -lt $deadline)
  }

  if (-not $android) { throw 'Android emulator did not become ready.' }
  flutter run -d $android.id --debug
} finally {
  Pop-Location
}
