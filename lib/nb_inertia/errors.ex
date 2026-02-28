defprotocol NbInertia.Errors do
  @moduledoc ~S"""
  Converts a value to Inertia.js-compatible [validation errors](https://inertiajs.com/validation).

  This protocol transforms error structures into the flat map format expected by
  Inertia.js for client-side validation, where keys are field paths and values
  are error messages.

  ## Built-in Implementations

  * `Ecto.Changeset` - Converts changeset errors, handling nested and array fields
  * `Map` - Validates and passes through properly formatted error maps

  ## Usage with Ecto.Changeset

      def create(conn, %{"post" => post_params}) do
        case Posts.create(post_params) do
          {:ok, post} ->
            redirect(conn, to: ~p"/posts/#{post}")

          {:error, changeset} ->
            conn
            |> assign_errors(changeset)
            |> redirect(to: ~p"/posts/new")
        end
      end

  ## Custom Error Formatting

  Provide a custom message function as the second argument:

      NbInertia.Errors.to_errors(changeset, fn {msg, opts} ->
        Gettext.dgettext(MyApp.Gettext, "errors", msg, opts)
      end)

  ## Implementing for Custom Types

      defimpl NbInertia.Errors, for: MyApp.ValidationError do
        def to_errors(error) do
          %{"field_name" => error.message}
        end

        def to_errors(error, _msg_func), do: to_errors(error)
      end
  """

  @spec to_errors(term()) :: map() | no_return()
  def to_errors(value)

  @spec to_errors(term(), msg_func :: function()) :: map() | no_return()
  def to_errors(value, msg_func)
end

defimpl NbInertia.Errors, for: Ecto.Changeset do
  def to_errors(%Ecto.Changeset{} = changeset) do
    to_errors(changeset, &default_msg_func/1)
  end

  def to_errors(%Ecto.Changeset{} = changeset, msg_func) do
    changeset
    |> Ecto.Changeset.traverse_errors(msg_func)
    |> process_errors()
    |> Map.new()
  end

  defp process_errors(value, path \\ nil)

  defp process_errors(%{} = map, path) do
    map
    |> Map.to_list()
    |> Enum.map(fn {key, value} ->
      path = if path, do: "#{path}.#{key}", else: key
      process_errors(value, path)
    end)
    |> List.flatten()
  end

  defp process_errors([%{} | _] = maps, path) do
    maps
    |> Enum.with_index()
    |> Enum.map(fn {map, idx} ->
      process_errors(map, "#{path}[#{idx}]")
    end)
    |> List.flatten()
  end

  defp process_errors([message], path) when is_binary(message) do
    {path, message}
  end

  defp process_errors([first_message | _], path) when is_binary(first_message) do
    {path, first_message}
  end

  defp default_msg_func({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end
end

defimpl NbInertia.Errors, for: Map do
  def to_errors(value) do
    validate_error_map!(value)
  end

  def to_errors(value, _msg_func) do
    validate_error_map!(value)
  end

  defp validate_error_map!(map) do
    values = Map.values(map)

    # Check for "bagged" errors (e.g. %{"updateCompany" => %{"name" => "is invalid"}})
    if Enum.all?(values, &is_map/1) do
      Enum.each(values, &validate_error_map!/1)
    else
      Enum.each(map, fn {key, value} ->
        if !is_atom(key) && !is_binary(key) do
          raise ArgumentError, message: "expected atom or string key, got #{inspect(key)}"
        end

        if !is_binary(value) do
          raise ArgumentError,
            message: "expected string value for #{to_string(key)}, got #{inspect(value)}"
        end
      end)
    end

    map
  end
end
