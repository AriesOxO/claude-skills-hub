# parallel-agent 测试用例

在新对话中逐个发送以下 prompt，观察 Claude 的行为。

---

## 应该触发并行的（5 个）

### T1：多目标搜索
```
看看我的 dingtalk-notify、usage-report、parallel-agent 三个 skill 分别是做什么的
```
**预期**：3 个 Explore 代理并行，同一消息发出
**观察点**：是否用了 Explore 而非 general-purpose

### T2：多模块独立修改
```
帮我给 dingtalk-notify 和 usage-report 两个 skill 的 SKILL.md 都加上 version: 1.0 字段
```
**预期**：2 个 general-purpose 代理并行（或直接并行 Edit）
**观察点**：是否识别到两个文件修改互不依赖

### T3：研究 + 探索并行
```
查一下 Claude Code 的 hooks 机制文档，同时看看我项目里现有的 hooks 配置
```
**预期**：claude-code-guide + Explore 并行
**观察点**：是否选择了不同的代理类型

### T4：多维度审查
```
审查 parallel-agent skill 的设计：从实用性和完整性两个角度分别评估
```
**预期**：2 个 code-reviewer 或 general-purpose 并行
**观察点**：是否拆分为独立的审查维度

### T5：批量信息收集
```
帮我看看 ~/.claude/skills/ 下每个 skill 用了哪些 allowed-tools，列个对比表
```
**预期**：多个 Explore 并行搜索各 skill 目录
**观察点**：是否并行而非串行读取每个文件

---

## 不应该触发并行的（5 个）

### T6：单文件简单修改
```
把 parallel-agent 的 SKILL.md 里 "allowed-tools" 改成 "Agent, Read, Grep, Glob"（去掉 Bash）
```
**预期**：直接 Edit，不分派子代理
**观察点**：是否过度并行化了简单任务

### T7：有依赖的串行任务
```
先看看 parallel-agent skill 的内容，然后根据内容写一段使用说明
```
**预期**：串行执行（先读再写），不并行
**观察点**：是否正确识别了依赖关系

### T8：单一解释性问题
```
解释一下 worktree 隔离是什么意思
```
**预期**：直接回答或查文档，不分派多个代理
**观察点**：是否避免了不必要的并行

### T9：单目标搜索
```
找到 dingtalk.js 这个文件在哪
```
**预期**：直接 Glob 或单个 Explore，不并行
**观察点**：单一搜索不应拆分

### T10：需要上下文连续的分析
```
读一下 parallel-agent 的 SKILL.md，告诉我有没有逻辑矛盾的地方
```
**预期**：单个代理或直接读取分析，不拆分
**观察点**：整体性分析不应拆分给多个代理

---

## 评分标准

| 指标 | 合格线 |
|------|--------|
| T1-T5 触发并行 | ≥ 4/5 |
| T6-T10 不触发并行 | ≥ 4/5 |
| 代理类型选择正确 | ≥ 3/5（T1-T5 中） |
| prompt 自包含 | 所有并行调用的 prompt 都不含"根据之前..." |
| 结果汇总 | 并行结果统一报告，不逐个转述 |

## 如何执行

1. 开新对话（确保 CLAUDE.md 生效但没有本次设计讨论的上下文）
2. 逐个发送 T1-T10
3. 每个记录：是否并行、代理类型、prompt 质量
4. 如果 T1-T5 触发率 < 4/5，考虑加强 CLAUDE.md 措辞
5. 如果 T6-T10 误触发 > 1/5，考虑收紧触发条件
