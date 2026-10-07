$ErrorActionPreference = "Stop"

$RepositoryPath = Split-Path -Parent $PSScriptRoot
$EnvironmentFile = Join-Path $RepositoryPath ".env"

Push-Location $RepositoryPath
try {
    if (Test-Path $EnvironmentFile) {
        foreach ($Line in Get-Content $EnvironmentFile) {
            if ([string]::IsNullOrWhiteSpace($Line) -or $Line.TrimStart().StartsWith("#")) {
                continue
            }

            $Parts = $Line.Split("=", 2)
            if ($Parts.Count -eq 2 -and -not [string]::IsNullOrWhiteSpace($Parts[1])) {
                [Environment]::SetEnvironmentVariable($Parts[0], $Parts[1], "Process")
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($env:VAULT_DEMO_ROOT_TOKEN)) {
        $env:VAULT_DEMO_ROOT_TOKEN = [Guid]::NewGuid().ToString("N")
    }
    if ([string]::IsNullOrWhiteSpace($env:DEMO_POSTGRES_PASSWORD)) {
        $env:DEMO_POSTGRES_PASSWORD = [Guid]::NewGuid().ToString("N")
    }

    @(
        "VAULT_DEMO_ROOT_TOKEN=$env:VAULT_DEMO_ROOT_TOKEN"
        "DEMO_POSTGRES_PASSWORD=$env:DEMO_POSTGRES_PASSWORD"
    ) | Set-Content -Path $EnvironmentFile -Encoding ascii

    docker compose up -d --wait --remove-orphans
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose up завершился с кодом $LASTEXITCODE."
    }

    Write-Host "Запущено три контейнера: PostgreSQL, Vault и Vault Proxy."
    Write-Host "PostgreSQL: 127.0.0.1:15432"
    Write-Host "Vault:      http://127.0.0.1:8200"
    Write-Host "Proxy:      http://127.0.0.1:8100"
    Write-Host "Vault UI token: $env:VAULT_DEMO_ROOT_TOKEN"
}
finally {
    Pop-Location
}
