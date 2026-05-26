# CLAUDE.md 行为层配置

要让 `parallel-agent` skill 发挥最大效果，需要在你的 `~/.claude/CLAUDE.md`（或项目级 `CLAUDE.md`）中加入以下"行为层"内容。

**为什么需要两层配合？**

- **CLAUDE.md 行为层**：始终在上下文中的决策框架。包含独立性判断、简单/复杂场景分流表、类型选择速查。让 Claude 在每个任务开始时就能判断"是否需要并行"。
- **SKILL.md 深度参考**：按需调用的复杂场景指南。包含 worktree 隔离、分阶段编排、失败恢复等。只有遇到复杂场景时才读取，避免日常对话被淹没。

如果只装 SKILL.md 而没有 CLAUDE.md 行为层，Claude 可能在该并行时仍串行执行 —— 因为它不知道何时该读 skill。

---

## 推荐加到 CLAUDE.md 的内容

直接复制下方代码块到你的 `~/.claude/CLAUDE.md`（或追加为新章节）：

````markdown
## 并行子代理策略

识别到 2 个或以上无依赖关系的子任务时，必须在同一条消息中并行分派子代理。串行执行独立任务是对用户时间的浪费。

### 独立性快速判断

子任务 A 和 B 独立 = A 不需要 B 的输出就能开始 + 作用于不同文件/模块。

### 决策框架

| 判断 | 选择 |
|------|------|
| 2-3 个独立搜索/分析 | 直接并行，不需要读 skill |
| 需要写代码且涉及多文件 | 并行 + worktree 隔离 |
| 先研究再执行的复杂任务 | 分阶段并行，读 parallel-agent skill |
| 4+ 个子代理编排 | 读 parallel-agent skill 获取编排策略 |

### 类型选择速查

- 定位/搜索 → Explore（只能读摘录，不能做深度分析）
- 代码审查 → feature-dev:code-reviewer
- 写代码/改文件 → general-purpose
- 查文档/API → claude-code-guide
- 深度追踪调用链 → feature-dev:code-explorer

### 行为规则

1. 分析任务时先识别并行机会，在同一条消息中发出所有独立的 Agent 调用
2. 每个子代理 prompt 必须自包含 — 完整描述目标、上下文、约束、输出格式
3. 不要委托理解："根据你的发现来实现" 是错误的，主线程必须综合结果后给出具体指令
4. 需要写代码的并行任务使用 `isolation: "worktree"` 避免冲突
5. 子代理返回后验证实际结果（读文件/diff），不要只信摘要
6. 结果统一汇总后报告，按用户关心的维度组织，不逐个转述
7. 要求子代理精简输出（"200 字以内"/"只返回路径和行号"），控制上下文膨胀
````

---

## 安装步骤

1. **复制 skill 文件到本地**：

   ```bash
   cp -r skills/parallel-agent ~/.claude/skills/
   ```

2. **将上方代码块追加到 CLAUDE.md**：

   ```bash
   # 用你喜欢的编辑器打开
   code ~/.claude/CLAUDE.md
   # 或
   vim ~/.claude/CLAUDE.md
   ```

3. **验证生效**：

   开新对话，发送 `test-cases.md` 中的 T1 测试 prompt，观察 Claude 是否并行分派多个子代理。

---

## 项目级 vs 用户级配置

| 配置位置 | 适用场景 |
|---------|---------|
| `~/.claude/CLAUDE.md` | 所有项目通用，适合大部分用户 |
| `<project>/CLAUDE.md` | 只对特定项目启用并行策略 |
| `~/.claude/skills/parallel-agent/` | 用户级 skill，所有项目都能调用 |
| `<project>/.claude/skills/parallel-agent/` | 项目级 skill，只在该项目可见 |

推荐：CLAUDE.md 行为层放用户级，skill 也放用户级，享受跨项目复用。
