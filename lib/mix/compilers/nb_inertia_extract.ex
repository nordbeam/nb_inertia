defmodule Mix.Compilers.NbInertiaExtract do
  @moduledoc """
  Mix compiler that automatically extracts `~TSX`/`~JSX` components on `mix compile`.

  Add this compiler to your project's `mix.exs`:

      def project do
        [
          compilers: Mix.compilers() ++ [:nb_inertia_extract],
          # ...
        ]
      end

  The compiler runs after the standard Elixir compiler, finds all Page modules
  with `render/0` defined, and extracts their frontend components to
  `.nb_inertia/pages/`.

  Extraction is incremental — only files whose content has changed are rewritten.
  """

  @doc false
  def run(_args) do
    # Only run if there are page modules with render/0
    # Use incremental mode to avoid unnecessary writes
    results = NbInertia.Extractor.extract_all(incremental: true)

    # Determine diagnostics from results
    diagnostics =
      results
      |> Enum.flat_map(fn
        {:error, mod, reason} ->
          [
            %Mix.Task.Compiler.Diagnostic{
              compiler_name: "nb_inertia_extract",
              file: "",
              message: "Failed to extract #{inspect(mod)}: #{reason}",
              position: 0,
              severity: :warning
            }
          ]

        _ ->
          []
      end)

    if diagnostics == [] do
      {:noop, []}
    else
      {:ok, diagnostics}
    end
  end
end
