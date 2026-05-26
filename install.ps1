# claude-skills-hub installer (PowerShell)
# 使用方法见 README.md 的 "在线安装" 章节

$ErrorActionPreference = 'Stop'

# 强制 UTF-8 输出，确保中文字符在 Windows 终端正确显示
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # 某些受限环境下设置编码可能失败，忽略即可
}

$script:CSH_OWNER  = if ($env:CSH_OWNER)  { $env:CSH_OWNER }  else { 'AriesOxO' }
$script:CSH_REPO   = if ($env:CSH_REPO)   { $env:CSH_REPO }   else { 'claude-skills-hub' }
$script:CSH_BRANCH = if ($env:CSH_BRANCH) { $env:CSH_BRANCH } else { 'master' }
$script:SKILLS_DIR = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $HOME '.claude/skills' }

$script:TARBALL_URL = "https://github.com/$script:CSH_OWNER/$script:CSH_REPO/archive/refs/heads/$script:CSH_BRANCH.tar.gz"
$script:RAW_URL     = "https://raw.githubusercontent.com/$script:CSH_OWNER/$script:CSH_REPO/$script:CSH_BRANCH"

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Ok   { param($Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err  { param($Message) Write-Host "[ERR]  $Message" -ForegroundColor Red }

function Show-Usage {
    $rawUrl = $script:RAW_URL
    Write-Host @"
Claude Skills Hub 安装器 (PowerShell)

用法:
  csh <command> [args...]

命令:
  install <skill>...   安装一个或多个 skill
  list                 列出仓库中所有可用 skills
  installed            列出本地已安装的 skills
  update [skill]...    更新（不指定则更新所有已安装）
  uninstall <skill>... 卸载 skill
  help                 显示此帮助

示例:
  # 一次性安装（无需保存脚本到本地）
  iex "& { `$(iwr -useb $rawUrl/install.ps1) } install parallel-agent"

  # 安装到 PATH 长期使用
  iwr -useb $rawUrl/install.ps1 -OutFile `$HOME\bin\csh.ps1
  csh.ps1 install parallel-agent

环境变量:
  CLAUDE_SKILLS_DIR    自定义 skills 安装目录（默认: ~/.claude/skills）
  CSH_BRANCH           使用特定分支/tag（默认: master）
  CSH_OWNER / CSH_REPO 自定义仓库源
"@
}

function Invoke-List {
    Write-Info "从 $script:CSH_OWNER/$script:CSH_REPO@$script:CSH_BRANCH 获取可用 skills..."
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "csh-$([System.Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
    try {
        $srcRoot = Get-TarballRoot -TmpDir $tmpDir
        $dirs = Get-ChildItem -Path $srcRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne '_template' }
        if (-not $dirs) {
            Write-Warn "未找到任何 skill"
            return
        }
        foreach ($d in $dirs) {
            Write-Host "  - $($d.Name)"
        }
    } finally {
        if (Test-Path $tmpDir) {
            Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-Installed {
    if (-not (Test-Path $script:SKILLS_DIR)) {
        Write-Info "skills 目录尚未创建: $script:SKILLS_DIR"
        return
    }
    Write-Info "已安装的 skills（位于 $script:SKILLS_DIR）:"
    $dirs = Get-ChildItem -Path $script:SKILLS_DIR -Directory -ErrorAction SilentlyContinue
    if (-not $dirs) {
        Write-Warn "没有已安装的 skills"
        return
    }
    foreach ($d in $dirs) {
        Write-Host "  - $($d.Name)"
    }
}

function Get-TarballRoot {
    param([string]$TmpDir)
    $tarPath = Join-Path $TmpDir 'repo.tar.gz'
    Write-Info "下载 $script:CSH_REPO@$script:CSH_BRANCH..."
    Invoke-WebRequest -Uri $script:TARBALL_URL -OutFile $tarPath -UseBasicParsing
    # 用 Windows 内置 tar.exe，避免 git bash 的 GNU tar 把 D: 当远程主机
    $tarExe = "$env:SystemRoot\System32\tar.exe"
    if (-not (Test-Path $tarExe)) {
        $tarExe = 'tar'
    }
    Push-Location $TmpDir
    try {
        & $tarExe -xzf 'repo.tar.gz'
        if ($LASTEXITCODE -ne 0) {
            throw "tar 解压失败（Windows 10 1803+ 自带 tar.exe，旧版本需要手动安装）"
        }
    } finally {
        Pop-Location
    }
    return (Join-Path $TmpDir "$script:CSH_REPO-$script:CSH_BRANCH/skills")
}

function Invoke-Install {
    param([string[]]$Skills)

    if (-not $Skills -or $Skills.Count -eq 0) {
        Write-Err "需要指定至少一个 skill 名称"
        Show-Usage
        exit 1
    }

    if (-not (Test-Path $script:SKILLS_DIR)) {
        New-Item -ItemType Directory -Path $script:SKILLS_DIR -Force | Out-Null
    }

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "csh-$([System.Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    $needsSnippet = @()
    try {
        $srcRoot = Get-TarballRoot -TmpDir $tmpDir
        foreach ($skill in $Skills) {
            $src = Join-Path $srcRoot $skill
            if (-not (Test-Path $src)) {
                Write-Err "skill 不存在: $skill（运行 csh list 查看可用 skills）"
                continue
            }
            $dest = Join-Path $script:SKILLS_DIR $skill
            if (Test-Path $dest) {
                Write-Warn "已存在，将覆盖: $dest"
                Remove-Item -Recurse -Force $dest
            }
            Copy-Item -Recurse -Path $src -Destination $dest
            Write-Ok "已安装: $skill -> $dest"

            if (Test-Path (Join-Path $dest 'claude-md-snippet.md')) {
                $needsSnippet += $skill
            }
        }
    } finally {
        if (Test-Path $tmpDir) {
            Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
        }
    }

    if ($needsSnippet.Count -gt 0) {
        Write-Host ""
        Write-Warn "以下 skill 需要在 CLAUDE.md 中追加配套配置:"
        foreach ($s in $needsSnippet) {
            $snippetPath = Join-Path (Join-Path $script:SKILLS_DIR $s) 'claude-md-snippet.md'
            Write-Host "    - $snippetPath"
        }
    }
}

function Invoke-Update {
    param([string[]]$Skills)
    if (-not $Skills -or $Skills.Count -eq 0) {
        if (-not (Test-Path $script:SKILLS_DIR)) {
            Write-Warn "skills 目录不存在: $script:SKILLS_DIR"
            return
        }
        $installed = Get-ChildItem -Path $script:SKILLS_DIR -Directory -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Name
        if (-not $installed) {
            Write-Info "没有已安装的 skills，无需更新"
            return
        }
        Write-Info "将更新: $($installed -join ', ')"
        Invoke-Install -Skills $installed
    } else {
        Invoke-Install -Skills $Skills
    }
}

function Invoke-Uninstall {
    param([string[]]$Skills)
    if (-not $Skills -or $Skills.Count -eq 0) {
        Write-Err "需要指定至少一个 skill 名称"
        exit 1
    }
    foreach ($skill in $Skills) {
        $dest = Join-Path $script:SKILLS_DIR $skill
        if (-not (Test-Path $dest)) {
            Write-Warn "未安装: $skill"
            continue
        }
        Remove-Item -Recurse -Force $dest
        Write-Ok "已卸载: $skill"
    }
}

# 入口：当直接执行（非 dot-source）时处理参数
$cmd = if ($args.Count -gt 0) { $args[0] } else { 'help' }
$rest = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

switch ($cmd.ToLower()) {
    'install'           { Invoke-Install -Skills $rest }
    'list'              { Invoke-List }
    'ls'                { Invoke-List }
    'installed'         { Invoke-Installed }
    'update'            { Invoke-Update -Skills $rest }
    'upgrade'           { Invoke-Update -Skills $rest }
    'uninstall'         { Invoke-Uninstall -Skills $rest }
    'remove'            { Invoke-Uninstall -Skills $rest }
    'rm'                { Invoke-Uninstall -Skills $rest }
    { $_ -in 'help','-h','--help','' } { Show-Usage }
    default {
        Write-Err "未知命令: $cmd"
        Show-Usage
        exit 1
    }
}
