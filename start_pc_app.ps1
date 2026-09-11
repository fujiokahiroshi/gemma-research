param(
    [int]$Port = 8788,
    [switch]$KeepExisting,
    [switch]$SkipModelDownload
)

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$submoduleDir = Join-Path $projectDir 'ai-nas-manager'
$appDir = Join-Path $submoduleDir 'ai-nas-manager'
$appStart = Join-Path $appDir 'start_pc_app.ps1'

if (-not (Test-Path -LiteralPath $appStart)) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        throw 'Git is required. Install Git for Windows and retry.'
    }
    Write-Host 'Initializing the ai-nas-manager submodule...'
    & $git.Source -C $projectDir submodule update --init --recursive
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $appStart)) {
        throw 'The ai-nas-manager submodule could not be initialized.'
    }
}

$uv = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uv) {
    throw 'uv is required. Install it from https://docs.astral.sh/uv/getting-started/installation/ and retry.'
}

$modelDir = Join-Path $appDir 'models'
$modelPath = Join-Path $modelDir 'yolox_tiny.onnx'
if (-not $SkipModelDownload -and -not (Test-Path -LiteralPath $modelPath)) {
    $modelUrl = 'https://github.com/Megvii-BaseDetection/YOLOX/releases/download/0.1.1rc0/yolox_tiny.onnx'
    $expectedHash = '427CC366D34E27FF7A03E2899B5E3671425C262EA2291F88BB942BC1CC70B0F7'
    [void](New-Item -ItemType Directory -Path $modelDir -Force)
    $temporary = Join-Path $modelDir '.yolox_tiny.onnx.download'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Host 'Downloading the verified YOLOX-Tiny model...'
        Invoke-WebRequest -Uri $modelUrl -OutFile $temporary -UseBasicParsing
        $actualHash = (Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash
        if ($actualHash -ne $expectedHash) {
            throw 'The YOLOX-Tiny model checksum did not match.'
        }
        Move-Item -LiteralPath $temporary -Destination $modelPath
    }
    finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}

try {
    $models = Invoke-RestMethod -Uri 'http://127.0.0.1:1234/v1/models' -TimeoutSec 2
    Write-Host ('LM Studio is available with ' + @($models.data).Count + ' loaded model(s).')
}
catch {
    Write-Warning 'LM Studio is not responding at http://127.0.0.1:1234. The App will start, but Gemma analysis requires LM Studio.'
}

$startArguments = @('-Port', $Port)
if ($KeepExisting) {
    $startArguments += '-KeepExisting'
}
& $appStart @startArguments
