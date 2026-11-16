param(
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}

$Root = Split-Path -Parent $PSScriptRoot
$RunDir = Join-Path $Root '.run'
$LogDir = Join-Path $RunDir 'logs'
$PidDir = Join-Path $RunDir 'pids'
New-Item -ItemType Directory -Force -Path $LogDir, $PidDir | Out-Null

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
function Write-Err([string]$Message) { Write-Host "  [ERROR] $Message" -ForegroundColor Red }
function Fail([string]$Message) {
    Write-Err $Message
    Write-Host "`n启动失败。日志目录：$LogDir" -ForegroundColor Red
    exit 1
}

function Test-Port([int]$Port) {
    $conn = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
    if ($conn) { return $true }
    $lines = netstat -ano | Select-String "^\s*TCP\s+\S+:$Port\s+\S+\s+LISTENING"
    return [bool]$lines
}

function Get-PidOnPort([int]$Port) {
    $conn = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) { return [int]$conn.OwningProcess }
    $line = netstat -ano | Select-String "^\s*TCP\s+\S+:$Port\s+\S+\s+LISTENING\s+(\d+)" | Select-Object -First 1
    if ($line) { return [int]$line.Matches[0].Groups[1].Value }
    return 0
}

function Wait-Port([int]$Port, [int]$TimeoutSec) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-Port $Port) { return $true }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Wait-Http([string]$Url, [int]$TimeoutSec) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { return $true }
        } catch {
            if ($_.Exception.Response) { return $true }
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Test-DockerReady {
    try {
        & docker info 1>$null 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Start-DockerDesktop {
    if (Test-DockerReady) { return $true }

    $candidates = @(
        (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'),
        'G:\develop2\Docker\Docker Desktop.exe',
        'D:\develop2\Docker\Docker Desktop.exe',
        (Join-Path $env:LOCALAPPDATA 'Docker\Docker Desktop.exe')
    )
    $exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $exe) {
        Write-Err "未找到 Docker Desktop，请手动启动 Docker Desktop 后重试。"
        return $false
    }

    Write-Step "Docker Desktop 未运行，正在启动（首次可能需要 1-2 分钟）..."
    Start-Process -FilePath $exe | Out-Null
    $deadline = (Get-Date).AddSeconds(180)
    while ((Get-Date) -lt $deadline) {
        if (Test-DockerReady) {
            Write-Ok "Docker Desktop 已就绪"
            return $true
        }
        Start-Sleep -Seconds 3
    }
    Write-Err "Docker Desktop 启动超时（180 秒）。"
    return $false
}

function Ensure-Milvus {
    if (-not (Start-DockerDesktop)) { return $false }

    $status = & docker inspect -f '{{.State.Status}}' milvus-standalone 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "未找到 milvus-standalone 容器，请按 README 创建 Milvus standalone。"
        return $false
    }

    if ($status -ne 'running') {
        Write-Step "启动 Milvus 容器 ..."
        & docker start milvus-standalone 1>$null 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Milvus 容器启动失败。"
            return $false
        }
    }

    $deadline = (Get-Date).AddSeconds(120)
    while ((Get-Date) -lt $deadline) {
        $state = & docker inspect -f '{{.State.Status}}' milvus-standalone 2>$null
        $health = & docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' milvus-standalone 2>$null
        if ($health -eq 'healthy') {
            Write-Ok "Milvus 已就绪"
            return $true
        }
        if ($state -eq 'running' -and (Test-Port 19530)) {
            Write-Ok "Milvus 已运行（19530）"
            return $true
        }
        if ($state -eq 'exited') {
            Write-Err "Milvus 容器已退出（可能是上次停止不干净）。最近日志："
            & docker logs --tail 20 milvus-standalone 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            return $false
        }
        Start-Sleep -Seconds 2
    }
    Write-Err "Milvus 启动超时。最近日志："
    & docker logs --tail 20 milvus-standalone 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    return $false
}

function Start-BackgroundProcess {
    param(
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory,
        [string]$StdOut,
        [string]$StdErr
    )
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory `
        -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr -PassThru -WindowStyle Hidden
    Set-Content -Path (Join-Path $PidDir "$Name.pid") -Value $process.Id -Encoding ASCII
    return $process
}

function Show-Tail([string]$Path, [int]$Lines = 30) {
    if (Test-Path $Path) {
        Write-Host "    最近日志：$Path" -ForegroundColor DarkGray
        Get-Content $Path -Tail $Lines | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 智维 · 企业 IT 智能工单平台 - 一键启动" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ---------- 基础工具检查 ----------
Write-Step "检查基础环境"
if (-not (Get-Command java -ErrorAction SilentlyContinue)) { Fail "未找到 java，请安装 JDK 17 并加入 PATH。" }
Write-Ok "Java：$((Get-Command java).Source)"
if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) { Fail "未找到 npm.cmd，请安装 Node.js 并加入 PATH。" }
Write-Ok "npm：$((Get-Command npm.cmd).Source)"

# ---------- MySQL ----------
Write-Step "检查 MySQL（3306）"
if (-not (Test-Port 3306)) {
    $mysqlService = Get-Service -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'MySQL*' -and $_.Status -eq 'Stopped' } |
        Select-Object -First 1
    if ($mysqlService) {
        try {
            Start-Service $mysqlService.Name
            Write-Ok "已启动 MySQL 服务：$($mysqlService.Name)"
        } catch {
            Write-Warn "无法自动启动 MySQL 服务：$($_.Exception.Message)"
        }
    }
    if (-not (Wait-Port 3306 20)) { Fail "MySQL 3306 未监听，请先启动 MySQL。" }
}
Write-Ok "MySQL 已运行"

# ---------- Milvus ----------
Write-Step "检查 Milvus"
if (-not (Ensure-Milvus)) { Fail "Milvus 未就绪。" }

# ---------- Agent ----------
Write-Step "启动 AI Agent（8000）"
$agentDir = Join-Path $Root 'code\ticket-agent'
$python = Join-Path $agentDir '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) {
    Fail "未找到 Agent 虚拟环境：$python`n请按 README 创建 .venv 并安装依赖。"
}
if (Test-Port 8000) {
    $existing = Get-PidOnPort 8000
    if ($existing -gt 0) {
        Set-Content -Path (Join-Path $PidDir 'agent.pid') -Value $existing -Encoding ASCII
    }
    Write-Warn "Agent 端口 8000 已被占用（PID $existing），跳过启动。"
} else {
    $agentOut = Join-Path $LogDir 'agent.out.log'
    $agentErr = Join-Path $LogDir 'agent.err.log'
    Start-BackgroundProcess -Name 'agent' -FilePath $python `
        -Arguments @('-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', '8000') `
        -WorkingDirectory $agentDir -StdOut $agentOut -StdErr $agentErr | Out-Null
    if (-not (Wait-Http 'http://127.0.0.1:8000/' 60)) {
        Write-Err "Agent 启动失败。"
        Show-Tail $agentErr
        Show-Tail $agentOut
        Fail "请检查 Agent 日志：$agentOut / $agentErr"
    }
    Write-Ok "Agent 已启动：http://127.0.0.1:8000"
}

# ---------- 后端 ----------
Write-Step "启动后端（8080）"
$backendDir = Join-Path $Root 'code\ticket-backend'
$jar = Join-Path $backendDir 'target\zhiwei-ticket-backend-1.0.0.jar'
if (-not (Test-Path $jar)) {
    if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
        Fail "未找到后端 jar，且 Maven 不在 PATH。请先执行 mvn -DskipTests package。"
    }
    Write-Warn "未找到后端 jar，正在构建（mvn -DskipTests package）..."
    Push-Location $backendDir
    try { & mvn -DskipTests package } finally { Pop-Location }
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jar)) { Fail "Maven 构建失败，未生成 jar。" }
}
if (Test-Port 8080) {
    $existing = Get-PidOnPort 8080
    if ($existing -gt 0) {
        Set-Content -Path (Join-Path $PidDir 'backend.pid') -Value $existing -Encoding ASCII
    }
    Write-Warn "后端端口 8080 已被占用（PID $existing），跳过启动。"
} else {
    $backendOut = Join-Path $LogDir 'backend.out.log'
    $backendErr = Join-Path $LogDir 'backend.err.log'
    Start-BackgroundProcess -Name 'backend' -FilePath 'java' `
        -Arguments @('-jar', "`"$jar`"") -WorkingDirectory $backendDir `
        -StdOut $backendOut -StdErr $backendErr | Out-Null
    if (-not (Wait-Port 8080 90)) {
        Write-Err "后端启动失败。"
        Show-Tail $backendErr
        Show-Tail $backendOut
        Fail "请检查后端日志：$backendOut / $backendErr"
    }
    Write-Ok "后端已启动：http://127.0.0.1:8080/api"
}

# ---------- 前端 ----------
Write-Step "启动前端（5173）"
$frontDir = Join-Path $Root 'code\ticket-frontend'
if (-not (Test-Path (Join-Path $frontDir 'node_modules'))) {
    if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
        Fail "未找到 npm.cmd，请安装 Node.js 并加入 PATH。"
    }
    Write-Warn "未找到 node_modules，正在执行 npm install ..."
    Push-Location $frontDir
    try { & npm.cmd install } finally { Pop-Location }
    if ($LASTEXITCODE -ne 0) { Fail "npm install 失败。" }
}
if (Test-Port 5173) {
    $existing = Get-PidOnPort 5173
    if ($existing -gt 0) {
        Set-Content -Path (Join-Path $PidDir 'frontend.pid') -Value $existing -Encoding ASCII
    }
    Write-Warn "前端端口 5173 已被占用（PID $existing），跳过启动。"
} else {
    $frontLog = Join-Path $LogDir 'frontend.log'
    $cmdLine = "npm run dev > `"$frontLog`" 2>&1"
    $frontProcess = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $cmdLine `
        -WorkingDirectory $frontDir -PassThru -WindowStyle Hidden
    Set-Content -Path (Join-Path $PidDir 'frontend.pid') -Value $frontProcess.Id -Encoding ASCII
    if (-not (Wait-Http 'http://localhost:5173/' 60)) {
        Write-Err "前端启动失败。"
        Show-Tail $frontLog
        Fail "请检查前端日志：$frontLog"
    }
    Write-Ok "前端已启动：http://localhost:5173"
}

# ---------- 完成 ----------
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " 启动完成" -ForegroundColor Green
Write-Host " 前端：  http://localhost:5173"
Write-Host " 后端：  http://127.0.0.1:8080/api"
Write-Host " Agent： http://127.0.0.1:8000"
Write-Host " 日志：  $LogDir"
Write-Host " 停止：  双击 一键关闭.bat"
Write-Host " 测试账号：admin / employee / engineer，密码 123456"
Write-Host "============================================" -ForegroundColor Green

if (-not $NoBrowser) {
    Start-Process 'http://localhost:5173' | Out-Null
}
