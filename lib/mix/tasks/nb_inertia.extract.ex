defmodule Mix.Tasks.NbInertia.Extract do
  @moduledoc """
  Extracts colocated `~TSX`/`~JSX` components from Page modules to real files.

  The extraction pipeline:
  1. Compiles the project (ensures all Page modules are loaded)
  2. Finds all Page modules with `render/0` defined
  3. Generates TypeScript type preambles from prop declarations
  4. Writes `.tsx`/`.jsx` files to `.nb_inertia/pages/`

  ## Usage

      # Extract all pages
      mix nb_inertia.extract

      # Extract with verbose output
      mix nb_inertia.extract --verbose

      # Clean output directory first
      mix nb_inertia.extract --clean

      # Specify custom output directory
      mix nb_inertia.extract --output-dir .nb_inertia/pages

  ## Options

    * `--verbose` - Print extraction details
    * `--clean` - Remove output directory before extracting
    * `--output-dir` - Custom output directory (default: `.nb_inertia/pages`)

  ## Output

  Extracted files are written to `.nb_inertia/pages/` (gitignored).

      .nb_inertia/pages/
      ├── Users/
      │   ├── Index.tsx
      │   ├── Show.tsx
      │   └── Edit.tsx
      └── Dashboard/
          └── Index.tsx
  """

  use Mix.Task

  @shortdoc "Extract ~TSX/~JSX components from Page modules"

  @switches [
    verbose: :boolean,
    clean: :boolean,
    output_dir: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: @switches)

    # Ensure the project is compiled
    Mix.Task.run("compile", [])

    # Build extraction options
    extract_opts =
      opts
      |> Keyword.put_new(:verbose, false)
      |> Keyword.put_new(:clean, false)
      |> normalize_output_dir()

    # Always log in non-verbose mode
    verbose? = Keyword.get(extract_opts, :verbose, false)

    unless verbose? do
      IO.puts("Extracting ~TSX/~JSX pages...")
    end

    results = NbInertia.Extractor.extract_all(extract_opts)

    unless verbose? do
      {ok, skipped, errors} = count_results(results)

      output_dir =
        Keyword.get(extract_opts, :output_dir, NbInertia.Extractor.default_output_dir())

      cond do
        ok + skipped == 0 and errors == 0 ->
          IO.puts("No pages with render/0 found.")

        errors > 0 ->
          Mix.shell().error("Extracted #{ok} page(s) with #{errors} error(s) to #{output_dir}")

        true ->
          IO.puts("Extracted #{ok} page(s) to #{output_dir} (#{skipped} unchanged)")
      end
    end

    if Enum.any?(results, &match?({:error, _, _}, &1)) do
      Mix.raise("Extraction failed for some pages. Run with --verbose for details.")
    end
  end

  defp normalize_output_dir(opts) do
    case Keyword.get(opts, :output_dir) do
      nil -> opts
      dir -> Keyword.put(opts, :output_dir, dir)
    end
  end

  defp count_results(results) do
    Enum.reduce(results, {0, 0, 0}, fn
      {:ok, _}, {ok, skip, err} -> {ok + 1, skip, err}
      {:skipped, _}, {ok, skip, err} -> {ok, skip + 1, err}
      {:error, _, _}, {ok, skip, err} -> {ok, skip, err + 1}
    end)
  end
end
