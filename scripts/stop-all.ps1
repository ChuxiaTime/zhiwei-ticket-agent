$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}

$Root = Split-Path -Parent $PSScriptRoot
$RunDir = Join-Path $Root '.run'
$PidDir = Join-Path $RunDir 'pids'

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "  [WARN] $Message" -ForegroundColor Yellow }

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

function Stop-Tree([int]$ProcessId, [string]$Name) {
    if ($ProcessId -le 0) { return }
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $process) { return }
    Write-Host "  停止 $Name（PID $ProcessId）..." -ForegroundColor Gray
    & taskkill.exe /PID $ProcessId /T /F 1>$null 2>$null
    Start-Sleep -Milliseconds 500
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 智维 · 企业 IT 智能工单平台 - 一键关闭" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$stoppedAny = $false

# 优先按 PID 文件停止，避免误杀其他进程
Write-Step "停止前端 / 后端 / Agent"
$services = @(
    @{ Name = '前端'; File = 'frontend.pid' },
    @{ Name = '后端'; File = 'backend.pid' },
    @{ Name = 'Agent'; File = 'agent.pid' }
)
foreach ($service in $services) {
    $pidFile = Join-Path $PidDir $service.File
    if (Test-Path $pidFile) {
        $processId = 0
        $rawPid = Get-Content $pidFile -Raw -ErrorAction SilentlyContinue
        if ($rawPid -and [int]::TryParse($rawPid.Trim(), [ref]$processId)) {
            if ($processId -gt 0) {
                Stop-Tree $processId $service.Name
                $stoppedAny = $true
            }
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }
}

# PID 文件丢失时，按项目端口兜底
foreach ($port in 5173, 8080, 8000) {
    $processId = Get-PidOnPort $port
    if ($processId -gt 0) {
        Stop-Tree $processId "端口 $port 进程"
        $stoppedAny = $true
    }
}

# 停止 Milvus；MySQL 和 Docker Desktop 保持运行
Write-Step "停止 Milvus 容器"
$dockerReady = $false
try {
    & docker info 1>$null 2>$null
    $dockerReady = ($LASTEXITCODE -eq 0)
} catch {
    $dockerReady = $false
}
if ($dockerReady) {
    $status = & docker inspect -f '{{.State.Status}}' milvus-standalone 2>$null
    if ($LASTEXITCODE -eq 0 -and $status -eq 'running') {
        & docker stop --time 60 milvus-standalone 1>$null 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Milvus 已停止"
            $stoppedAny = $true
        } else {
            Write-Warn "Milvus 停止失败，请手动执行：docker stop milvus-standalone"
        }
    } else {
        Write-Ok "Milvus 未运行，无需停止"
    }
} else {
    Write-Warn "Docker 未运行，跳过 Milvus"
}

# 检查端口
Start-Sleep -Seconds 1
$stillListening = @()
foreach ($port in 5173, 8080, 8000) {
    if (Test-Port $port) { $stillListening += $port }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
if ($stillListening.Count -eq 0) {
    Write-Host " 已关闭前端 / 后端 / Agent" -ForegroundColor Green
} else {
    Write-Host " 以下端口仍被占用：$($stillListening -join ', ')" -ForegroundColor Yellow
    Write-Host " 可能是其他程序占用，请手动检查。" -ForegroundColor Yellow
}
Write-Host " MySQL 与 Docker Desktop 保持运行（避免影响其他项目）"
Write-Host "============================================" -ForegroundColor Green

if (-not $stoppedAny -and $stillListening.Count -eq 0) {
    Write-Host "`n项目当前没有在运行。" -ForegroundColor Gray
}
