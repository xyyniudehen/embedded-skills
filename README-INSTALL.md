# 给 AI 的安装说明

本文件写给你（正在阅读它的 AI），人类用户可以跳过。目标：把本仓库的技能、只读审查者和入口规则，装进你当前运行的 agent 配置，并且不破坏已有内容。

按顺序执行，每一步做完再进下一步。中途无法确定时停下来报告，不要猜。

## 新电脑快速开始

已经拿到本仓库（clone、拷贝或解压）后，在仓库目录执行：

```powershell
# 1. 安装（自动识别 OpenCode / Codex / Claude；嵌入式规则默认全局常驻）
.\bootstrap.ps1 -Force

# 2. 校验（只读；带上同样的参数）
.\bootstrap.ps1 -Verify
```

- 不想自动识别：加 `-Runtime opencode|codex|claude`
- PowerShell 拦截脚本时：`powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Force`
- 不是 Windows，或没有 PowerShell：继续读下面的手工步骤，或把本文件交给你的 AI 让它照做
- 想限定嵌入式规则只对某个工程树生效：加 `-EmbeddedRoot '<这台机器上的工程根>'`，不要照抄别的机器

## 第 0 步：识别你所在的运行时

如果你能执行 PowerShell，优先直接运行安装脚本，它会一次装齐技能、审查者、全局规则、嵌入式规则和使用手册：

```powershell
.\install.ps1 -Full -Runtime opencode
```

装完或改动后用 `-Verify` 只读检查是否一致：

```powershell
.\install.ps1 -Full -Runtime opencode -Verify
```

`-Full` 装到 OpenCode 时会把 `embedded.md` 的绝对路径写进全局 `opencode.json` 的 `instructions`，默认对所有目录生效。想限定到某个工程树时改用 `-EmbeddedRoot '<工程根>'`：它会在该目录写一个 `opencode.json`，不再写全局 `instructions`。

目标机器无法运行脚本，或运行时不在上面三个之中时，继续下面的手工步骤。

按顺序检查这些路径是否存在：

| 检查路径 | 判定 |
| --- | --- |
| `~/.config/opencode/` | OpenCode |
| `~/.codex/` | Codex CLI |
| `~/.claude/` | Claude Code |
| 都不存在 | 进入「未知运行时」分支（见文末） |

同时确认这些目录里是否已有 `AGENTS.md` 或 `CLAUDE.md`，以及是否存在 `skills/`。已有内容一律保留。

## 第 1 步：查表定位

| 运行时 | 入口规则文件 | 技能目录 | 只读审查者 |
| --- | --- | --- | --- |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/skills/` | `~/.config/opencode/agents/embedded-reviewer.md` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/` | `~/.claude/agents/embedded-reviewer.md`（不支持时改为新开会话） |
| Codex CLI | `~/.codex/AGENTS.md` | `~/.codex/skills/` | 按版本核实；不支持时改为新开会话 |

路径以实际探测到的为准。表中路径不存在时，创建父目录后再写入，不要写到其他运行时的目录里。

## 第 2 步：复制技能

来源：本仓库 `skills/` 下的每个包含 `SKILL.md` 的目录。

对每个技能：

1. 目标路径 `<技能目录>/<技能名>/`。
2. 已存在同名目录时，先整体备份到 `<技能目录>/.backup-<YYYYMMDD-HHMMSS>/<技能名>/`，再覆盖。
3. 递归复制全部文件，保持目录结构（含 `references/`、`scripts/`）。
4. 不删除目标目录里其他技能的已有文件。

技能清单以 `skills/` 实际内容为准，当前为：

- `embedded-project-dev-style`
- `embedded-change-archive`
- `embedded-impact-verify`

## 第 3 步：安装只读审查者

把本仓库 `agents/embedded-reviewer.md` 复制到第 1 步表中的审查者路径。目标已存在时同样先备份。

如果该运行时不支持定义子代理：

- 不强行创建文件；
- 在报告里写明“审查者需人工以新会话方式使用”，并给出用法：新开一个会话，只贴 diff、范围声明和验收标准，再贴 `embedded-reviewer.md` 全文。

## 第 4 步：合并入口规则

来源：本仓库 `global/AGENTS.md`。

用标记块包裹后合并，标记固定为：

```text
<!-- embedded-workflow:start v1 -->
（global/AGENTS.md 全文）
<!-- embedded-workflow:end -->
```

规则：

1. 目标文件里已有 `embedded-workflow:start` 块 → 整体替换该块内容，保留块外的原有内容。
2. 没有该块 → 在文件末尾追加一个空行，再追加整块。
3. 目标文件不存在 → 创建文件，只写该块。
4. **严禁重写、删除或重排用户已有的规则。**
5. 同一文件里只能存在一个该标记块。

### 嵌入式规则（默认全局常驻，可限定目录）

来源：本仓库 `global/embedded.md`。**不要把它整段并进 `AGENTS.md`**；用 `instructions` 引入文件，改动才不用重装。

OpenCode：

1. 把 `embedded.md` 复制到 `<运行时主目录>/embedded.md`（例如 `~/.config/opencode/embedded.md`）。
2. 默认把该绝对路径追加到全局 `~/.config/opencode/opencode.json` 的 `instructions`：

   ```jsonc
   {
     "$schema": "https://opencode.ai/config.json",
     "instructions": ["C:/Users/<你>/.config/opencode/embedded.md"]
   }
   ```

3. 只想限定到某个工程树时，改为在该工程根创建或合并 `opencode.json`，写同一条 `instructions`。配置只从 cwd 向上找，所以写工程根，不写公共父目录。
4. 目标 `opencode.json` 已存在时，只追加 `instructions` 里的条目，不改其他字段；`instructions` 数组会合并，不是覆盖。
5. 无法安全合并（JSONC、格式特殊）时，输出要添加的那一行，让用户手动加。

Claude Code / Codex：

- 没有 `instructions` 文件数组时，把 `embedded.md` 复制到工程根并改名为 `AGENTS.md`（Claude 为 `CLAUDE.md`）。
- 一个父目录覆盖多个工程的做法在部分运行时不可靠，宁可每个工程根放一份。

## 第 5 步：自检

逐项确认，并把结果写进报告：

- [ ] 三个技能目录都存在，且各自有 `SKILL.md`
- [ ] 每个 `SKILL.md` 的 frontmatter 至少包含 `name` 和 `description`
- [ ] 技能 ID 与目录名一致（大小写敏感，小写 kebab-case）
- [ ] 入口规则块恰好一个，起止标记配对
- [ ] 入口规则块只包含通用规则；`>>safe`、`>>help`、归档规则应出现在 `embedded.md` 中，**不在**全局块内
- [ ] 入口规则块包含每轮技能评估（输出 `技能：<id>` 或 `技能：无`）
- [ ] 入口规则块包含手动加载说明（`@<技能ID>` 与 `>>use <短名>` 对照表）
- [ ] 审查者文件存在，或已说明该运行时不支持
- [ ] OpenCode 下审查者是 `mode: subagent`，且 `edit`/`shell` 为 `deny`（`opencode debug agents` 可查）
- [ ] `embedded.md` 已安装，且**没有**被整段合并进全局入口文件
- [ ] 全局或工程级 `opencode.json` 的 `instructions` 指向正确的绝对路径（或已说明需人工放置）
- [ ] 没有写入其他运行时的目录
- [ ] 备份目录路径已记录

## 第 6 步：报告

```markdown
## 安装报告

- 运行时：OpenCode
- 技能：3 个（列出路径）
- 审查者：<路径> / 不支持（原因）
- 入口规则：已追加 / 已替换 / 已创建（<路径>，<行数> 行）
- 嵌入式规则：<路径>；引入方式：全局 `instructions` / 工程级 `opencode.json` / 待人工放置
- 备份：<目录>（无覆盖时写“无”）
- 回滚：删除 <技能目录> 下新增目录，删除入口文件中的标记块，必要时从备份恢复
- 未完成项：<列出，没有则写“无”>
- 使用手册：<本仓库绝对路径>/使用手册.md（告诉用户这份文件的位置）
- 验证方法：发送 `>>help`，应只输出入口说明；发送 `>>safe`，应先播报成本而不是直接开始
```

## 未知运行时分支

适用于 WorkBuddy 或本文件未列出的 agent：

1. 先完成第 2 步：把 `skills/` 复制到你自己的技能目录。技能只是 Markdown，任何支持技能或指令扩展的运行时都能读取。
2. 入口规则不要猜测位置。输出一段代码如下，让用户粘贴到它的全局指令配置里：

   ```text
   请把下面两个标记之间的全部内容，追加到你的全局指令配置文件末尾：
   <!-- embedded-workflow:start v1 -->
   ...
   <!-- embedded-workflow:end -->
   ```

3. 如果不知道技能目录在哪，输出同样的代码块，让用户指定；不要写入当前项目目录冒充全局配置。
4. 在报告里注明：技能已装、入口规则待人工放置、原因是什么。

## 禁止

- 不修改 shell profile、PATH、系统环境变量。
- 不删除用户已有的技能、规则或配置。
- 不碰其他运行时的目录。
- 不在未确认目标路径时创建文件。
- 不把本仓库的 `README.md`、`install.ps1` 当成安装目标。
- 不把入口规则写进项目内的 `AGENTS.md`（那是项目级，不是全局）。
- 不把 `embedded.md` 整段并进全局入口文件（要用 `instructions` 引入，改动才不用重装）。

## 回滚

1. 技能：删除第 2 步新增的目录，或从备份目录恢复。
2. 入口规则：删除 `<!-- embedded-workflow:start v1 -->` 到 `<!-- embedded-workflow:end -->` 之间的整块。
3. 审查者：删除第 3 步复制的文件。
4. 嵌入式规则：删除全局或工程级 `opencode.json` 中对应的 `instructions` 条目（该文件只为此而生时可直接删除），再删除 `<运行时主目录>/embedded.md`。
5. 回滚后发送 `>>help`，确认不再输出入口说明。
