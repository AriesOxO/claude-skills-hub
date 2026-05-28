# claude-skills-hub installer (PowerShell)
# 使用方法见 README.md 的 "在线安装" 章节

$ErrorActionPreference = 'Stop'

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$script:CSH_OWNER    = if ($env:CSH_OWNER)         { $env:CSH_OWNER }         else { 'AriesOxO' }
$script:CSH_REPO     = if ($env:CSH_REPO)          { $env:CSH_REPO }          else { 'claude-skills-hub' }
$script:CSH_BRANCH   = if ($env:CSH_BRANCH)        { $env:CSH_BRANCH }        else { 'master' }
$script:SKILLS_DIR   = if ($env:CLAUDE_SKILLS_DIR)  { $env:CLAUDE_SKILLS_DIR }  else { Join-Path $HOME '.claude/skills' }
$script:CLAUDE_MD    = if ($env:CLAUDE_MD_PATH)     { $env:CLAUDE_MD_PATH }     else { Join-Path $HOME '.claude/CLAUDE.md' }
$script:CACHE_TTL    = if ($env:CSH_CACHE_TTL)      { [int]$env:CSH_CACHE_TTL } else { 300 }

$script:TARBALL_URL = "https://github.com/$script:CSH_OWNER/$script:CSH_REPO/archive/refs/heads/$script:CSH_BRANCH.tar.gz"
$script:RAW_URL     = "https://raw.githubusercontent.com/$script:CSH_OWNER/$script:CSH_REPO/$script:CSH_BRANCH"
$script:CACHE_DIR   = Join-Path ([System.IO.Path]::GetTempPath()) "csh-cache-$script:CSH_OWNER-$script:CSH_REPO-$script:CSH_BRANCH"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Ok   { param($Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err  { param($Message) Write-Host "[ERR]  $Message" -ForegroundColor Red }

function Show-Usage {
    $rawUrl = $script:RAW_URL
    Write-Host @"
Claude Skills Hub 安装器 (PowerShell)

用法:
  csh <command> [options] [args...]

命令:
  install [--auto-config] [--local <path>] <skill>...
  list [--verbose]       列出仓库中所有可用 skills
  installed              列出本地已安装的 skills
  update [skill]...      更新
  uninstall <skill>...   卸载 skill
  help                   显示此帮助

示例:
  iex "& { `$(iwr -useb $rawUrl/install.ps1) } install --auto-config parallel-agent"
  csh.ps1 install --local .\skills\my-skill my-skill
  csh.ps1 list --verbose
"@
}

function Get-TarballRoot {
    param([string]$TmpDir)

    # 缓存机制
    $tsFile = Join-Path $script:CACHE_DIR '.timestamp'
    if ((Test-Path $script:CACHE_DIR) -and (Test-Path $tsFile)) {
        $cachedTime = [int](Get-Content $tsFile)
        $now = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $age = $now - $cachedTime
        if ($age -lt $script:CACHE_TTL) {
            Write-Info "使用缓存（${age}s 前下载）"
            return (Join-Path $script:CACHE_DIR 'skills')
        }
    }

    $tarPath = Join-Path $TmpDir 'repo.tar.gz'
    Write-Info "下载 $script:CSH_REPO@$script:CSH_BRANCH..."

    $retries = 3
    for ($i = 0; $i -lt $retries; $i++) {
        try {
            Invoke-WebRequest -Uri $script:TARBALL_URL -OutFile $tarPath -UseBasicParsing -TimeoutSec 30
            break
        } catch {
            if ($i -lt ($retries - 1)) {
                Write-Warn "下载失败，重试 ($($i+1)/$retries)..."
                Start-Sleep -Seconds 2
            } else {
                Write-Err "下载失败: $script:TARBALL_URL（已重试 $retries 次）"
                Write-Err "如果是网络问题，尝试设置代理: `$env:HTTPS_PROXY='http://your-proxy:port'"
                exit 1
            }
        }
    }

    $tarExe = "$env:SystemRoot\System32\tar.exe"
    if (-not (Test-Path $tarExe)) { $tarExe = 'tar' }
    Push-Location $TmpDir
    try {
        & $tarExe -xzf 'repo.tar.gz'
        if ($LASTEXITCODE -ne 0) { throw "tar 解压失败" }
    } finally { Pop-Location }

    # 写入缓存
    if (Test-Path $script:CACHE_DIR) { Remove-Item -Recurse -Force $script:CACHE_DIR }
    Copy-Item -Recurse (Join-Path $TmpDir "$script:CSH_REPO-$script:CSH_BRANCH") $script:CACHE_DIR
    [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString() | Set-Content (Join-Path $script:CACHE_DIR '.timestamp')

    return (Join-Path $TmpDir "$script:CSH_REPO-$script:CSH_BRANCH/skills")
}

function Get-SkillDescription {
    param([string]$SkillMdPath)
    if (-not (Test-Path $SkillMdPath)) { return '' }
    $lines = Get-Content $SkillMdPath -TotalCount 20
    $inFrontmatter = $false
    foreach ($line in $lines) {
        if ($line -eq '---' -and -not $inFrontmatter) { $inFrontmatter = $true; continue }
        if ($line -eq '---' -and $inFrontmatter) { break }
        if ($inFrontmatter -and $line -match '^description:\s*(.+)$') { return $Matches[1] }
    }
    return ''
}

function Invoke-AutoConfig {
    param([string]$Skill)
    $snippetPath = Join-Path (Join-Path $script:SKILLS_DIR $Skill) 'claude-md-snippet.md'
    if (-not (Test-Path $snippetPath)) { return }

    $lines = Get-Content $snippetPath
    $inBlock = $false; $content = @()
    foreach ($line in $lines) {
        if ($line -eq '````markdown') { $inBlock = $true; continue }
        if ($line -eq '````' -and $inBlock) { break }
        if ($inBlock) { $content += $line }
    }
    if ($content.Count -eq 0) {
        Write-Warn "无法从 $snippetPath 提取配置内容，请手动查看"
        return
    }

    if ((Test-Path $script:CLAUDE_MD) -and (Get-Content $script:CLAUDE_MD -Raw) -match '## 并行子代理策略') {
        Write-Info "$Skill 的 CLAUDE.md 配置已存在，跳过"
        return
    }

    $dir = Split-Path $script:CLAUDE_MD -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    "`n`n" + ($content -join "`n") | Add-Content $script:CLAUDE_MD
    Write-Ok "已将 $Skill 配置追加到 $script:CLAUDE_MD"
}
function Invoke-List {
    param([switch]$Verbose)
    Write-Info "从 $script:CSH_OWNER/$script:CSH_REPO@$script:CSH_BRANCH 获取可用 skills..."
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "csh-$([System.Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
    try {
        $srcRoot = Get-TarballRoot -TmpDir $tmpDir
        $dirs = Get-ChildItem -Path $srcRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne '_template' }
        if (-not $dirs) { Write-Warn "未找到任何 skill"; return }
        foreach ($d in $dirs) {
            if ($Verbose) {
                $desc = Get-SkillDescription (Join-Path $d.FullName 'SKILL.md')
                if ($desc) { Write-Host ("  {0,-20} {1}" -f $d.Name, $desc) }
                else { Write-Host ("  {0,-20} (无描述)" -f $d.Name) }
            } else {
                Write-Host "  - $($d.Name)"
            }
        }
    } finally {
        if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue }
    }
}

function Invoke-Installed {
    if (-not (Test-Path $script:SKILLS_DIR)) {
        Write-Info "skills 目录尚未创建: $script:SKILLS_DIR"; return
    }
    Write-Info "已安装的 skills（位于 $script:SKILLS_DIR）:"
    $dirs = Get-ChildItem -Path $script:SKILLS_DIR -Directory -ErrorAction SilentlyContinue
    if (-not $dirs) { Write-Warn "没有已安装的 skills"; return }
    foreach ($d in $dirs) { Write-Host "  - $($d.Name)" }
}

function Invoke-Install {
    param([string[]]$RawArgs)

    $autoConfig = $false; $localPath = ''; $skills = @()
    $i = 0
    while ($i -lt $RawArgs.Count) {
        switch ($RawArgs[$i]) {
            '--auto-config' { $autoConfig = $true }
            '--local' { $i++; $localPath = $RawArgs[$i] }
            default { $skills += $RawArgs[$i] }
        }
        $i++
    }

    if ($skills.Count -eq 0) { Write-Err "需要指定至少一个 skill 名称"; Show-Usage; exit 1 }
    if (-not (Test-Path $script:SKILLS_DIR)) {
        New-Item -ItemType Directory -Path $script:SKILLS_DIR -Force | Out-Null
    }

    $srcRoot = ''
    if ($localPath) {
        if (-not (Test-Path $localPath)) { Write-Err "本地路径不存在: $localPath"; exit 1 }
        $srcRoot = $localPath
        Write-Info "从本地路径安装: $localPath"
    } else {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "csh-$([System.Guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path $tmpDir | Out-Null
        $srcRoot = Get-TarballRoot -TmpDir $tmpDir
    }

    $needsSnippet = @()
    foreach ($skill in $skills) {
        if ($localPath) {
            $srcSkill = $localPath
            if (-not (Test-Path (Join-Path $srcSkill 'SKILL.md'))) {
                Write-Err "目录中缺少 SKILL.md: $srcSkill"; continue
            }
        } else {
            $srcSkill = Join-Path $srcRoot $skill
            if (-not (Test-Path $srcSkill)) {
                Write-Err "skill 不存在: $skill（运行 csh list 查看）"; continue
            }
        }
        $dest = Join-Path $script:SKILLS_DIR $skill
        if (Test-Path $dest) {
            Write-Warn "已存在，将覆盖: $dest"
            Remove-Item -Recurse -Force $dest
        }
        Copy-Item -Recurse -Path $srcSkill -Destination $dest
        Write-Ok "已安装: $skill -> $dest"
        if (Test-Path (Join-Path $dest 'claude-md-snippet.md')) { $needsSnippet += $skill }
    }

    if ($needsSnippet.Count -gt 0) {
        Write-Host ""
        if ($autoConfig) {
            foreach ($s in $needsSnippet) { Invoke-AutoConfig -Skill $s }
        } else {
            Write-Warn "以下 skill 需要在 CLAUDE.md 中追加配套配置:"
            foreach ($s in $needsSnippet) {
                Write-Host "    - $(Join-Path (Join-Path $script:SKILLS_DIR $s) 'claude-md-snippet.md')"
            }
            Write-Info "提示: 使用 --auto-config 可自动追加"
        }
    }

    if ($tmpDir -and (Test-Path $tmpDir)) {
        Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    }
}

function Invoke-Update {
    param([string[]]$Skills)
    if (-not $Skills -or $Skills.Count -eq 0) {
        if (-not (Test-Path $script:SKILLS_DIR)) { Write-Warn "skills 目录不存在"; return }
        $installed = Get-ChildItem -Path $script:SKILLS_DIR -Directory | Select-Object -ExpandProperty Name
        if (-not $installed) { Write-Info "没有已安装的 skills"; return }
        Write-Info "将更新: $($installed -join ', ')"
        Invoke-Install -RawArgs $installed
    } else {
        Invoke-Install -RawArgs $Skills
    }
}

function Invoke-Uninstall {
    param([string[]]$Skills)
    if (-not $Skills -or $Skills.Count -eq 0) { Write-Err "需要指定至少一个 skill 名称"; exit 1 }
    foreach ($skill in $Skills) {
        $dest = Join-Path $script:SKILLS_DIR $skill
        if (-not (Test-Path $dest)) { Write-Warn "未安装: $skill"; continue }
        Remove-Item -Recurse -Force $dest
        Write-Ok "已卸载: $skill"
    }
}

$cmd = if ($args.Count -gt 0) { $args[0] } else { 'help' }
$rest = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

switch ($cmd.ToLower()) {
    'install'           { Invoke-Install -RawArgs $rest }
    { $_ -in 'list','ls' } {
        $v = $rest -contains '--verbose' -or $rest -contains '-v'
        Invoke-List -Verbose:$v
    }
    'installed'         { Invoke-Installed }
    { $_ -in 'update','upgrade' } { Invoke-Update -Skills $rest }
    { $_ -in 'uninstall','remove','rm' } { Invoke-Uninstall -Skills $rest }
    { $_ -in 'help','-h','--help','' } { Show-Usage }
    default { Write-Err "未知命令: $cmd"; Show-Usage; exit 1 }
}
