# 统一工作流维护仓库

本目录是嵌入式开发、学术论文写作与仿真、面试准备、面试录音复盘和全局协作规则的唯一维护源。`C:\Users\...\.codex` 中的技能和 `AGENTS.md` 都是安装副本；修改应先在本目录完成，再运行安装脚本同步。

## 当前内容

| 路径 | 用途 |
| --- | --- |
| `skills/embedded-project-dev-style` | STM32、MCU、裸机、RTOS、驱动和调试的开发协作规范 |
| `skills/embedded-change-archive` | 功能完成后归档到项目内 `更新记录/`，含差异表、四档证据和复习卡 |
| `skills/embedded-impact-verify` | 改前查影响面，改后按静态/编译/下载/运行四档交证据 |
| `skills/academic-voice` | 英文学术写作：用词、句式、标点、缩写、文献回顾、图题、公式排版、五页篇幅 |
| `skills/academic-sim-run` | MATLAB 论文仿真：代码形态、并行池、无人值守、复现、出图与结果归档 |
| `skills/academic-audit` | 按 PDF 独立评阅论文，输出带位置和分级的问题清单 |
| `skills/interview-round-prep` | 按一面、二面、终面和HR面组织面试准备 |
| `skills/interview-record-review` | 面试录音/逐字稿的完整问答、追问、反问和改进复盘 |
| `global/AGENTS.md` | 全局协作规则：通用行为、模式开关、归档规则、技能索引，所有任务生效 |
| `global/embedded.md` | 嵌入式专项规则：STM32/MCU/RTOS 基调、ISR/DMA 上下文、编码与配置核对，默认全局常驻 |
| `global/academic.md` | 学术任务层：判域、先方案门禁、方向锚点、按目的取规则、学术锚点，默认全局常驻 |
| `agents/embedded-reviewer.md` | 只读审查者提示词，保险模式收口时使用 |
| `agents/academic-reviewer.md` | 学术只读审稿者提示词，检查改动是否偏离方向锚点 |
| `README-INSTALL.md` | 给其他 AI 的自安装说明，含未知运行时的降级方式 |
| `使用手册.md` | 面向人：四层结构、每个技能怎么用、速查表、常见问题 |

具体项目代码、录音、简历和个人背景资料不放入此仓库，避免把大文件、隐私和临时材料提交到 Git。

## 工作流概览

两种模式，默认正常流程。**保险模式和归档由 `global/embedded.md` 定义；安装时默认全局常驻，也可以用 `-EmbeddedRoot` 限定到指定工程树。**

| | 正常流程（默认） | 保险模式（成本较高） |
| --- | --- | --- |
| 进入 | 直接描述需求 | 发 `>>safe`，我报成本后回 `>>go` |
| 谁写代码 | 用户 | AI |
| 审查 | AI 审用户的 diff | 只读审查者，只给 diff + 范围声明 + 验收标准 |
| 适用 | 单点改动、调试、想自己搞懂的模块 | 批量改动、跨文件重构、不想逐行看的改动 |

退出保险模式：`<<safe`、说“退出”、任务收尾，或连续两次范围外改动。

入口说明随时可用 `>>help` 查看，不消耗额度。

技能评估：每轮回复第一行会写 `技能：<id>` 或 `技能：无`，表示这轮判断过要不要加载技能；说“别显示技能”可关闭无匹配时的输出。

归档：一个功能完成、证据齐、短时间不再改动时，AI 提醒一次；用户说“归档”后，AI **先出归档方案等确认**，再写入项目根 `更新记录/YYYY-MM-DD_主题.md`。

各运行时的安装方式见 [README-INSTALL.md](README-INSTALL.md)；规则与技能的正文不写运行时专有工具名，差异只在安装时处理。

### 规则分层

只把跨领域的东西放全局；嵌入式规则和学术规则各自单独成文件，安装时默认写进全局 `opencode.json` 的 `instructions`，所有目录常驻。不想让嵌入式规则占用非嵌入式任务的上下文时，用 `-EmbeddedRoot` 改成只在指定工程树生效。

学术规则靠 `global/academic.md` 的「进入判据 + 不适用即沉默」自我隔离：非学术任务不读、不引用它，所以常驻不冲突。

| 层 | 文件 | 内容 | 生效范围 | 每轮都在？ |
| --- | --- | --- | --- | --- |
| 全局规则 | `global/AGENTS.md` | 通用行为、文档规范、四条硬约束、技能索引 | 所有任务 | 是 |
| 嵌入式规则 | `global/embedded.md` | 工程规则、保险模式、每轮三行、入口提示、归档 | 默认全局；可用 `-EmbeddedRoot` 限定 | 是（全局时） |
| 学术规则 | `global/academic.md` | 判域、先方案门禁、方向锚点、按目的取规则 | 默认全局；非学术任务不启用 | 是（全局时） |
| 技能正文 | `skills/*/SKILL.md` | 具体流程 | 匹配时加载，任意目录 | 否 |
| 审查者 | `agents/*.md` | 只读审查 | 被派发时 | 否 |

OpenCode 的两种引入方式：

1. **全局常驻（默认）**：安装脚本把 `<安装根>/embedded.md`、`<安装根>/academic.md` 的绝对路径追加到 `~/.config/opencode/opencode.json`（只追加实际存在的文件）：

   ```jsonc
   {
     "$schema": "https://opencode.ai/config.json",
     "instructions": [
       "C:/Users/<你>/.config/opencode/embedded.md",
       "C:/Users/<你>/.config/opencode/academic.md"
     ]
   }
   ```

   任意目录启动都会加载；修改规则文件后不需要重装。

2. **限定工程树**：`-EmbeddedRoot <工程根>` 会在该目录写 `opencode.json`。配置只从 cwd 向上找，所以要写在实际工程根，不要写公共父目录（会污染兄弟目录）。

Claude Code 和 Codex 没有等价的 `instructions` 文件数组时，把 `embedded.md` 复制到工程根并改名为 `AGENTS.md`（Claude 为 `CLAUDE.md`）。

## 安装和同步

新机器拿到仓库后，一条命令即可（自动识别运行时）：

```powershell
.\bootstrap.ps1 -Force
.\bootstrap.ps1 -Verify
```

只想在指定工程树生效时，再加上 `-EmbeddedRoot`：

```powershell
.\bootstrap.ps1 -EmbeddedRoot 'D:\你的嵌入式工程根' -Force
.\bootstrap.ps1 -Verify -EmbeddedRoot 'D:\你的嵌入式工程根'
```

也可以直接调用安装脚本：

```powershell
# 一次装齐：技能 + 审查者 + 全局规则 + 嵌入式规则 + 学术规则 + 使用手册
.\install.ps1 -Full -Runtime opencode
.\install.ps1 -Full -Runtime codex
.\install.ps1 -Full -Runtime claude

# 指定任意目录（旧用法仍有效）
.\install.ps1 -All -InstallGlobalRules -Force
.\install.ps1 -Destination 'D:\your-codex\skills' -All
.\install.ps1 -SkillName interview-record-review -Force
```

`-Full` 等价于 `-All -Agents -Manual -EmbeddedRules -AcademicRules -InstallGlobalRules`，装到 OpenCode 时还会自动加 `-EmbeddedGlobal`。各参数的作用：

| 参数 | 装什么 | 装到哪 |
| --- | --- | --- |
| `-All` / `-SkillName` | 技能 | `<Destination>/<技能名>/` |
| `-Agents` | `agents/*.md` | `<安装根>/agents/`（OpenCode 自动补 frontmatter，装成只读 subagent） |
| `-InstallGlobalRules` | `global/AGENTS.md` | `<安装根>/AGENTS.md`（Claude 为 `CLAUDE.md`） |
| `-EmbeddedRules` | `global/embedded.md` | `<安装根>/embedded.md` |
| `-AcademicRules` | `global/academic.md` | `<安装根>/academic.md` |
| `-EmbeddedGlobal` | 全局 `instructions` | `<安装根>/opencode.json` 追加已安装规则文件的绝对路径（`embedded.md`、`academic.md`） |
| `-EmbeddedRoot` | 目录级 `opencode.json` | `<EmbeddedRoot>/opencode.json` |
| `-Manual` | `使用手册.md` | `<安装根>/使用手册.md` |
| `-Verify` | 只比对、不写入，有差异时退出码 1 | — |

只想让嵌入式规则在某个工程树生效时，加 `-EmbeddedRoot`（会覆盖默认的全局常驻）：

```powershell
.\install.ps1 -Full -Runtime opencode -EmbeddedRoot '<这台机器上的嵌入式工程根>'
```

`<安装根>` 是技能目录的上一级，由 `-Runtime` 决定：OpenCode 为 `~/.config/opencode`，Codex 为 `~/.codex`，Claude 为 `~/.claude`。

不带 `-Force` 时，脚本不会覆盖已有技能、审查者、规则或手册；内容一致时跳过并提示已是最新。脚本不删除安装目录中的其他文件，也不自动删除已改名的旧资源。

> Codex 是否识别自定义子代理尚未核实。装了 `agents/` 但没生效时，改用新会话方式：只贴 diff、范围声明、验收标准和 `agents/embedded-reviewer.md` 全文。

## 修改入口：改仓库，不改副本

**仓库是唯一真源，安装目录里的都是副本。** 直接改 `~/.config/opencode/AGENTS.md` 之类的副本，下次重装会被覆盖，也不会进 Git。

### 标准循环

```powershell
# 1. 改仓库里的文件（global/、skills/、agents/、使用手册.md）

# 2. 看看本机和仓库差在哪（只读，不改任何东西）
.\install.ps1 -Full -Runtime opencode -EmbeddedRoot 'E:\xieyiyi\gz\stm32' -Verify

# 3. 确认后重装
.\install.ps1 -Full -Runtime opencode -EmbeddedRoot 'E:\xieyiyi\gz\stm32' -Force

# 4. 实际试一次（>>help / >>safe / 说"归档"），再提交
git add -A
git commit -m "workflow: ..."
git push
```

`-Verify` 会逐个比对技能目录、审查者、规则、手册和目录级配置，输出：

```
OK       skills/embedded-impact-verify
DRIFT    embedded.md
MISSING  agents/embedded-reviewer.md
EXTRA    skills/old-skill（安装目录有，仓库没有）
```

有差异时退出码为 1，可以直接用在脚本或 CI 里。

### 多台机器

| 场景 | 操作 |
| --- | --- |
| 新机器 | `git clone` → `install.ps1 -Full -Runtime ... -Force` → `-Verify` |
| 老机器同步 | `git pull` → `-Verify` 看差异 → `-Force` 重装 |
| 两台都改了 | 先 `git pull` 解决冲突，再重新 `-Force` 重装；不要手工合并安装副本 |
| 只想确认状态 | `-Verify`，只读 |

### 覆盖前会备份

`-Force` 覆盖内容不同的文件或技能目录时，会先把旧内容复制到：

```
<安装根>\.backup\YYYYMMDD-HHMMSS\
```

按相对路径保留，例如 `.backup\20261020-215139\skills\embedded-impact-verify\SKILL.md`。确认无误后可自行删除旧备份。

### 路径说明

全局 `instructions` 和目录级 `opencode.json` 指向的都是**安装副本**（如 `C:/Users/Admin/.config/opencode/embedded.md`），不是仓库路径。这样换机器、挪仓库都不会失效；代价是改完仓库要重装一次才生效——这正是 `-Verify` 存在的意义。

## 维护要求

- 新技能使用小写字母、数字和连字符命名，必须有 `SKILL.md`；需要界面元数据时添加 `agents/openai.yaml`。
- 先判断是否应更新已有技能，再新建目录；详细模板和规则放 `references/`，避免入口文件过长。
- 内容区分已验证事实、代码推断和待确认结论，不把某个项目的参数推广为通用事实。
- 修改后运行 `skill-creator` 的 `quick_validate.py`，并做一次不写入真实工程的可控试用。
