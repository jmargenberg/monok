defmodule Monok.MixProject do
  use Mix.Project

  def project do
    [
      app: :monok,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],

      # Docs
      source_url: "https://github.com/jmargenberg/monok",
      docs: [main: "Monok", extras: ["README.md"]],
      description:
        "Alternative pipe operators for clean handling of `{:ok, value}` and `{:error, reason}` tuples.",
      package: package()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jmargenberg/monok"}
    ]
  end
end
