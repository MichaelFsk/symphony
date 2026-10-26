defmodule SymphonyElixir.I18n do
  @moduledoc """
  Small, explicit catalog for operator-facing text. Tracker data, agent output, log
  records and JSON API contracts are never translated.
  """

  @languages ["en", "zh-CN"]
  @zh_cn %{
    "Symphony Observability" => "Symphony 运行监控",
    "Operations Dashboard" => "运行控制台",
    "Current state, retry pressure, token usage, and orchestration health for the active Symphony runtime." => "查看当前 Symphony 的任务状态、重试压力、Token 用量和调度健康状况。",
    "Live" => "在线",
    "Offline" => "离线",
    "Snapshot unavailable" => "无法获取快照",
    "Snapshot timed out" => "获取快照超时",
    "Running" => "运行中",
    "Active issue sessions in the current runtime." => "当前运行实例中正在执行的任务会话。",
    "Retrying" => "等待重试",
    "Issues waiting for the next retry window." => "等待下一次重试的任务。",
    "Blocked" => "已阻塞",
    "Issues paused for operator input or approval." => "等待人工输入或批准的任务。",
    "Total tokens" => "Token 总量",
    "Runtime" => "运行时长",
    "Total Codex runtime across completed and active sessions." => "已完成和正在执行的 Codex 会话的累计运行时长。",
    "Rate limits" => "用量限制",
    "Latest upstream rate-limit snapshot, when available." => "上游服务最近提供的用量限制快照。",
    "Running sessions" => "运行中的会话",
    "Active issues, last known agent activity, and token usage." => "正在执行的任务、最近的 Agent 活动和 Token 用量。",
    "No active sessions." => "当前没有运行中的会话。",
    "Issue" => "任务",
    "State" => "状态",
    "Session" => "会话",
    "Runtime / turns" => "时长 / 轮次",
    "Codex update" => "Codex 更新",
    "Tokens" => "Token 用量",
    "JSON details" => "JSON 详情",
    "Copy ID" => "复制 ID",
    "Copied" => "已复制",
    "Total:" => "总计：",
    "In" => "输入",
    "Out" => "输出",
    "Blocked sessions" => "阻塞的会话",
    "Issues paused because Codex requested operator input or approval." => "因 Codex 请求人工输入或批准而暂停的任务。",
    "No blocked sessions." => "当前没有阻塞的会话。",
    "Blocked at" => "阻塞时间",
    "Last update" => "最近更新",
    "Error" => "错误",
    "Retry queue" => "重试队列",
    "No issues are currently backing off." => "当前没有等待重试的任务。",
    "Attempt" => "重试次数",
    "Due at" => "计划时间",
    "Open %{identifier} in the issue tracker" => "在任务跟踪器中打开 %{identifier}",
    "Language" => "语言",
    "SYMPHONY STATUS" => "SYMPHONY 状态",
    "app_status=offline" => "应用状态=离线",
    "Agents" => "执行器",
    "Throughput" => "吞吐量",
    "Tokens:" => "Token：",
    "total %{tokens}" => "总计 %{tokens}",
    "credits %{balance}" => "额度 %{balance}",
    "Rate Limits" => "用量限制",
    "Backoff queue" => "重试队列",
    "Orchestrator snapshot unavailable" => "无法获取调度器快照",
    "Project" => "项目",
    "Dashboard" => "控制台",
    "Next refresh" => "下次刷新",
    "checking now…" => "正在检查…",
    "No active agents" => "当前没有运行中的执行器",
    "No queued retries" => "当前没有等待重试的任务",
    "ID" => "ID",
    "STAGE" => "阶段",
    "PID" => "PID",
    "AGE / TURN" => "时长 / 轮次",
    "TOKENS" => "TOKEN",
    "SESSION" => "会话",
    "EVENT" => "事件",
    "unavailable" => "不可用",
    "primary" => "主要",
    "secondary" => "次要",
    "credits n/a" => "额度未知",
    "credits unlimited" => "额度不限",
    "credits available" => "有可用额度",
    "credits none" => "无可用额度",
    "remaining" => "剩余",
    "limit" => "限额",
    "reset" => "重置",
    "attempt=%{attempt}" => "第 %{attempt} 次",
    " in " => " 等待 ",
    "error=%{error}" => "错误=%{error}",
    "Usage: symphony [--logs-root <path>] [--port <port>] [--language <en|zh-CN>] [path-to-WORKFLOW.md]" => "用法：symphony [--logs-root <路径>] [--port <端口>] [--language <en|zh-CN>] [WORKFLOW.md 路径]",
    "Supported languages: en, zh-CN" => "支持的语言：en、zh-CN",
    "Workflow file not found: %{path}" => "找不到工作流文件：%{path}",
    "Failed to start Symphony with workflow %{path}: %{reason}" => "无法使用工作流 %{path} 启动 Symphony：%{reason}",
    "This Symphony implementation is a low key engineering preview." => "此 Symphony 实现为早期工程预览版。",
    "Codex will run without any guardrails." => "Codex 将在没有常规防护措施的情况下运行。",
    "SymphonyElixir is not a supported product and is presented as-is." => "SymphonyElixir 按原样提供，不属于受支持的产品。",
    "To proceed, start with `--i-understand-that-this-will-be-running-without-the-usual-guardrails` CLI argument" =>
      "若要继续，请在启动时添加 `--i-understand-that-this-will-be-running-without-the-usual-guardrails` 参数",
    "Symphony supervisor is not running" => "Symphony 监督进程未运行"
  }

  @spec languages() :: [String.t()]
  def languages, do: @languages

  @spec supported?(term()) :: boolean()
  def supported?(language), do: language in @languages

  @spec resolve(term(), String.t()) :: String.t()
  def resolve(language, fallback \\ "en") do
    if supported?(language), do: language, else: fallback
  end

  @spec t(String.t(), String.t(), keyword()) :: String.t()
  def t(language, message, bindings \\ []) do
    translated = if language == "zh-CN", do: Map.get(@zh_cn, message, message), else: message

    Enum.reduce(bindings, translated, fn {key, value}, text ->
      String.replace(text, "%{#{key}}", to_string(value))
    end)
  end

  @doc "Terminal cell width for Latin, CJK and emoji graphemes used in dashboard cells."
  @spec width(String.t()) :: non_neg_integer()
  def width(text), do: text |> String.graphemes() |> Enum.map(&grapheme_width/1) |> Enum.sum()

  @spec pad(String.t(), non_neg_integer(), :left | :right) :: String.t()
  def pad(text, cells, align \\ :left) do
    padding = String.duplicate(" ", max(cells - width(text), 0))
    if align == :right, do: padding <> text, else: text <> padding
  end

  @spec truncate(String.t(), non_neg_integer()) :: String.t()
  def truncate(text, cells) do
    if width(text) <= cells do
      text
    else
      prefix = take_cells(text, max(cells - 3, 0))

      prefix <> String.duplicate(".", min(cells, 3))
    end
  end

  defp take_cells(text, cells) do
    {prefix, _width} =
      text
      |> String.graphemes()
      |> Enum.reduce_while({"", 0}, &append_cell(&1, &2, cells))

    prefix
  end

  defp append_cell(grapheme, {prefix, width}, cells) do
    next_width = width + grapheme_width(grapheme)

    if next_width <= cells do
      {:cont, {prefix <> grapheme, next_width}}
    else
      {:halt, {prefix, width}}
    end
  end

  defp grapheme_width(<<codepoint::utf8, _rest::binary>> = grapheme) do
    if wide_codepoint?(codepoint) or Regex.match?(~r/\p{Emoji_Presentation}|\x{FE0F}|\x{20E3}/u, grapheme),
      do: 2,
      else: 1
  end

  defp wide_codepoint?(codepoint) do
    codepoint in 0x2E80..0xA4CF or codepoint in 0xAC00..0xD7A3 or
      codepoint in 0xF900..0xFAFF or codepoint in 0xFE10..0xFE6F or
      codepoint in 0xFF01..0xFF60 or codepoint in 0xFFE0..0xFFE6 or
      codepoint in 0x20000..0x3FFFF
  end
end
