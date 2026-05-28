# parallel-agent

并行子代理编排的深度参考指南。帮助 Claude 在复杂多阶段并行任务中做出正确的编排决策。

## ⚠️ 重要：需要两层配合

此 skill 单独安装效果有限，必须配合 CLAUDE.md 行为层使用：

| 层级 | 文件 | 作用 |
|------|------|------|
| 行为层（始终在上下文） | `~/.claude/CLAUDE.md` 中的并行子代理策略章节 | 让 Claude 在每个任务开始就判断"是否需要并行"，含独立性判断、决策框架、类型选择速查、7 条行为规则 |
| 深度参考（按需调用） | `~/.claude/skills/parallel-agent/SKILL.md` | 复杂场景的编排策略，含 worktree 隔离、分阶段编排、失败恢复 |

**只装 SKILL.md 而没有 CLAUDE.md 行为层**，Claude 不知道何时该读 skill，可能在该并行时仍串行执行。

完整配置见 [claude-md-snippet.md](./claude-md-snippet.md)。

## 用途

当 Claude 需要处理以下场景时，调用此 skill 获取编排策略：

- 复杂的多阶段并行任务（研究 → 决策 → 执行）
- 并行代码修改需要 worktree 隔离避免冲突
- 4+ 个子代理的批量编排
- 跨模块协调的并行流程

> 简单的 2-3 个并行搜索由 CLAUDE.md 行为层直接处理，不需要读此 skill。

## 内容覆盖

| 章节 | 内容 |
|------|------|
| 零 | 30 秒决策树 |
| 一 | Foreground vs Background 选择 |
| 二 | Worktree 隔离与合并流程 |
| 三 | Model 选择策略（haiku/sonnet/opus） |
| 四 | 分阶段编排模式（A/B/C） |
| 五 | 子代理类型选择 |
| 六 | Trust but Verify 验证清单 |
| 七 | 失败恢复策略 |
| 八 | 反模式与边界 |
| 九 | Prompt 编写要点 |

## 安装

**推荐方式（一行命令，自动配置 CLAUDE.md）：**

```bash
bash -c "$(curl -sSL https://raw.githubusercontent.com/AriesOxO/claude-skills-hub/master/install.sh)" -- install --auto-config parallel-agent
```

**手动方式（两步配置）：**

### 1. 复制 skill 到本地

```bash
cp -r skills/parallel-agent ~/.claude/skills/
```

### 2. 配置 CLAUDE.md 行为层

将 [claude-md-snippet.md](./claude-md-snippet.md) 中提供的"并行子代理策略"章节追加到 `~/.claude/CLAUDE.md`（用户级，推荐）或项目根目录的 `CLAUDE.md`（项目级）。

## 分类

`productivity` — 工作流优化

## 作者

claude-skills-hub maintainers

## 许可证

MIT
