param(
  [int]$ApiPort = 7137,
  [string]$ApiVersion = "v1"
)

$ip = Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike "127.*" -and
    $_.IPAddress -notlike "169.254.*" -and
    $_.SkipAsSource -ne $true
  } |
  Select-Object -First 1 -ExpandProperty IPAddress

if (-not $ip) {
  Write-Error "Nao foi possivel detectar um IP local valido."
  exit 1
}

$apiBaseUrl = "https://$ip`:$ApiPort/api"

Write-Host "Executando Flutter em modo dev..."
Write-Host "API_BASE_URL=$apiBaseUrl"
Write-Host "API_VERSION=$ApiVersion"

flutter run `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=$apiBaseUrl `
  --dart-define=API_VERSION=$ApiVersion `
  --dart-define=ENABLE_NETWORK_LOGS=true
