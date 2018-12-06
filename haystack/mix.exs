defmodule Haystack.MixProject do
  use Mix.Project

  def project do
    [
      app: :haystack,
      version: "0.1.0",
      elixir: "~> 1.7",
      escript: escript_config(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp escript_config do
    [
      main_module: CLI,
      name: "haystack"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exprof, "~> 0.2.0"},
      {:poolboy, "~> 1.5.1"}
    ]
  end
end
