defmodule TypeCheck.Internals.Bootstrap.Macros do
  # coveralls-ignore-start

  @moduledoc false
  # Used inside modules that want to add checks
  # where this is not possible because of cyclic dependencies otherwise
  defmacro if_recompiling?(kwargs) do
    doblock =
      kwargs[:do] ||
        quote generated: true, location: :keep do
        end

    elseblock =
      kwargs[:else] ||
        quote generated: true, location: :keep do
        end

    # `Code.ensure_loaded/1` no longer sees modules compiled earlier in the same
    # run (there is no .beam on disk in a fresh build), so "am I being
    # recompiled?" is signaled explicitly by `recompile/2` instead.
    if :persistent_term.get({TypeCheck.Internals.Bootstrap.Macros, :recompiling, __CALLER__.module}, false) do
      doblock
    else
      elseblock
    end
  end

  defmacro recompile(module, filename) do
    quote do
      # Compatible with Elixir 1.9:
      # If support no longer necessary, replace with Code.get_compiler_option
      prev = Code.compiler_options()[:ignore_module_conflict]
      Code.compiler_options(%{:ignore_module_conflict => true})
      require unquote(module)
      :persistent_term.put({TypeCheck.Internals.Bootstrap.Macros, :recompiling, unquote(module)}, true)
      Code.compile_file(unquote(filename))
      :persistent_term.erase({TypeCheck.Internals.Bootstrap.Macros, :recompiling, unquote(module)})
      Code.compiler_options(%{:ignore_module_conflict => prev})
    end
  end

  # coveralls-ignore-end
end
