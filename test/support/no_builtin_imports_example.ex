defmodule NoBuiltinImportsExample do
  use TypeCheck

  @type! wrapped() :: {:wrapped, integer, binary(), term, [integer()]}
  @type! recursive() :: :done | {:next, recursive()}
  @type! recursive_value(a) :: {:value, a} | {:next, recursive_value(a)}

  @spec! integer() :: integer()
  def integer(), do: 42

  @spec! binary() :: binary()
  def binary(), do: "binary"

  @spec! term() :: term()
  def term(), do: :term

  @spec! list(integer()) :: [integer()]
  def list(value), do: [value]

  @spec! echo_integer(integer()) :: integer()
  def echo_integer(value), do: value

  @spec! echo_integer_without_parentheses(integer) :: integer
  def echo_integer_without_parentheses(value), do: value
end

defmodule ExplicitBuiltinImportsExample do
  use TypeCheck
  import TypeCheck.Builtin

  def integer_type(), do: integer()
end
