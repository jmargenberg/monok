defmodule Monok.MixProject do
  use Mix.Project

  def project do
    [
      app: :monok,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      source_url: "https://github.com/jmargenberg/monok",
      docs: [main: "Monok", extras: ["README.md"]]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
