defmodule SymphonyElixir.I18nTest do
  use ExUnit.Case, async: true

  alias SymphonyElixir.{Config.Schema, I18n}

  test "English is the default and unsupported languages fall back without creating atoms" do
    assert I18n.languages() == ["en", "zh-CN"]
    assert I18n.supported?("en")
    assert I18n.supported?("zh-CN")
    refute I18n.supported?("fr")
    refute I18n.supported?(nil)
    assert I18n.resolve("zh-CN") == "zh-CN"
    assert I18n.resolve("fr") == "en"
    assert I18n.resolve(nil, "zh-CN") == "zh-CN"
    assert I18n.t("en", "Running") == "Running"
    assert I18n.t("zh-CN", "Running") == "运行中"
    assert I18n.t("zh-CN", "external diagnostic") == "external diagnostic"
    assert I18n.t("fr", "Running") == "Running"
    assert I18n.t("zh-CN", "attempt=%{attempt}", attempt: 2) == "第 2 次"
    assert I18n.t("en", "attempt=%{attempt}", attempt: 2) == "attempt=2"
  end

  test "workflow language is validated with an English default" do
    assert {:ok, settings} = Schema.parse(%{})
    assert settings.observability.language == "en"
    assert {:ok, settings} = Schema.parse(%{"observability" => %{"language" => nil}})
    assert settings.observability.language == "en"
    assert {:error, _} = Schema.parse(%{"observability" => %{"language" => ""}})
    assert {:ok, settings} = Schema.parse(%{"observability" => %{"language" => "zh-CN"}})
    assert settings.observability.language == "zh-CN"
    assert {:error, {:invalid_workflow_config, message}} = Schema.parse(%{"observability" => %{"language" => "fr"}})
    assert message =~ "observability.language"
  end

  test "terminal cells account for Chinese width without breaking graphemes" do
    assert I18n.width("") == 0
    assert I18n.width("运行中") == 6
    assert I18n.width("é") == 1
    assert I18n.width("✅") == 2
    assert I18n.width("👨‍👩‍👧‍👦") == 2
    assert I18n.width("🇨🇳") == 2
    assert I18n.width("☀️") == 2
    assert I18n.width("1️⃣") == 2
    assert I18n.pad("✅正常", 8) == "✅正常  "
    assert I18n.truncate("👨‍👩‍👧‍👦正常", 5) == "👨‍👩‍👧‍👦..."
    assert I18n.pad("状态", 8) == "状态    "
    assert I18n.pad("状态", 8, :right) == "    状态"
    assert I18n.pad("状态", 2) == "状态"
    assert I18n.truncate("状态正常", 7) == "状态..."
    assert I18n.truncate("状态", 4) == "状态"
    assert I18n.truncate("状态", 2) == ".."
    assert I18n.truncate("状态", 0) == ""
  end
end
