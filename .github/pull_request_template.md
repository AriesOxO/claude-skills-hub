## 新增 Skill

### 技能信息

- **技能名称**：
- **分类**：（productivity / code-quality / documentation / devops / notification / analysis）
- **一句话描述**：

### 变更说明

简要描述这个 skill 做什么、解决什么问题。

### 自检清单

- [ ] `SKILL.md` 结构完整（frontmatter + 触发条件 + 执行步骤 + 输出格式）
- [ ] `README.md` 包含使用示例和安装说明
- [ ] 无硬编码个人信息（API key、绝对路径等）
- [ ] 已通过 `csh install --local ./skills/<name> <name>` 本地验证
- [ ] 不依赖仓库中其他 skill 的文件（如有依赖请说明）
- [ ] 如需 CLAUDE.md 配套配置，已提供 `claude-md-snippet.md`

### 测试方法

描述如何验证这个 skill 正常工作（如：开新对话，发送什么 prompt，期望什么行为）。

### 兼容性

- 支持的操作系统：macOS / Linux / Windows（如有限制请说明）
- 依赖的外部工具：（如 git、curl、特定 CLI 等）
