defmodule Mix.Tasks.Nb.Setup.CredoTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Nb.Setup.Credo

  describe "update_mix_exs_for_credo_dep/1" do
    test "adds Credo to a literal deps list" do
      source = """
      defmodule Demo.MixProject do
        use Mix.Project

        def project do
          []
        end

        defp deps do
          [
            {:phoenix, "~> 1.8"}
          ]
        end
      end
      """

      assert {:ok, updated, :added} = Credo.update_mix_exs_for_credo_dep(source)
      assert updated =~ "{:credo, \"~> 1.7\", only: [:dev, :test], runtime: false}"
      assert updated =~ "{:phoenix, \"~> 1.8\"}"
    end

    test "keeps mix.exs unchanged when Credo is already present" do
      source = """
      defmodule Demo.MixProject do
        use Mix.Project

        def project do
          []
        end

        defp deps do
          [
            {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
            {:phoenix, "~> 1.8"}
          ]
        end
      end
      """

      assert {:ok, ^source, :already_present} = Credo.update_mix_exs_for_credo_dep(source)
    end
  end

  describe "recommended_check_entries/1" do
    test "returns only nb_inertia checks when nb_serializer is not installed" do
      modules =
        [:nb_inertia]
        |> Credo.recommended_check_entries()
        |> Enum.map(&elem(&1, 0))

      assert NbInertia.Credo.Check.Warning.UseNbInertiaController in modules
      assert NbInertia.Credo.Check.Warning.MissingMount in modules
      refute NbSerializer.Credo.Check.Warning.MissingDatetimeFormat in modules
      assert length(modules) == length(Enum.uniq(modules))
    end

    test "includes nb_serializer checks when nb_serializer is installed" do
      modules =
        [:nb_inertia, :nb_serializer]
        |> Credo.recommended_check_entries()
        |> Enum.map(&elem(&1, 0))

      assert NbInertia.Credo.Check.Warning.UseNbInertiaController in modules
      assert NbSerializer.Credo.Check.Warning.MissingDatetimeFormat in modules
      assert NbSerializer.Credo.Check.Design.LargeSchema in modules
    end
  end

  describe "recommended_require_patterns/3" do
    test "returns current-app and dependency require globs for supported nb libraries" do
      cwd = File.cwd!()

      patterns =
        Credo.recommended_require_patterns(
          [:nb_inertia, :nb_serializer],
          %{nb_serializer: Path.expand("../nb_serializer", cwd)},
          cwd
        )

      assert "lib/nb_inertia/credo/check/**/*.ex" in patterns
      assert "../nb_serializer/lib/nb_serializer/credo/check/**/*.ex" in patterns
    end
  end

  describe "sync_nb_checks/2" do
    test "preserves existing options for desired checks and removes stale nb checks from list configs" do
      config = %{
        configs: [
          %{
            checks: [
              {Credo.Check.Readability.ModuleDoc, []},
              {NbInertia.Credo.Check.Warning.UseNbInertiaController, [priority: :high]},
              {NbSerializer.Credo.Check.Warning.MissingDatetimeFormat, [priority: :low]}
            ]
          }
        ]
      }

      desired_checks = [
        {NbInertia.Credo.Check.Warning.UseNbInertiaController, []},
        {NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl, []}
      ]

      assert {updated, true} = Credo.sync_nb_checks(config, desired_checks)

      checks = get_in(updated, [:configs, Access.at(0), :checks])

      assert {Credo.Check.Readability.ModuleDoc, []} in checks
      assert {NbInertia.Credo.Check.Warning.UseNbInertiaController, [priority: :high]} in checks
      assert {NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl, []} in checks

      refute Enum.any?(
               checks,
               &(elem(&1, 0) == NbSerializer.Credo.Check.Warning.MissingDatetimeFormat)
             )
    end

    test "keeps explicitly disabled desired checks disabled and only removes stale nb checks" do
      config = %{
        configs: [
          %{
            checks: %{
              enabled: [
                {Credo.Check.Readability.ModuleDoc, []},
                {NbSerializer.Credo.Check.Warning.MissingDatetimeFormat, [priority: :low]}
              ],
              disabled: [
                {NbInertia.Credo.Check.Warning.UseNbInertiaController, [priority: :high]}
              ]
            }
          }
        ]
      }

      desired_checks = [
        {NbInertia.Credo.Check.Warning.UseNbInertiaController, []},
        {NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl, []}
      ]

      assert {updated, true} = Credo.sync_nb_checks(config, desired_checks)

      enabled = get_in(updated, [:configs, Access.at(0), :checks, :enabled])
      disabled = get_in(updated, [:configs, Access.at(0), :checks, :disabled])

      assert {Credo.Check.Readability.ModuleDoc, []} in enabled
      assert {NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl, []} in enabled
      assert {NbInertia.Credo.Check.Warning.UseNbInertiaController, [priority: :high]} in disabled

      refute Enum.any?(
               enabled,
               &(elem(&1, 0) == NbSerializer.Credo.Check.Warning.MissingDatetimeFormat)
             )
    end
  end

  describe "sync_nb_requires/2" do
    test "adds desired nb require globs and removes stale nb globs while preserving unrelated ones" do
      config = %{
        configs: [
          %{
            requires: [
              "lib/custom_checks/**/*.ex",
              "../old_nb_serializer/lib/nb_serializer/credo/check/**/*.ex"
            ]
          }
        ]
      }

      desired_requires = [
        "lib/nb_inertia/credo/check/**/*.ex",
        "../nb_serializer/lib/nb_serializer/credo/check/**/*.ex"
      ]

      assert {updated, true} = Credo.sync_nb_requires(config, desired_requires)

      requires = get_in(updated, [:configs, Access.at(0), :requires])

      assert "lib/custom_checks/**/*.ex" in requires
      assert "lib/nb_inertia/credo/check/**/*.ex" in requires
      assert "../nb_serializer/lib/nb_serializer/credo/check/**/*.ex" in requires
      refute "../old_nb_serializer/lib/nb_serializer/credo/check/**/*.ex" in requires
    end
  end
end
