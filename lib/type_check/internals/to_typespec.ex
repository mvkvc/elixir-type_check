defmodule TypeCheck.Internals.ToTypespec do
  @moduledoc false
  def full_rewrite(ast, env) do
    Macro.postwalk(ast, &rewrite(&1, env))
  end

  def rewrite(ast, env) do
    case Macro.expand(ast, env) do
      {:lazy, _, [type]} ->
        type

      {:lazy_explicit, meta, [module, name, arguments]} ->
        # Removes 'lazy' from typespec.
        # Restores original type information we had available in `@type!`.
        case Keyword.fetch(meta, :original_type_ast) do
          {:ok, type_ast} ->
            type_ast

          :error ->
            quote generated: true, location: :keep do
              unquote(module).unquote(name)(unquote_splicing(arguments))
            end
        end

      {:when, _, [type, _]} ->
        # Hide `when` that might contain code from the typespec
        type

      {:guarded_by, _, [type, _]} ->
        # Hide `when` that might contain code from the typespec
        type

      ast = {:wrap_with_gen, _, [type, _]} ->
        if {:wrap_with_gen, 2} in (env.functions[TypeCheck.Type.StreamData] || []) do
          # Hide generator wrapper
          type
        else
          ast
        end

      # {:"::", _, [_name, type_ast]} ->
      #   # Hide inner named types from the typespec.
      #   type_ast

      {:named_type, _, [_name, type_ast]} ->
        # Hide inner named types from the typespec.
        type_ast

      {:one_of, _, [types]} ->
        Enum.reduce(types, fn type, snippet ->
          quote generated: true, location: :keep do
            unquote(snippet) | unquote(type)
          end
        end)

      {:fixed_tuple, meta, [elem_types]} ->
        {:{}, meta, elem_types}

      {:tuple, meta, [size]} ->
        elems =
          0..size
          |> Enum.map(fn _ ->
            quote generated: true, location: :keep do
              any()
            end
          end)

        {:{}, meta, elems}

      {:fixed_list, _meta, [_elem_types]} ->
        quote generated: true, location: :keep do
          list()
        end

      {:range, _meta, [lower, higher]} ->
        quote generated: true, location: :keep do
          unquote(lower)..unquote(higher)
        end

      {:range, _meta, [range]} ->
        quote generated: true, location: :keep do
          unquote(range)
        end

      {:literal, _, [elem_type]} ->
        if is_binary(elem_type) do
          quote generated: true, location: :keep do
            binary()
          end
        else
          quote generated: true, location: :keep do
            unquote(elem_type)
          end
        end

      {:impl, _, [protocol_name]} ->
        quote generated: true, location: :keep do
          unquote(protocol_name).t()
        end

      {:fixed_map, _, [keywords]} ->
        snippets =
          keywords
          |> Enum.map(fn {key, value} ->
            quote generated: true, location: :keep do
              {required(unquote(key)), unquote(value)}
            end
          end)

        quote generated: true, location: :keep do
          %{unquote_splicing(snippets)}
        end

      {:map, _, [key_type, value_type]} ->
        quote generated: true, location: :keep do
          %{optional(unquote(key_type)) => unquote(value_type)}
        end

      # Relax these types that Elixir's builtin typespecs does not accept
      float when is_float(float) ->
        quote generated: true, location: :keep do
          float()
        end

      other ->
        other
    end
  end
end
