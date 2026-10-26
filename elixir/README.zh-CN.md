# Symphony Elixir

[English](README.md) | [简体中文](README.zh-CN.md)

本目录是依据仓库根目录 [SPEC.md](../SPEC.md) 实现的 Elixir/OTP 参考版本。
本手册说明本 fork 的运行方式与中英文切换；更详细的各 tracker 配置和错误类型见
[英文参考手册](README.md)。配置键、协议字段与命令名在两种语言下相同。

> [!WARNING]
> 本参考实现用于评估。正式使用前应根据项目要求完善凭据、执行权限、网络、工作区和验收策略。

## 工作流程

1. 轮询已配置的任务系统，内置 Linear、GitHub Issues、Jira Cloud、Asana 和 GitLab 适配。
2. 为每个任务建立独立工作区。
3. 在工作区启动 Codex app-server，传入项目定义的工作提示。
4. 依据任务状态继续执行、等待输入、重试或停止。
5. 通过终端看板、Web 看板和 JSON API 观察运行状态。

任务进入终态后，调度器停止对应代理并清理匹配的工作区。
需要保留交付产物的部署应先制定归档流程。
代理要求操作员输入、审批或 MCP 补充信息时，任务会保持领取并显示为阻塞。
当前阻塞映射只保存在内存中，重启后仍处于活动状态的任务可能再次成为候选。

选中的 tracker 可以向代理提供对应工具：`linear_graphql`、`github_api`、`jira_rest`、
`asana_api` 或 `gitlab_api`。这些工具由宿主使用配置的认证执行；
原生实现会从 Codex 子进程环境中移除该适配器声明的 tracker token 变量。
权限范围仍由账号及服务端配置决定。

## 环境准备

推荐使用 [mise](https://mise.jdx.dev/) 管理 Elixir 和 Erlang 版本。
版本约束以本目录的 `mise.toml` 和 `mix.exs` 为准。

```bash
git clone https://github.com/MichaelFsk/symphony
cd symphony/elixir
mise trust
mise install
mise exec -- elixir --version
mise exec -- mix setup
mise exec -- mix build
```

将本目录的 `WORKFLOW.md` 复制到目标项目，填写 tracker 目标、工作区、准备步骤和代理提示。
示例文件可能引用自定义任务状态，应按自身看板调整。

## 启动

```bash
mise exec -- ./bin/symphony /absolute/project/WORKFLOW.md --language zh-CN
```

未传流程文件时读取当前目录的 `WORKFLOW.md`。项目相关相对路径按流程文件所在目录解释。

常用参数：

- `--language en` / `--language zh-CN`：覆盖本进程的默认界面语言。
- `--logs-root /absolute/logs`：日志目录。
- `--port 4000`：启用 Phoenix Web 看板和 JSON API。

保持项目指引、执行范围与验收要求在项目内定义。源代码存在、服务启动或代理正常退出，
都不能单独证明业务任务已经完成验收。

## 语言设置

默认语言为英文。在 `WORKFLOW.md` 的 YAML 配置区设置简体中文：

```yaml
observability:
  language: zh-CN
```

也可以只为本次启动覆盖：

```bash
./bin/symphony ./WORKFLOW.md --language zh-CN --port 4000
./bin/symphony ./WORKFLOW.md --language en --port 4000
```

Web 看板顶部提供 **English** 和 **简体中文** 链接，分别使用 `?lang=en` 与 `?lang=zh-CN`。
选择只作用于当前访问请求及其 LiveView 会话，不修改其他访问者或服务进程的默认语言。
已连接的会话保留打开时的语言；刷新页面后，新请求才采用最新配置的默认语言。
浏览器传入未支持的语言时回退到配置的默认语言；配置文件或 CLI 中的无效语言会校验失败。

界面语言覆盖导航、标签、命令行展示和可访问性文字。
任务标题和描述、tracker 状态原值、代理输出、路径以及诊断错误载荷保持原样。
JSON API 的字段和值保持协议定义，工作流提示正文也不会自动翻译。

## 项目配置

流程文件由 YAML front matter 与 Markdown 任务提示组成，例如：

```markdown
---
tracker:
  kind: linear
  provider:
    project_slug: "your-project"
    api_key: $LINEAR_API_KEY
workspace:
  root: /absolute/workspaces
hooks:
  after_create: |
    git clone git@github.com:your-org/your-project.git .
agent:
  max_concurrent_agents: 2
  max_turns: 20
observability:
  language: zh-CN
codex:
  command: codex app-server
---

处理任务 {{ issue.identifier }}。
标题：{{ issue.title }}
任务内容：{{ issue.description }}
```

`tracker.kind` 选择适配器；站点、项目和认证引用放在 `tracker.provider`。
`tracker.required_labels`、`active_states` 和 `terminal_states` 位于 `tracker` 下。
未填写的值使用各自默认值。所选适配器仍需具备真实的凭据与目标资源权限。

密钥应通过环境变量引用提供，避免明文写进代理可读的流程文件。
原生 tracker 工具的权限取决于其账号；项目过滤条件不能自动限制所有原始 API 工具调用。

配置未显式指定时，Codex 使用较保守的审批拒绝策略以及 `workspace-write` 沙箱。
具体可用的审批和沙箱字段以使用中的 Codex app-server 协议版本为准。
`codex.turn_timeout_ms` 是流式更新的最大静默时间，不是整个任务的总时长限制；
`agent.max_turns` 限定单次代理运行中连续执行的轮数。

启动时找不到流程文件或 YAML 无效，服务会失败。
运行期间重新加载配置失败时，服务继续使用最后有效配置并记录错误。

## 看板和 API

启用 `--port` 后提供：

- `/`：Phoenix LiveView 看板，支持语言切换。
- `/api/v1/state`：调度器状态。
- `/api/v1/<issue_identifier>`：指定任务状态。
- `/api/v1/refresh`：请求刷新。

API 字段不随界面语言改变。错误原文和任务内容会按来源显示，便于跨语言排查。

## 自包含发行包

上游使用 [Burrito](https://github.com/burrito-elixir/burrito) 构建包含 Erlang、Elixir 和 Symphony
的可执行文件，支持 macOS 与 Linux 的 ARM64、x86_64。
目标机器仍需准备 Codex、Git 和 tracker 账号。

本 fork 的语言改动需要由包含这些提交的源码构建或对应发行包提供。
从上游下载的旧二进制不会自动获得本 fork 的语言切换功能。
发布说明、源提交和校验和应匹配实际运行文件。

## 开发验证

```bash
mix format --check-formatted
mix specs.check
mix test
```

完整检查入口以 [Makefile](Makefile) 为准：

```bash
make all
```

测试和代码检查不代替真实账号、真实模型、部署保护和业务验收。
更多 tracker 配置、错误约定和扩展信息参阅 [英文参考手册](README.md)。

## 许可证

采用 [Apache License 2.0](../LICENSE)，并保留 [NOTICE](../NOTICE) 中的来源声明。
