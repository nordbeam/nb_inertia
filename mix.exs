defmodule NbInertia.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/nordbeam/nb_inertia"

  def project do
    [
      app: :nb_inertia,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      name: "NbInertia",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NbInertia.Application, []}
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.6", only: [:dev, :test]},
      # Required dependencies
      {:inertia, "~> 2.0"},
      {:phoenix, "~> 1.7"},
      {:plug, "~> 1.14"},
      {:deno_rider, "~> 0.2"},

      # Optional dependencies
      {:nb_serializer, path: "/Users/assim/Projects/nb_serializer", optional: true},

      # Development and test dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:stream_data, "~> 1.0", only: [:test, :dev]},
      {:jason, "~> 1.4"},
      {:ecto, "~> 3.10"}
    ]
  end

  defp description do
    """
    Advanced Inertia.js integration for Phoenix with declarative page DSL,
    type-safe props, shared props, and optional NbSerializer support.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/nb_inertia"
      },
      maintainers: ["assim"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md"
      ],
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
