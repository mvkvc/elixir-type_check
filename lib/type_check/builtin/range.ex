defmodule TypeCheck.Builtin.Range do
  defstruct [:range]

  use TypeCheck

  if Version.compare(System.version(), "1.12.0") == :lt do
    @type! t :: %__MODULE__{range: %Range{first: integer(), last: integer()}}
  else
    @type! t :: %__MODULE__{range: %Range{first: integer(), last: integer(), step: 1}}
  end

  @type! problem_tuple ::
           {t(), :not_an_integer, %{}, any()}
           | {t(), :not_in_range, %{}, integer()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %{range: range}, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when not is_integer(x) ->
            {:error, {unquote(Macro.escape(s)), :not_an_integer, %{}, unquote(param)}}

          x when x not in unquote(Macro.escape(range)) ->
            {:error, {unquote(Macro.escape(s)), :not_in_range, %{}, unquote(param)}}

          correct_value ->
            {:ok, [], correct_value}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(struct, opts) do
      struct.range
      |> Inspect.Range.inspect(opts)
      |> TypeCheck.Inspect.unwrap_doc()
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(%{range: %Range{first: first, last: last} = range})
          when is_integer(first) and is_integer(last) do
        StreamData.integer(range)
      end

      def to_gen(_s) do
        StreamData.integer()
      end
    end
  end
end
