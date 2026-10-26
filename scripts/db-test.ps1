param(
    [Parameter(Position = 0)]
    [ValidateSet('up','down','status','migrate','test','all','api','integration')]
    [string]$Action = 'status'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$composeFile = Join-Path $root 'infra/docker/compose.test.yml'
$envFile = Join-Path $root '.env.docker.test'
$composeArgs = @('compose', '-p', 'hbd-pg-test', '--env-file', $envFile, '-f', $composeFile)
$dbName = 'hbd_test'

function Assert-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker CLI not found. Start Docker Desktop / install Docker first.'
    }
    & docker info --format '{{.ServerVersion}}' *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Docker Engine is unavailable. Start Docker Desktop.' }
}

function Ensure-LocalEnv {
    if (-not (Test-Path -LiteralPath $envFile)) {
        $bytes = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        $password = ([BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
        @("HBD_PG_TEST_PASSWORD=$password", 'HBD_PG_TEST_PORT=55432') |
            Set-Content -LiteralPath $envFile -Encoding Ascii
        Write-Host '[SETUP] Created gitignored .env.docker.test with random local password (not shown).'
    }
    $lines = @(Get-Content -LiteralPath $envFile)
    if (-not ($lines | Where-Object { $_ -match '^HBD_PG_TEST_PASSWORD=[A-Za-z0-9_-]{20,}$' })) {
        throw '.env.docker.test has no valid random HBD_PG_TEST_PASSWORD. Edit it locally; do not commit it.'
    }
}

function Invoke-Compose {
    param([string[]]$Arguments)
    & docker @composeArgs @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed (exit $LASTEXITCODE)." }
}

function Invoke-Psql {
    param([string[]]$Arguments)
    & docker @composeArgs exec -T postgres psql -U postgres -d $dbName -X -q -v ON_ERROR_STOP=1 @Arguments
    if ($LASTEXITCODE -ne 0) { throw "PostgreSQL command failed (exit $LASTEXITCODE)." }
}

function Assert-Running {
    $containerId = (& docker @composeArgs ps -q postgres 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $containerId) {
        throw 'Test database is not running. Run: pnpm run db:test:up'
    }
}

function Start-TestDb {
    Write-Host '[DOCKER] Starting dedicated hbd-pg-test PostgreSQL 17 on 127.0.0.1:55432 ...'
    Invoke-Compose -Arguments @('up', '-d', '--wait', 'postgres')
    Write-Host '[OK] Test database healthy. Other containers and volumes unchanged.'
}

function Apply-Migrations {
    Assert-Running
    Write-Host '[MIGRATIONS] Applying canonical SQL into isolated local test DB ...'
    Invoke-Psql -Arguments @('-c', 'CREATE SCHEMA IF NOT EXISTS hbd_test_meta; CREATE TABLE IF NOT EXISTS hbd_test_meta.applied_migrations (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());')
    $files = @(Get-ChildItem -LiteralPath (Join-Path $root 'supabase/migrations') -Filter '*.sql' -File | Sort-Object Name)
    $applied = 0
    foreach ($file in $files) {
        if ($file.Name -notmatch '^[a-zA-Z0-9_.-]+$') { throw "Unsafe migration filename: $($file.Name)" }
        $count = (& docker @composeArgs exec -T postgres psql -U postgres -d $dbName -X -q -At -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM hbd_test_meta.applied_migrations WHERE name='$($file.Name)';")
        if ($LASTEXITCODE -ne 0) { throw 'Cannot check migration history.' }
        if ($count -eq '1') {
            Write-Host "  [SKIP] $($file.Name)"
            continue
        }
        Write-Host "  [APPLY] $($file.Name)"
        Invoke-Psql -Arguments @('-1', '-f', "/workspace/migrations/$($file.Name)", '-c', "INSERT INTO hbd_test_meta.applied_migrations(name) VALUES ('$($file.Name)');")
        $applied++
    }
    Write-Host "[OK] $($files.Count) migrations checked; $applied applied now."
}

function Invoke-SqlTests {
    Assert-Running
    $files = @(Get-ChildItem -LiteralPath (Join-Path $root 'supabase/tests/database') -Filter '*.sql' -File | Sort-Object Name)
    $passed = 0
    foreach ($file in $files) {
        if ($file.Name -notmatch '^[a-zA-Z0-9_.-]+$') { throw "Unsafe test filename: $($file.Name)" }
        Write-Host "  [TEST] $($file.Name)"
        Invoke-Psql -Arguments @('-f', "/workspace/tests/$($file.Name)")
        $passed++
    }
    Write-Host "[OK] PostgreSQL SQL files passed: $passed / $($files.Count)"
}

function Start-NativeApi {
    Assert-Running
    $line = @(Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^HBD_PG_TEST_PASSWORD=' } | Select-Object -First 1)[0]
    $password = $line.Substring('HBD_PG_TEST_PASSWORD='.Length)
    $portLine = @(Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^HBD_PG_TEST_PORT=' } | Select-Object -First 1)
    $dbPort = if ($portLine.Count -gt 0) { $portLine[0].Substring('HBD_PG_TEST_PORT='.Length) } else { '55432' }
    if ($dbPort -notmatch '^[0-9]{2,5}$') { throw 'Invalid local PostgreSQL port.' }
    $original = $env:DATABASE_URL
    try {
        $env:DATABASE_URL = "postgresql://postgres:$password@127.0.0.1:$dbPort/hbd_test?schema=public"
        Write-Host '[API] Fastify starts NATIVE via pnpm with isolated Docker PostgreSQL.'
        & pnpm --filter @happy-birthday/api dev
        if ($LASTEXITCODE -ne 0) { throw "Fastify exited with code $LASTEXITCODE" }
    }
    finally { $env:DATABASE_URL = $original }
}

function Invoke-ApiIntegrationTests {
    Assert-Running
    # Don't rely on DATABASE_URL, which can point to hosted Supabase on developer PCs.
    $line = @(Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^HBD_PG_TEST_PASSWORD=' } | Select-Object -First 1)[0]
    $password = $line.Substring('HBD_PG_TEST_PASSWORD='.Length)
    $portLine = @(Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^HBD_PG_TEST_PORT=' } | Select-Object -First 1)
    $dbPort = if ($portLine.Count -gt 0) { $portLine[0].Substring('HBD_PG_TEST_PORT='.Length) } else { '55432' }
    if ($dbPort -notmatch '^[0-9]{2,5}$') { throw 'Invalid local PostgreSQL port.' }
    $original = $env:HBD_TEST_DATABASE_URL
    try {
        $env:HBD_TEST_DATABASE_URL = "postgresql://postgres:$password@127.0.0.1:$dbPort/hbd_test"
        Write-Host '[INTEGRATION] Fastify + Prisma against isolated Docker PostgreSQL (read-only queries).'
        & pnpm --filter @happy-birthday/api test:integration
        if ($LASTEXITCODE -ne 0) { throw "API integration tests failed (exit $LASTEXITCODE)." }
    }
    finally { $env:HBD_TEST_DATABASE_URL = $original }
}

Assert-Docker
Ensure-LocalEnv
switch ($Action) {
    'up' { Start-TestDb }
    'down' {
        Write-Host '[DOCKER] Stopping ONLY hbd-pg-test (volume retained).'
        Invoke-Compose -Arguments @('down')
    }
    'status' { Invoke-Compose -Arguments @('ps') }
    'api' { Start-NativeApi }
    'migrate' { Apply-Migrations }
    'test' { Invoke-SqlTests }
    'integration' { Invoke-ApiIntegrationTests }
    'all' {
        Start-TestDb
        Apply-Migrations
        Invoke-SqlTests
        Invoke-ApiIntegrationTests
    }
}
