param(
    [ValidateSet('auto', 'opencode', 'codex', 'claude')]
    [string]$Runtime = 'auto',
    [string]$EmbeddedRoot,
    [switch]$Verify,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$userProfile = [Environment]::GetFolderPath('UserProfile')

function Test-Runtime {
    param([string]$Name)
    switch ($Name) {
        'opencode' { return (Test-Path -LiteralPath (Join-Path $userProfile '.config\opencode')) }
        'codex' { return ((Test-Path -LiteralPath (Join-Path $userProfile '.codex')) -or [bool]$env:CODEX_HOME) }
        'claude' { return (Test-Path -LiteralPath (Join-Path $userProfile '.claude')) }
    }
    return $false
}

if ($Runtime -eq 'auto') {
    $detected = @(@('opencode', 'codex', 'claude') | Where-Object { Test-Runtime $_ })
    if ($detected.Count -eq 0) {
        Write-Output '未检测到 OpenCode / Codex / Claude 的配置目录。'
        Write-Output '请手动指定：.\bootstrap.ps1 -Runtime opencode -EmbeddedRoot <嵌入式工程父目录>'
        exit 1
    }
    $Runtime = $detected[0]
    Write-Output "Detected runtime: $Runtime"
    if ($detected.Count -gt 1) {
        $others = @($detected | Select-Object -Skip 1) -join ', '
        Write-Output "其他已检测到的运行时：$others。如需装到其中一个，用 -Runtime 指定。"
    }
}

if (-not $EmbeddedRoot) {
    Write-Output '未提供 -EmbeddedRoot：嵌入式规则将写入全局 instructions，对所有目录生效。'
    Write-Output "只想限定到某个工程树时：.\bootstrap.ps1 -Runtime $Runtime -EmbeddedRoot '<工程根>' -Force"
}

$install = Join-Path $PSScriptRoot 'install.ps1'
if (-not (Test-Path -LiteralPath $install)) { throw "Missing install script: $install" }

$params = @{ Full = $true; Runtime = $Runtime }
if ($EmbeddedRoot) { $params.EmbeddedRoot = $EmbeddedRoot }
if ($Verify) { $params.Verify = $true }
elseif ($Force) { $params.Force = $true }

& $install @params
exit $LASTEXITCODE
