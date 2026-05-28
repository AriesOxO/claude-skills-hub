# Claude Skills Hub

社区驱动的 Claude Code Skills 共享仓库。在这里你可以发现、使用和贡献高质量的 Claude Code 技能。

## 什么是 Skill？

Skill 是 Claude Code 的可复用自动化流程，通过 `SKILL.md` 文件定义触发条件、执行步骤和输出格式，让 Claude 在特定场景下自动执行标准化操作。

## 快速开始

### 在线安装（推荐）

**macOS / Linux / Git Bash / WSL**

```bash
# 一次性安装单个 skill（无需保存脚本）
bash -c "$(curl -sSL https://raw.githubusercontent.com/AriesOxO/claude-skills-hub/master/install.sh)" -- install parallel-agent

# 长期使用：把脚本装到 PATH，之后用 csh 命令
curl -sSL https://raw.githubusercontent.com/AriesOxO/claude-skills-hub/master/install.sh -o ~/.local/bin/csh
chmod +x ~/.local/bin/csh
csh install parallel-agent
```

**Windows PowerShell**

```powershell
# 一次性安装单个 skill
iex "& { $(iwr -useb https://raw.githubusercontent.com/AriesOxO/claude-skills-hub/master/install.ps1) } install parallel-agent"

# 长期使用：保存到 PATH 路径
iwr -useb https://raw.githubusercontent.com/AriesOxO/claude-skills-hub/master/install.ps1 -OutFile $HOME\bin\csh.ps1
csh.ps1 install parallel-agent
```

### 命令一览

| 命令 | 作用 |
|------|------|
| `csh install <skill>...` | 安装一个或多个 skill 到 `~/.claude/skills/` |
| `csh list` | 列出仓库中所有可用 skills |
| `csh installed` | 列出本地已安装的 skills |
| `csh update [skill]...` | 更新（不指定参数时更新所有已安装的） |
| `csh uninstall <skill>...` | 卸载 skill |
| `csh help` | 显示帮助 |

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLAUDE_SKILLS_DIR` | `~/.claude/skills` | 自定义安装目录 |
| `CSH_BRANCH` | `master` | 使用特定分支/tag |
| `CSH_OWNER` / `CSH_REPO` | `AriesOxO` / `claude-skills-hub` | 自定义仓库源（fork 后可指向自己） |

### 离线安装（手动）

```bash
git clone https://github.com/AriesOxO/claude-skills-hub.git
cp -r claude-skills-hub/skills/parallel-agent ~/.claude/skills/
```

### 浏览技能

查看 [技能索引](skills/README.md) 了解所有可用技能。

## 重要提示

部分 skill（如 `parallel-agent`）需要配合 CLAUDE.md 行为层配置才能发挥效果。安装时如检测到 `claude-md-snippet.md` 文件，安装器会提示你查看该文件并把内容追加到 `~/.claude/CLAUDE.md`。

## 目录结构

```
claude-skills-hub/
├── install.sh             # bash/zsh/git bash/WSL 安装器
├── install.ps1            # Windows PowerShell 安装器
├── skills/                # 所有共享技能
│   ├── README.md          # 技能索引（分类列表）
│   ├── _template/         # 技能模板（创建新技能的起点）
│   └── <skill-name>/      # 各个技能目录
│       ├── SKILL.md       # 技能定义文件
│       ├── README.md      # 技能说明文档
│       └── claude-md-snippet.md  # （可选）CLAUDE.md 配套配置
├── CONTRIBUTING.md        # 贡献指南
└── LICENSE
```

## 贡献

欢迎贡献你的 Skill！请阅读 [贡献指南](CONTRIBUTING.md)。

简要流程：
1. Fork 本仓库
2. 基于 `skills/_template/` 创建你的技能
3. 用 `csh install --local ./skills/你的技能 你的技能` 本地验证
4. 提交 PR，填写技能说明

## 常见问题

### 下载失败 / 网络超时

国内用户访问 GitHub 可能不稳定。设置代理后重试：

```bash
# bash
export https_proxy=http://127.0.0.1:7897
csh install parallel-agent

# PowerShell
$env:HTTPS_PROXY = 'http://127.0.0.1:7897'
csh.ps1 install parallel-agent
```

安装器内置 3 次重试，通常第二次就能成功。

### PowerShell 提示"无法加载文件...因为在此系统上禁止运行脚本"

Windows 默认禁止运行 `.ps1` 脚本。以管理员身份运行：

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

或者用一次性方式绕过（不修改系统策略）：

```powershell
powershell -ExecutionPolicy Bypass -File csh.ps1 install parallel-agent
```

### tar 解压失败

- **Windows**：需要 Windows 10 1803+ 内置的 `tar.exe`。旧版本请升级系统或安装 [7-Zip](https://7-zip.org/)
- **macOS/Linux**：通常自带 tar，如果缺失：`brew install gnu-tar` 或 `apt install tar`

### 权限不足 / mkdir 失败

安装器默认写入 `~/.claude/skills/`。如果该路径无权限，用环境变量指定其他位置：

```bash
export CLAUDE_SKILLS_DIR=~/my-skills
csh install parallel-agent
```

### 安装后 Claude 没有使用 skill

1. 确认 skill 文件在正确位置：`ls ~/.claude/skills/parallel-agent/SKILL.md`
2. 如果 skill 需要 CLAUDE.md 配套配置（如 parallel-agent），确认已追加。用 `--auto-config` 可自动完成
3. 开新对话测试（旧对话可能不会重新加载 skills）

## 许可证

MIT License
