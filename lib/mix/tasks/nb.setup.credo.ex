defmodule Mix.Tasks.Nb.Setup.Credo do
  @shortdoc "Set up Credo with the installed nb_* custom checks"
  @moduledoc """
  Adds Credo to your project if needed and syncs `.credo.exs` with the
  custom checks provided by the installed `nb_*` libraries.

      mix nb.setup.credo

  This task currently enables checks from:

    * `nb_inertia`
    * `nb_serializer` when it is installed

  Re-running the task is safe. It removes stale nb-specific checks for
  libraries that are no longer installed and keeps existing Credo options
  for checks that are already configured.
  """

  use Mix.Task

  @credo_dep {:credo, "~> 1.7", [only: [:dev, :test], runtime: false]}

  @nb_inertia_checks [
    {NbInertia.Credo.Check.Design.DeclareInertiaPage, []},
    {NbInertia.Credo.Check.Design.FormInputsOptionalFieldConsistency, []},
    {NbInertia.Credo.Check.Readability.InertiaPageComponentNameCase, []},
    {NbInertia.Credo.Check.Readability.PropFromAssigns, []},
    {NbInertia.Credo.Check.Warning.ActionWithoutMount, []},
    {NbInertia.Credo.Check.Warning.AvoidRawInertiaRender, []},
    {NbInertia.Credo.Check.Warning.DirectRepoInController, []},
    {NbInertia.Credo.Check.Warning.InconsistentOptionalProps, []},
    {NbInertia.Credo.Check.Warning.MissingInertiaPageProps, []},
    {NbInertia.Credo.Check.Warning.MissingInertiaSharedProps, []},
    {NbInertia.Credo.Check.Warning.MissingMount, []},
    {NbInertia.Credo.Check.Warning.MissingSerializerInertiaProps, []},
    {NbInertia.Credo.Check.Warning.MixedInertiaControllerType, []},
    {NbInertia.Credo.Check.Warning.MixedPageAndController, []},
    {NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl, []},
    {NbInertia.Credo.Check.Warning.ModalWithoutBaseUrl, []},
    {NbInertia.Credo.Check.Warning.RenderWithoutProps, []},
    {NbInertia.Credo.Check.Warning.UndeclaredPropInMount, []},
    {NbInertia.Credo.Check.Warning.UntypedInertiaProps, []},
    {NbInertia.Credo.Check.Warning.UnusedPropInMount, []},
    {NbInertia.Credo.Check.Warning.UseNbInertiaController, []}
  ]

  @nb_serializer_checks [
    {NbSerializer.Credo.Check.Design.LargeSchema, []},
    {NbSerializer.Credo.Check.Design.SimpleFieldCompute, []},
    {NbSerializer.Credo.Check.Readability.MissingModuledoc, []},
    {NbSerializer.Credo.Check.Warning.DatetimeAsString, []},
    {NbSerializer.Credo.Check.Warning.GenericMapType, []},
    {NbSerializer.Credo.Check.Warning.InconsistentNumericTypes, []},
    {NbSerializer.Credo.Check.Warning.InvalidNestedSerializerType, []},
    {NbSerializer.Credo.Check.Warning.MissingDatetimeFormat, []}
  ]

  @fallback_credo_config %{
    configs: [
      %{
        name: "default",
        files: %{
          included: [
            "lib/",
            "src/",
            "test/",
            "web/",
            "apps/*/lib/",
            "apps/*/src/",
            "apps/*/test/",
            "apps/*/web/"
          ],
          excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
        },
        plugins: [],
        requires: [],
        strict: false,
        parse_timeout: 5000,
        color: true,
        checks: %{
          enabled: [],
          disabled: []
        }
      }
    ]
  }

  @impl Mix.Task
  def run(_argv) do
    mix_exs_path = Path.expand("mix.exs")
    credo_status = ensure_credo_dependency(mix_exs_path)

    if credo_status == :added do
      Mix.shell().info("Added Credo to mix.exs.")
      fetch_dependencies!()
    else
      refresh_loadpaths!()
    end

    ensure_credo_config_file!()

    installed_libraries = installed_nb_libraries()
    desired_checks = recommended_check_entries(installed_libraries)
    desired_requires = recommended_require_patterns(installed_libraries)

    credo_config_path = Path.expand(".credo.exs")

    credo_config = load_credo_config!(credo_config_path)
    {credo_config, requires_changed?} = sync_nb_requires(credo_config, desired_requires)
    {credo_config, checks_changed?} = sync_nb_checks(credo_config, desired_checks)

    maybe_write_credo_config(
      {credo_config, requires_changed? or checks_changed?},
      credo_config_path
    )

    maybe_recompile_with_credo!(credo_status, desired_checks, installed_libraries)

    print_summary(credo_status, desired_checks)
  end

  @doc false
  def update_mix_exs_for_credo_dep(source) when is_binary(source) do
    ast = Code.string_to_quoted!(source)

    {updated_ast, status} =
      Macro.prewalk(ast, :unchanged, fn
        {kind, meta, [{:deps, fun_meta, args}, [do: deps]]}, status
        when kind in [:def, :defp] and (is_nil(args) or is_list(args)) and status == :unchanged ->
          case deps do
            dep_list when is_list(dep_list) ->
              if Enum.any?(dep_list, &dep_named?(&1, :credo)) do
                {{kind, meta, [{:deps, fun_meta, args}, [do: dep_list]]}, :already_present}
              else
                credo_dep_ast = credo_dep_ast()

                {{kind, meta, [{:deps, fun_meta, args}, [do: dep_list ++ [credo_dep_ast]]]},
                 :added}
              end

            _ ->
              {{kind, meta, [{:deps, fun_meta, args}, [do: deps]]}, status}
          end

        node, status ->
          {node, status}
      end)

    case status do
      :added ->
        {:ok, format_elixir(updated_ast), :added}

      :already_present ->
        {:ok, source, :already_present}

      :unchanged ->
        {:error, "Could not find a literal deps/0 list in mix.exs."}
    end
  end

  @doc false
  def recommended_check_entries(installed_deps) do
    []
    |> maybe_append_checks(:nb_inertia in installed_deps, @nb_inertia_checks)
    |> maybe_append_checks(:nb_serializer in installed_deps, @nb_serializer_checks)
  end

  @doc false
  def recommended_require_patterns(
        installed_deps,
        deps_paths \\ Mix.Project.deps_paths(),
        cwd \\ File.cwd!()
      ) do
    Enum.flat_map(installed_deps, fn app ->
      case library_root_path(app, deps_paths, cwd) do
        nil -> []
        root_path -> [require_pattern_for_library(app, root_path, cwd)]
      end
    end)
  end

  @doc false
  def sync_nb_checks(config, desired_checks) do
    all_nb_modules =
      (@nb_inertia_checks ++ @nb_serializer_checks)
      |> Enum.map(&check_module/1)
      |> MapSet.new()

    new_config =
      case config do
        %{configs: configs} when is_list(configs) ->
          %{
            config
            | configs:
                Enum.map(configs, &sync_checks_in_config(&1, desired_checks, all_nb_modules))
          }

        _ ->
          put_nb_config_in_default_config(desired_checks, [])
      end

    {new_config, new_config != config}
  end

  @doc false
  def sync_nb_requires(config, desired_requires) do
    new_config =
      case config do
        %{configs: configs} when is_list(configs) ->
          %{config | configs: Enum.map(configs, &sync_requires_in_config(&1, desired_requires))}

        _ ->
          put_nb_config_in_default_config([], desired_requires)
      end

    {new_config, new_config != config}
  end

  defp ensure_credo_dependency(mix_exs_path) do
    source = File.read!(mix_exs_path)

    case update_mix_exs_for_credo_dep(source) do
      {:ok, updated_source, :added} ->
        File.write!(mix_exs_path, updated_source)
        :added

      {:ok, _source, :already_present} ->
        :already_present

      {:error, reason} ->
        Mix.raise("""
        Could not add Credo to mix.exs automatically.

        #{reason}

        Add this dependency manually and re-run the task:

            #{@credo_dep |> inspect()}
        """)
    end
  end

  defp fetch_dependencies! do
    Mix.Task.reenable("deps.get")
    Mix.Task.run("deps.get")
    refresh_loadpaths!()
  rescue
    error ->
      raise_dependency_fetch_error!(error)
  end

  defp refresh_loadpaths! do
    Mix.Task.reenable("deps.loadpaths")
    Mix.Task.run("deps.loadpaths", ["--no-deps-check"])
    Mix.Task.reenable("loadpaths")
    Mix.Task.run("loadpaths", ["--no-compile"])
  end

  defp ensure_credo_config_file! do
    if File.exists?(".credo.exs") do
      :ok
    else
      refresh_loadpaths!()

      try do
        Mix.Task.reenable("credo.gen.config")
        Mix.Task.run("credo.gen.config")
      rescue
        _ ->
          write_credo_config!(@fallback_credo_config, ".credo.exs")
      end
    end
  end

  defp load_credo_config!(path) do
    case Code.eval_file(path) do
      {config, _binding} when is_map(config) ->
        config

      _ ->
        Mix.raise("""
        .credo.exs did not evaluate to a map.

        Please update #{path} manually.
        """)
    end
  rescue
    error ->
      Mix.raise("""
      Could not parse .credo.exs.

      #{Exception.message(error)}
      """)
  end

  defp maybe_write_credo_config({config, true}, path) do
    write_credo_config!(config, path)
  end

  defp maybe_write_credo_config({_config, false}, _path), do: :ok

  defp write_credo_config!(config, path) do
    config
    |> inspect(pretty: true, limit: :infinity)
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> then(&File.write!(path, &1))
  end

  defp recompile_with_credo!(installed_libraries) do
    current_app = Mix.Project.config()[:app]

    dependency_apps =
      installed_libraries
      |> Enum.reject(&(&1 == current_app))

    if dependency_apps != [] do
      Mix.Task.reenable("deps.compile")
      Mix.Task.run("deps.compile", Enum.map(dependency_apps, &Atom.to_string/1) ++ ["--force"])
    end

    Mix.Task.reenable("compile")

    if current_app in installed_libraries do
      Mix.Task.run("compile", ["--force"])
    else
      Mix.Task.run("compile")
    end
  end

  defp maybe_recompile_with_credo!(credo_status, desired_checks, installed_libraries) do
    if credo_status == :added or missing_custom_check_modules?(desired_checks) do
      recompile_with_credo!(installed_libraries)
    end
  end

  defp installed_nb_libraries(deps_paths \\ Mix.Project.deps_paths()) do
    supported_apps = [:nb_inertia, :nb_serializer]
    current_app = Mix.Project.config()[:app]

    supported_apps
    |> Enum.filter(fn app ->
      cond do
        app == current_app ->
          library_has_custom_check_files?(Path.expand("."), app)

        deps_paths[app] ->
          library_has_custom_check_files?(deps_paths[app], app)

        true ->
          false
      end
    end)
    |> Enum.uniq()
  end

  defp maybe_append_checks(checks, true, extra_checks), do: checks ++ extra_checks
  defp maybe_append_checks(checks, false, _extra_checks), do: checks

  defp sync_checks_in_config(config, desired_checks, all_nb_modules) when is_map(config) do
    desired_modules =
      desired_checks
      |> Enum.map(&check_module/1)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    case Map.get(config, :checks) do
      checks when is_list(checks) ->
        cleaned_checks = remove_stale_nb_checks(checks, desired_modules, all_nb_modules)
        %{config | checks: merge_check_entries(cleaned_checks, desired_checks)}

      checks when is_map(checks) ->
        enabled_checks =
          checks
          |> Map.get(:enabled, [])
          |> ensure_list()
          |> remove_stale_nb_checks(desired_modules, all_nb_modules)

        disabled_checks =
          checks
          |> Map.get(:disabled, [])
          |> ensure_list()
          |> remove_stale_nb_checks(desired_modules, all_nb_modules)

        missing_checks = missing_desired_checks(enabled_checks ++ disabled_checks, desired_checks)

        updated_checks =
          checks
          |> Map.put(:enabled, enabled_checks ++ missing_checks)
          |> Map.put(:disabled, disabled_checks)

        %{config | checks: updated_checks}

      nil ->
        Map.put(config, :checks, %{enabled: desired_checks, disabled: []})

      _other ->
        config
    end
  end

  defp sync_checks_in_config(config, _desired_checks, _all_nb_modules), do: config

  defp sync_requires_in_config(config, desired_requires) when is_map(config) do
    requires =
      config
      |> Map.get(:requires, [])
      |> ensure_list()
      |> remove_stale_nb_requires(desired_requires)

    Map.put(config, :requires, merge_require_entries(requires, desired_requires))
  end

  defp sync_requires_in_config(config, _desired_requires), do: config

  defp put_nb_config_in_default_config(desired_checks, desired_requires) do
    @fallback_credo_config
    |> put_in([:configs, Access.at(0), :checks, :enabled], desired_checks)
    |> put_in([:configs, Access.at(0), :requires], desired_requires)
  end

  defp ensure_list(value) when is_list(value), do: value
  defp ensure_list(_), do: []

  defp remove_stale_nb_checks(entries, desired_modules, all_nb_modules) do
    Enum.reject(entries, fn entry ->
      module = check_module(entry)

      module && MapSet.member?(all_nb_modules, module) &&
        not MapSet.member?(desired_modules, module)
    end)
  end

  defp merge_check_entries(existing_entries, desired_entries) do
    existing_modules =
      existing_entries
      |> Enum.map(&check_module/1)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    existing_entries ++
      Enum.reject(desired_entries, fn entry ->
        MapSet.member?(existing_modules, check_module(entry))
      end)
  end

  defp missing_desired_checks(existing_entries, desired_entries) do
    existing_modules =
      existing_entries
      |> Enum.map(&check_module/1)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    Enum.reject(desired_entries, fn entry ->
      MapSet.member?(existing_modules, check_module(entry))
    end)
  end

  defp remove_stale_nb_requires(entries, desired_requires) do
    Enum.reject(entries, fn entry ->
      is_binary(entry) and nb_require_pattern?(entry) and entry not in desired_requires
    end)
  end

  defp merge_require_entries(existing_entries, desired_entries) do
    existing_entries ++ Enum.reject(desired_entries, &(&1 in existing_entries))
  end

  defp check_module({module, _opts}) when is_atom(module), do: module
  defp check_module({module, _opts, _meta}) when is_atom(module), do: module
  defp check_module(module) when is_atom(module), do: module
  defp check_module(_), do: nil

  defp missing_custom_check_modules?(desired_checks) do
    Enum.any?(desired_checks, fn entry ->
      case check_module(entry) do
        module when is_atom(module) -> not Code.ensure_loaded?(module)
        _ -> false
      end
    end)
  end

  defp dep_named?({:{}, _, [name | _]}, target) when is_atom(name), do: name == target
  defp dep_named?({name, _, _}, target) when is_atom(name), do: name == target
  defp dep_named?({name, _}, target) when is_atom(name), do: name == target
  defp dep_named?(_, _), do: false

  defp library_root_path(app, deps_paths, cwd) do
    current_app = Mix.Project.config()[:app]

    cond do
      app == current_app and library_has_custom_check_files?(Path.expand(cwd), app) ->
        Path.expand(cwd)

      deps_paths[app] && library_has_custom_check_files?(deps_paths[app], app) ->
        deps_paths[app]

      true ->
        nil
    end
  end

  defp library_has_custom_check_files?(root_path, app) do
    Path.join([root_path, "lib", Atom.to_string(app), "credo", "check", "**", "*.ex"])
    |> Path.wildcard()
    |> Enum.any?()
  end

  defp require_pattern_for_library(app, root_path, cwd) do
    relative_root = relative_path_from(cwd, root_path)

    relative_glob_path(
      relative_root,
      Path.join(["lib", Atom.to_string(app), "credo", "check", "**", "*.ex"])
    )
  end

  defp relative_glob_path(".", suffix), do: suffix
  defp relative_glob_path(relative_root, suffix), do: Path.join(relative_root, suffix)

  defp relative_path_from(from_path, to_path) do
    from_parts = Path.split(Path.expand(from_path))
    to_parts = Path.split(Path.expand(to_path))

    {from_suffix, to_suffix} = drop_common_path_prefix(from_parts, to_parts)
    relative_parts = List.duplicate("..", length(from_suffix)) ++ to_suffix

    case relative_parts do
      [] -> "."
      parts -> Path.join(parts)
    end
  end

  defp drop_common_path_prefix([segment | from_rest], [segment | to_rest]) do
    drop_common_path_prefix(from_rest, to_rest)
  end

  defp drop_common_path_prefix(from_parts, to_parts), do: {from_parts, to_parts}

  defp nb_require_pattern?(entry) when is_binary(entry) do
    Enum.any?([:nb_inertia, :nb_serializer], fn app ->
      suffix = Path.join(["lib", Atom.to_string(app), "credo", "check"])
      String.contains?(entry, suffix)
    end)
  end

  defp credo_dep_ast do
    Macro.escape(@credo_dep)
  end

  defp format_elixir(ast) do
    ast
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  defp raise_dependency_fetch_error!(
         %UndefinedFunctionError{
           module: Hex.Mix,
           function: :overridden_deps
         } = error
       ) do
    Mix.raise("""
    Credo was added to mix.exs, but fetching dependencies failed because Hex is too old for the current Mix version.

    Update Hex and then rerun the task:

        mix local.hex --force
        mix nb.setup.credo

    Original error:
        #{Exception.message(error)}
    """)
  end

  defp raise_dependency_fetch_error!(error) do
    Mix.raise("""
    Credo was added to mix.exs, but fetching dependencies failed.

    Resolve the dependency error, run `mix deps.get`, and then rerun:

        mix nb.setup.credo

    Original error:
        #{Exception.message(error)}
    """)
  end

  defp print_summary(credo_status, desired_checks) do
    installed_deps = installed_nb_libraries()
    check_count = Enum.count(desired_checks)

    credo_message =
      case credo_status do
        :added -> "- Added Credo to mix.exs and fetched dependencies"
        :already_present -> "- Credo was already configured in mix.exs"
      end

    deps_message =
      installed_deps
      |> Enum.map_join(", ", &Atom.to_string/1)
      |> case do
        "" -> "- No supported nb_* libraries were detected"
        names -> "- Enabled #{check_count} nb-specific Credo checks for #{names}"
      end

    Mix.shell().info("""

    Nb Credo setup complete.

    #{credo_message}
    #{deps_message}
    - Updated .credo.exs

    Next step:
        mix credo --strict
    """)
  end
end
