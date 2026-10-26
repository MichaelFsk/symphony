defmodule SymphonyElixir.CLI do
  @moduledoc """
  Escript entrypoint for running Symphony with an explicit WORKFLOW.md path.
  """

  alias SymphonyElixir.{I18n, LogFile, Workflow}

  @acknowledgement_switch :i_understand_that_this_will_be_running_without_the_usual_guardrails
  @switches [{@acknowledgement_switch, :boolean}, logs_root: :string, port: :integer, language: :string, help: :boolean]

  @type ensure_started_result :: {:ok, [atom()]} | {:error, term()}
  @type deps :: %{
          optional(:set_language_override) => (String.t() -> :ok),
          file_regular?: (String.t() -> boolean()),
          set_workflow_file_path: (String.t() -> :ok | {:error, term()}),
          set_logs_root: (String.t() -> :ok | {:error, term()}),
          set_server_port_override: (non_neg_integer() | nil -> :ok | {:error, term()}),
          ensure_all_started: (-> ensure_started_result())
        }

  @spec main([String.t()]) :: no_return()
  def main(args) do
    main(args, fn -> Application.ensure_all_started(:symphony_elixir) end)
  end

  @doc false
  @spec main([String.t()], (-> ensure_started_result())) :: no_return()
  def main(args, ensure_all_started) do
    case evaluate(args, runtime_deps(ensure_all_started)) do
      :ok ->
        wait_for_shutdown()

      {:help, message} ->
        IO.puts(message)
        System.halt(0)

      {:error, message} ->
        IO.puts(:stderr, message)
        System.halt(1)
    end
  end

  @spec evaluate([String.t()], deps()) :: :ok | {:help, String.t()} | {:error, String.t()}
  def evaluate(args, deps \\ runtime_deps()) do
    case OptionParser.parse(args, strict: @switches) do
      {opts, paths, []} when length(paths) <= 1 ->
        workflow_path = List.first(paths) || "WORKFLOW.md"
        language = Keyword.get(opts, :language) || workflow_language(workflow_path)

        cond do
          not I18n.supported?(language) ->
            {:error, I18n.t("en", "Supported languages: en, zh-CN")}

          Keyword.get(opts, :help, false) ->
            {:help, usage_message(language)}

          true ->
            start(workflow_path, opts, deps, language)
        end

      {opts, _paths, _invalid} ->
        {:error, usage_message(I18n.resolve(Keyword.get(opts, :language)))}
    end
  end

  defp start(workflow_path, opts, deps, language) do
    with :ok <- require_guardrails_acknowledgement(opts, language),
         :ok <- maybe_set_language(opts, deps),
         :ok <- maybe_set_logs_root(opts, deps, language),
         :ok <- maybe_set_server_port(opts, deps, language) do
      run(workflow_path, deps, language)
    end
  end

  defp workflow_language(workflow_path) do
    case Workflow.load(Path.expand(workflow_path)) do
      {:ok, %{config: %{"observability" => %{"language" => language}}}} -> I18n.resolve(language)
      _ -> "en"
    end
  end

  @spec run(String.t(), deps()) :: :ok | {:error, String.t()}
  def run(workflow_path, deps), do: run(workflow_path, deps, workflow_language(workflow_path))

  defp run(workflow_path, deps, language) do
    expanded_path = Path.expand(workflow_path)

    if deps.file_regular?.(expanded_path) do
      :ok = deps.set_workflow_file_path.(expanded_path)

      case deps.ensure_all_started.() do
        {:ok, _started_apps} ->
          :ok

        {:error, reason} ->
          {:error, I18n.t(language, "Failed to start Symphony with workflow %{path}: %{reason}", path: expanded_path, reason: inspect(reason))}
      end
    else
      {:error, I18n.t(language, "Workflow file not found: %{path}", path: expanded_path)}
    end
  end

  defp usage_message(language) do
    I18n.t(language, "Usage: symphony [--logs-root <path>] [--port <port>] [--language <en|zh-CN>] [path-to-WORKFLOW.md]")
  end

  @spec runtime_deps() :: deps()
  defp runtime_deps(ensure_all_started \\ fn -> Application.ensure_all_started(:symphony_elixir) end) do
    %{
      file_regular?: &File.regular?/1,
      set_workflow_file_path: &SymphonyElixir.Workflow.set_workflow_file_path/1,
      set_logs_root: &set_logs_root/1,
      set_server_port_override: &set_server_port_override/1,
      ensure_all_started: ensure_all_started,
      set_language_override: &set_language_override/1
    }
  end

  defp maybe_set_logs_root(opts, deps, language) do
    case Keyword.get_values(opts, :logs_root) do
      [] ->
        :ok

      values ->
        logs_root = values |> List.last() |> String.trim()

        if logs_root == "" do
          {:error, usage_message(language)}
        else
          :ok = deps.set_logs_root.(Path.expand(logs_root))
        end
    end
  end

  defp require_guardrails_acknowledgement(opts, language) do
    if Keyword.get(opts, @acknowledgement_switch, false) do
      :ok
    else
      {:error, acknowledgement_banner(language)}
    end
  end

  defp acknowledgement_banner(language) do
    lines = [
      "This Symphony implementation is a low key engineering preview.",
      "Codex will run without any guardrails.",
      "SymphonyElixir is not a supported product and is presented as-is.",
      "To proceed, start with `--i-understand-that-this-will-be-running-without-the-usual-guardrails` CLI argument"
    ]

    lines = Enum.map(lines, &I18n.t(language, &1))
    width = Enum.max(Enum.map(lines, &I18n.width/1))
    border = String.duplicate("─", width + 2)
    top = "╭" <> border <> "╮"
    bottom = "╰" <> border <> "╯"
    spacer = "│ " <> String.duplicate(" ", width) <> " │"

    content =
      [
        top,
        spacer
        | Enum.map(lines, fn line ->
            "│ " <> I18n.pad(line, width) <> " │"
          end)
      ] ++ [spacer, bottom]

    [
      IO.ANSI.red(),
      IO.ANSI.bright(),
      Enum.join(content, "\n"),
      IO.ANSI.reset()
    ]
    |> IO.iodata_to_binary()
  end

  defp maybe_set_language(opts, deps) do
    case Keyword.get(opts, :language) do
      nil -> :ok
      language -> Map.get(deps, :set_language_override, &set_language_override/1).(language)
    end
  end

  defp set_language_override(language) do
    Application.put_env(:symphony_elixir, :language_override, language)
    :ok
  end

  defp set_logs_root(logs_root) do
    Application.put_env(:symphony_elixir, :log_file, LogFile.default_log_file(logs_root))
    :ok
  end

  defp maybe_set_server_port(opts, deps, language) do
    case Keyword.get_values(opts, :port) do
      [] ->
        :ok

      values ->
        port = List.last(values)

        if is_integer(port) and port >= 0 do
          :ok = deps.set_server_port_override.(port)
        else
          {:error, usage_message(language)}
        end
    end
  end

  defp set_server_port_override(port) when is_integer(port) and port >= 0 do
    Application.put_env(:symphony_elixir, :server_port_override, port)
    :ok
  end

  @spec wait_for_shutdown() :: no_return()
  defp wait_for_shutdown do
    case Process.whereis(SymphonyElixir.Supervisor) do
      nil ->
        IO.puts(:stderr, I18n.t(SymphonyElixir.Config.language(), "Symphony supervisor is not running"))
        System.halt(1)

      pid ->
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, :process, ^pid, reason} ->
            case reason do
              :normal -> System.halt(0)
              _ -> System.halt(1)
            end
        end
    end
  end
end
