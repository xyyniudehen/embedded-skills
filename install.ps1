param(
    [string]$Destination,
    [string]$SkillName,
    [switch]$All,
    [switch]$Full,
    [switch]$Agents,
    [switch]$Manual,
    [switch]$EmbeddedRules,
    [string]$EmbeddedRoot,
    [switch]$InstallGlobalRules,
    [switch]$Force,
    [switch]$Verify,
    [ValidateSet('codex', 'opencode', 'claude')]
    [string]$Runtime
)

$ErrorActionPreference = 'Stop'

$userProfile = [Environment]::GetFolderPath('UserProfile')

# -Runtime 决定默认安装位置；-Destination 显式给出时优先。
$runtimeHome = $null
if ($Runtime) {
    $runtimeHome = switch ($Runtime) {
        'codex' { if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $userProfile '.codex' } }
        'opencode' { Join-Path $userProfile '.config\opencode' }
        'claude' { Join-Path $userProfile '.claude' }
    }
}

if (-not $Destination) {
    if ($runtimeHome) {
        $Destination = Join-Path $runtimeHome 'skills'
    } elseif ($env:CODEX_HOME) {
        $Destination = Join-Path $env:CODEX_HOME 'skills'
    } else {
        $Destination = Join-Path $userProfile '.codex\skills'
    }
}

# 运行时主目录：skills 的上一级。agents、规则和手册都装在这里。
$installRoot = Split-Path -Parent $Destination
$skillRoot = Join-Path $PSScriptRoot 'skills'

if ($Full) {
    $All = $true
    $Agents = $true
    $Manual = $true
    $EmbeddedRules = $true
    $InstallGlobalRules = $true
}

$available = @(Get-ChildItem -LiteralPath $skillRoot -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') })

function Get-TreeHash {
    param([string]$Path)
    $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File | Sort-Object FullName)
    $sb = New-Object Text.StringBuilder
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($Path.Length)
        [void]$sb.Append($rel).Append(':').Append((Get-FileHash -LiteralPath $f.FullName).Hash).Append("`n")
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $sha = [Security.Cryptography.SHA256]::Create()
    ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
}

function Test-SameFile {
    param([string]$Source, [string]$Target)
    if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) { return $false }
    return (Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Target).Hash
}

# ---------------------------------------------------------------- Verify

if ($Verify) {
    $drift = $false
    function Report-File {
        param([string]$Source, [string]$Target, [string]$Label)
        if (-not (Test-Path -LiteralPath $Target)) {
            Write-Output ("MISSING  {0}  -> {1}" -f $Label, $Target)
            $script:drift = $true
        } elseif ((Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Target).Hash) {
            Write-Output ("OK       {0}" -f $Label)
        } else {
            Write-Output ("DRIFT    {0}  -> {1}" -f $Label, $Target)
            $script:drift = $true
        }
    }

    if ($All) {
        foreach ($dir in $available) {
            $target = Join-Path $Destination $dir.Name
            if (-not (Test-Path -LiteralPath $target)) {
                Write-Output ("MISSING  skills/{0}" -f $dir.Name)
                $drift = $true
            } elseif ((Get-TreeHash $dir.FullName) -eq (Get-TreeHash $target)) {
                Write-Output ("OK       skills/{0}" -f $dir.Name)
            } else {
                Write-Output ("DRIFT    skills/{0}  -> {1}" -f $dir.Name, $target)
                $drift = $true
            }
        }
        if (Test-Path -LiteralPath $Destination) {
            foreach ($dir in (Get-ChildItem -LiteralPath $Destination -Directory)) {
                if ($dir.Name -in $available.Name) { continue }
                if (Test-Path -LiteralPath (Join-Path $dir.FullName 'SKILL.md')) {
                    Write-Output ("EXTRA    skills/{0}（安装目录有，仓库没有）" -f $dir.Name)
                    $drift = $true
                }
            }
        }
    }

    if ($Agents) {
        $src = Join-Path $PSScriptRoot 'agents'
        if (Test-Path -LiteralPath $src) {
            foreach ($f in (Get-ChildItem -LiteralPath $src -File)) {
                Report-File $f.FullName (Join-Path $installRoot ('agents\' + $f.Name)) ('agents/' + $f.Name)
            }
        }
    }

    if ($InstallGlobalRules) {
        $rulesName = if ($Runtime -eq 'claude') { 'CLAUDE.md' } else { 'AGENTS.md' }
        Report-File (Join-Path $PSScriptRoot 'global\AGENTS.md') (Join-Path $installRoot $rulesName) $rulesName
    }

    if ($EmbeddedRules) {
        Report-File (Join-Path $PSScriptRoot 'global\embedded.md') (Join-Path $installRoot 'embedded.md') 'embedded.md'
    }

    if ($Manual) {
        Report-File (Join-Path $PSScriptRoot '使用手册.md') (Join-Path $installRoot '使用手册.md') '使用手册.md'
    }

    if ($EmbeddedRoot) {
        $configPath = Join-Path $EmbeddedRoot 'opencode.json'
        $expected = ((Join-Path $installRoot 'embedded.md') -replace '\\', '/')
        if (-not (Test-Path -LiteralPath $configPath)) {
            Write-Output ("MISSING  {0}（目录级配置）" -f $configPath)
            $drift = $true
        } else {
            $raw = Get-Content -LiteralPath $configPath -Raw
            if ($raw -match [regex]::Escape($expected)) {
                Write-Output 'OK       opencode.json instructions'
            } else {
                Write-Output ("DRIFT    opencode.json instructions 应为 {0}" -f $expected)
                $drift = $true
            }
        }
    }

    Write-Output ''
    if ($drift) {
        Write-Output 'RESULT: 存在差异。确认后加 -Force 重装；仓库才是真源，不要直接修改安装副本。'
        exit 1
    }
    Write-Output 'RESULT: 全部一致。'
    exit 0
}

# ---------------------------------------------------------------- Install

$backupRoot = Join-Path $installRoot ('.backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Backup-Target {
    param([string]$Target, [string]$Relative)
    $dest = Join-Path $backupRoot $Relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $Target -Destination $dest -Recurse -Force
    Write-Output "Backed up $Target -> $dest"
}

function Sync-File {
    param([string]$Source, [string]$Target, [string]$Relative, [string]$Label)
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Target).Hash) {
            Write-Output "$Label already current at $Target"
            return
        }
        if (-not $Force) { throw "$Label differs: $Target. Review or use -Force to replace." }
        Backup-Target $Target $Relative
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Target -Force
    Write-Output "Installed $Label to $Target"
}

if ($All -and $SkillName) { throw 'Use either -All or -SkillName, not both.' }
if ($All) { $names = @($available.Name) } elseif ($SkillName) { $names = @($SkillName) } else { $names = @('embedded-change-archive') }
New-Item -ItemType Directory -Path $Destination -Force | Out-Null

foreach ($name in $names) {
    if ($name -notmatch '^[a-z0-9-]+$') { throw "Invalid skill name: $name" }
    $source = Join-Path $skillRoot $name
    if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md'))) { throw "Missing skill in maintenance repository: $source" }
    $target = Join-Path $Destination $name
    if (Test-Path -LiteralPath $target) {
        if ((Get-TreeHash $source) -eq (Get-TreeHash $target)) {
            Write-Output "Skill $name already current at $target"
            continue
        }
        if (-not $Force) { throw "Destination differs: $target. Review or use -Force to update managed files." }
        Backup-Target $target ('skills\' + $name)
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Get-ChildItem -LiteralPath $source -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($source.Length).TrimStart('\', '/')
        $output = Join-Path $target $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $output) -Force | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $output -Force
    }
    Write-Output "Installed skill $name to $target"
}

if ($Agents) {
    $source = Join-Path $PSScriptRoot 'agents'
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing agents directory: $source" }
    foreach ($f in (Get-ChildItem -LiteralPath $source -File)) {
        Sync-File $f.FullName (Join-Path $installRoot ('agents\' + $f.Name)) ('agents\' + $f.Name) ('agent ' + $f.Name)
    }
    if ($Runtime -eq 'codex') {
        Write-Output 'WARNING: Codex 对自定义子代理的支持未核实；若 agents 目录未被识别，请改用新会话方式粘贴 agents/embedded-reviewer.md。'
    }
}

if ($InstallGlobalRules) {
    $rulesName = if ($Runtime -eq 'claude') { 'CLAUDE.md' } else { 'AGENTS.md' }
    Sync-File (Join-Path $PSScriptRoot 'global\AGENTS.md') (Join-Path $installRoot $rulesName) $rulesName 'global rules'
}

if ($EmbeddedRules) {
    Sync-File (Join-Path $PSScriptRoot 'global\embedded.md') (Join-Path $installRoot 'embedded.md') 'embedded.md' 'embedded rules'

    if ($EmbeddedRoot) {
        New-Item -ItemType Directory -Path $EmbeddedRoot -Force | Out-Null
        $configPath = Join-Path $EmbeddedRoot 'opencode.json'
        $expected = ((Join-Path $installRoot 'embedded.md') -replace '\\', '/')
        if (-not (Test-Path -LiteralPath $configPath)) {
            $json = [ordered]@{
                '$schema'      = 'https://opencode.ai/config.json'
                'instructions' = @($expected)
            } | ConvertTo-Json -Depth 4
            [IO.File]::WriteAllText($configPath, $json + "`n", [Text.UTF8Encoding]::new($false))
            Write-Output "Created directory-level config $configPath"
        } else {
            try {
                $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
                $entries = @()
                if ($config.PSObject.Properties.Name -contains 'instructions') { $entries = @($config.instructions) }
                $others = @($entries | Where-Object { $_ -notmatch 'embedded\.md$' })
                $updated = @($others + $expected)
                if (($entries -join '|') -eq ($updated -join '|')) {
                    Write-Output "Directory-level config already points to $expected"
                } else {
                    Backup-Target $configPath 'opencode.json'
                    if ($config.PSObject.Properties.Name -contains 'instructions') {
                        $config.instructions = $updated
                    } else {
                        $config | Add-Member -NotePropertyName instructions -NotePropertyValue $updated
                    }
                    $json = $config | ConvertTo-Json -Depth 10
                    [IO.File]::WriteAllText($configPath, $json + "`n", [Text.UTF8Encoding]::new($false))
                    Write-Output "Updated instructions in $configPath -> $expected"
                }
            } catch {
                Write-Output "WARNING: 无法自动更新 $configPath（可能是 JSONC 或格式特殊）。请手动确保 instructions 包含：$expected"
            }
        }
    } else {
        Write-Output "提示：如需只在嵌入式目录生效，在 <目录>\opencode.json 的 instructions 中加入：$((Join-Path $installRoot 'embedded.md'))"
    }
}

if ($Manual) {
    Sync-File (Join-Path $PSScriptRoot '使用手册.md') (Join-Path $installRoot '使用手册.md') '使用手册.md' 'manual'
}

Write-Output ''
Write-Output "Install root: $installRoot"
Write-Output 'Next: 发送 >>help 验证入口说明；发送 >>safe 验证会先报成本。'
