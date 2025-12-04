defmodule NbInertia.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/nordbeam/nb_inertia"

  def project do
    [
      app: :nb_inertia,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      name: "NbInertia",
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def cli do
    [
      preferred_envs: [
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
      {:igniter, "~> 0.7", optional: true},
      # Required dependencies
      {:inertia, "~> 2.0"},
      {:phoenix, "~> 1.7"},
      {:plug, "~> 1.14"},
      {:deno_rider, "~> 0.2", optional: true},
      {:poolboy, "~> 1.5"},

      # Optional dependencies
      {:nb_serializer, github: "nordbeam/nb_serializer", optional: true},
      {:req, "~> 0.5", optional: true},

      # Development and test dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", optional: true, runtime: false},
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
      formatters: ["html"],
      groups_for_modules: [
        Core: [
          NbInertia,
          NbInertia.Controller,
          NbInertia.CoreController
        ],
        Configuration: [
          NbInertia.Config,
          NbInertia.Application
        ],
        "Shared Props": [
          NbInertia.SharedProps
        ],
        "Server-Side Rendering": [
          NbInertia.SSR,
          NbInertia.SSR.RenderError
        ],
        Testing: [
          NbInertia.TestHelpers
        ],
        Utilities: [
          NbInertia.ComponentNaming,
          NbInertia.DeepMerge,
          NbInertia.ParamsConverter,
          NbInertia.HTML
        ],
        Telemetry: [
          NbInertia.Telemetry
        ],
        Protocols: [
          NbInertia.PropSerializer
        ],
        "Lazy Evaluation": [
          NbInertia.LazyProps
        ]
      ]
    ]
  end
end
