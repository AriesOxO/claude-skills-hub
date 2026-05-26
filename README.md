# Claude Skills Hub

社区驱动的 Claude Code Skills 共享仓库。在这里你可以发现、使用和贡献高质量的 Claude Code 技能。

## 什么是 Skill？

Skill 是 Claude Code 的可复用自动化流程，通过 `SKILL.md` 文件定义触发条件、执行步骤和输出格式，让 Claude 在特定场景下自动执行标准化操作。

## 快速开始

### 安装使用

```bash
# 克隆仓库
git clone https://github.com/AriesOxO/claude-skills-hub.git

# 将想要的 skill 复制到你的 Claude Code skills 目录
cp -r skills/某个skill ~/.claude/skills/
```

### 浏览技能

查看 [技能索引](skills/README.md) 了解所有可用技能。

## 目录结构

```
claude-skills-hub/
├── skills/              # 所有共享技能
│   ├── README.md        # 技能索引（分类列表）
│   ├── _template/       # 技能模板（创建新技能的起点）
│   └── <skill-name>/    # 各个技能目录
│       ├── SKILL.md     # 技能定义文件
│       └── README.md    # 技能说明文档
├── CONTRIBUTING.md      # 贡献指南
└── LICENSE
```

## 贡献

欢迎贡献你的 Skill！请阅读 [贡献指南](CONTRIBUTING.md)。

简要流程：
1. Fork 本仓库
2. 基于 `skills/_template/` 创建你的技能
3. 提交 PR，填写技能说明

## 许可证

MIT License
