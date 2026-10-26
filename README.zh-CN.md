# Symphony

[English](README.md) | [简体中文](README.zh-CN.md)

Symphony 将项目任务转化为相互隔离、可自主推进的实现过程，让团队通过管理工作事项来组织开发。

[![Symphony 演示视频](.github/media/symphony-demo-poster.jpg)](https://player.vimeo.com/video/1186371009?h=5626e4b899)

[演示视频](https://player.vimeo.com/video/1186371009?h=5626e4b899)展示了 Symphony 持续读取 Linear 看板，
为任务启动代理，并提供 CI 状态、PR 评审反馈、复杂度分析和演示视频等工作证据的流程。
示例流程在任务获准后完成 PR 合入；具体权限和交付规则由各项目的工作流定义。

> [!WARNING]
> Symphony 是面向可信环境的工程预览版本。参考实现仍需根据部署环境完善运行保护和验收。

## 运行方式

### 项目准备

Symphony 适用于已为代理建立清晰指引、验证命令和开发边界的项目。
有关理念请参阅 [Harness engineering](https://openai.com/index/harness-engineering/)。

### 按规范实现

可依据仓库中的 [SPEC.md](SPEC.md) 实现适合自身环境的版本。该规范描述调度、任务状态、
工作区生命周期、重试和工作流配置约定；配置字段和协议标识保持英文，便于兼容现有工具。

### 使用 Elixir 参考实现

参阅 [简体中文运行手册](elixir/README.zh-CN.md) 或 [English guide](elixir/README.md)，
安装依赖并在自己的项目中配置 `WORKFLOW.md`。本 fork 的地址为
[MichaelFsk/symphony](https://github.com/MichaelFsk/symphony)，
上游项目为 [openai/symphony](https://github.com/openai/symphony)。

## 中英文切换

参考实现提供英文（`en`，默认）和简体中文（`zh-CN`）界面。
可以通过项目 `WORKFLOW.md` 中的 `observability.language` 设置默认语言，
或在启动时传入 `--language zh-CN` / `--language en`。
Web 看板提供 **English / 简体中文** 切换入口，每个访问者独立选择。

语言设置覆盖界面和命令行展示；任务内容、任务状态原值、代理输出及协议字段保持原样。
详细范围和示例见 [语言设置](elixir/README.zh-CN.md#语言设置)。

## 许可证

本项目采用 [Apache License 2.0](LICENSE)，来源声明见 [NOTICE](NOTICE)。
