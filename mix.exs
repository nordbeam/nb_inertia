defmodule NbInertia.MixProject do
  use Mix.Project

  @version "1.0.0"
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
      extra_applications: [:logger, :inets],
      mod: {NbInertia.Application, []}
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.8", optional: true},
      # Required dependencies
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:plug, "~> 1.14"},
      {:deno_rider, "~> 0.2", optional: true},

      # Optional dependencies
      {:nb_serializer, github: "nordbeam/nb_serializer", optional: true},

      # Development and test dependencies
      # Wallaby is only used by the optional browser-test helpers. Pin the
      # last 0.30 release because 0.31 switched to HTTPoison 3/Hackney 4,
      # which pulls HTTP/3 dependencies that require OTP 26 or newer.
      # Keep it out of the package runtime; browser-test applications should
      # start Wallaby explicitly when they configure those tests.
      {:wallaby, "~> 0.30.12", only: :test, runtime: false, optional: true},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
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
      files:
        ~w(bench docs lib priv usage-rules .formatter.exs mix.exs README* LICENSE* CHANGELOG* usage-rules.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "docs/performance.md",
        "docs/page-schema-runtime.md",
        "usage-rules.md"
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
          NbInertia.TestHelpers,
          NbInertia.WallabyHelpers
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
