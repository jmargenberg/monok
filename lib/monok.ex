defmodule Monok do
  @moduledoc """
  *** NOTE: this library is unfinished and has several unfixed issues, feel free to look through or help out but definitely don't depend on it. ***

  Provides the infix pipe operators `~>`, `~>>`, and `<~>` for writing elegant pipelines that treat the common
  `{:ok, result}` and `{:error, reason}` tuples as simple functors, monads and applicatives.

  Also provides the functions `fmap`, `bind` and `lift` as alternative implementations that don't override the
  inifix operators that could potentially conflict with other libraries.

  ## Why does this exist?
  Writing unnecessary macros and overriding infix operators are generally both pretty bad
  ideas but I made this as an exercise in learning basic metaprogramming.

  ## Functor Pipelines
  Allows you to write clean pipelines that transforms values inside of `{:ok, value}` tuples.

  ```
  iex> {:ok, [1, 2, 3]}
  iex> ~> Enum.sum()
  iex> ~> div(2)
  {:ok, 3}
  ```

  If the input is an `{:error, reason}` tuple it is carried through the pipeline without applying any
  transformations.

  ```
  iex> {:error, :reason}
  iex> ~> Enum.sum()
  iex> ~> div(2)
  {:error, :reason}
  ```

  ## Monad Pipelines
  Allows you to write clean pipelines that transform values in `{:ok, value}` tuples with functions that also
  return `{:ok, value}` tuples.

  ```
  iex> decrement = fn
  ...>   x when x > 0 -> {:ok, x - 1}
  ...>   _ -> {:error, :input_too_small}
  ...>  end
  iex> {:ok, 3}
  iex> ~>> decrement.()
  iex> ~>> decrement.()
  {:ok, 1}
  ```

  If at any point in the pipeline an `{:error, reason}` tuple is returned it is carried through without
  any of the transformation functions being applied.

  ```
  iex> decrement = fn
  ...>   x when x > 0 -> {:ok, x - 1}
  ...>   _ -> {:error, :input_too_small}
  ...>  end
  iex> {:ok, 3}
  iex> ~>> (fn _ -> {:error, :contrived_example} end).()
  iex> ~>> decrement.()
  iex> ~>> decrement.()
  {:error, :contrived_example}
  ```

  ## Mixed Pipelines
  These pipe operators that don't have to be used in seperate pipelines but can be used in conjuction,
  including with the standard `|>` pipe operator.

  ```
  iex> 7
  iex> |> (&(if &1 > 5, do: {:ok, &1}, else: {:error, :too_low})).()
  iex> ~> Integer.to_string()
  iex> ~>> (&(if &1 |> length() > 0, do: &1 ++ "!", else: {:error, :empty_string})).()
  {:ok, "7!"}
  ```
  """

  @doc """
  Applies a function to a value wrapped in an ok tuple, has no effect if given an error tuple.

  ## Examples

      iex> {:ok, 1}
      iex> |> fmap(fn x -> x + 1 end)
      {:ok, 2}

      iex> {:ok, 1}
      iex> |> fmap(fn x -> x + 1 end)
      iex> |> fmap(fn x -> x * 2 end)
      {:ok, 4}

      iex> {:error, :reason}
      iex> |> fmap(fn x -> x + 1 end)
      {:error, :reason}

  """
  def fmap(value_tuple, function)

  def fmap({:ok, value}, function) do
    {:ok, function.(value)}
  end

  def fmap({:error, reason}, _function) do
    {:error, reason}
  end

  @doc """
  Applies a function wrapped in an :ok tuple to a value wrapped in an :ok tuple.

  Carries through an :error tuple if either the value or function arguments are given as :error tuples instead of :ok tuples.

  ## Examples
      iex> {:ok, 1}
      iex> |> lift({:ok, fn x -> x + 1 end})
      {:ok, 2}

      iex> {:ok, 1}
      iex> |> lift({:error, :reason})
      {:error, :reason}

      iex> {:ok, 1}
      iex> |> lift({:ok, fn x -> x + 1 end})
      iex> |> lift({:ok, fn x -> x * 2 end})
      {:ok, 4}

      iex> {:error, :reason}
      iex> |> lift({:ok, fn x -> x + 1 end})
      {:error, :reason}
  """
  def lift(value_tuple, function_tuple)

  def lift({:ok, value}, {:ok, function}) do
    {:ok, function.(value)}
  end

  def lift({:error, reason}, _function_tuple) do
    {:error, reason}
  end

  def lift(_value_tuple, {:error, reason}) do
    {:error, reason}
  end

  @doc """
  Applies a function that returns a value wrapped in an :ok tuple to a value wrapped in an :ok tuple.

  Carries through an :error tuple if either the value argument is given as an :error tuple or the function returns an
  :error tuple when applied to the value.

  ## Examples
      iex> {:ok, 1}
      iex> |> bind(fn x -> {:ok, x + 1} end)
      {:ok, 2}

      iex> {:ok, 1}
      iex> |> bind(fn _ -> {:error, :reason} end)
      {:error, :reason}

      iex> {:ok, 1}
      iex> |> bind(fn x -> {:ok, x + 1} end)
      iex> |> bind(fn x -> {:ok, x * 2} end)
      {:ok, 4}

      iex> {:error, :reason}
      iex> |> bind(fn x -> {:ok, x + 1} end)
      {:error, :reason}
  """
  def bind(value_tuple, function)

  def bind({:ok, value}, function) do
    function.(value)
  end

  def bind({:error, reason}, _function) do
    {:error, reason}
  end

  @doc """
  Infix fmap operator.

  Applies a function to a value wrapped in an ok tuple, has no effect if given an error tuple.

  ## Examples

      iex> {:ok, "hello world!"}
      iex> ~> String.upcase()
      {:ok, "HELLO WORLD!"}

      iex> {:error, :reason}
      iex> ~> String.upcase()
      {:error, :reason}

      iex> {:ok, [1, 2, 3]}
      iex> ~> Enum.map(fn x -> x + 1 end)
      {:ok, [2, 3, 4]}

      iex> {:ok, [1, 2, 3]}
      iex> ~> Enum.sum()
      iex> ~> div(2)
      {:ok, 3}

      iex> {:ok, %{foo: 1}}
      iex> ~> Map.put(:bar, 2)
      iex> ~> Map.update(:bar, nil, &(&1 + 2))
      {:ok, %{foo: 1, bar: 4}}
  """
  defmacro value_tuple ~> function do
    handle_fmap_macro(value_tuple, function)
  end

  defp handle_fmap_macro({:ok, value}, {function, metadata, call_args}) do
    {:ok, {function, metadata, [value | call_args]} |> Macro.expand(__ENV__)}
  end

  defp handle_fmap_macro({:error, reason}, _function_ast) do
    {:error, reason}
  end

  defp handle_fmap_macro(value_ast_tuple, function_ast) do
    Macro.expand(value_ast_tuple, __ENV__) |> handle_fmap_macro(function_ast)
  end

  @doc """
  Infix lift operator.

  Applies a function wrapped in an :ok tuple to a value wrapped in an :ok tuple.

  Carries through an :error tuple if either the value or function arguments are given as :error tuples instead of :ok tuples.

  ## Usage
  Unlike the `~>` and `~>>`, `<~>` is implemented as a function instead of a macro.

  This is because macros were only used for the other infix operators so that they could more closely mimick
  `|>` in having actuall function calls on their right hand side instead of functions references. e.g. `{:ok, 1}
   ~> Integer.toString()` instead of `{:ok, 1} ~> &Integer.toString/1`. This would not make send for a lift
   operator since the function is itself wrapped in an :ok/:error tuple.

  ## Examples
      iex> {:ok, 1}
      iex> <~> {:ok, &Integer.to_string/1}
      {:ok, "1"}

      iex> {:ok, 1}
      iex> <~> {:ok, fn x -> x + 1 end}
      {:ok, 2}

      iex> {:ok, 1}
      iex> <~> {:error, :reason}
      {:error, :reason}

      iex> {:ok, "1"}
      iex> <~> {:ok, &String.to_integer/1}
      iex> <~> {:ok, fn x -> x + 1 end}
      {:ok, 2}

      iex> {:error, :reason}
      iex> <~> {:ok, fn x -> x + 1 end}
      {:error, :reason}
  """
  def value_tuple <~> function_tuple do
    value_tuple |> lift(function_tuple)
  end

  @doc """
  Infix bind operator.

  Applies a function that returns a value wrapped in an :ok tuple to a value wrapped in an :ok tuple.

  Carries through an :error tuple if either the value argument is given as an :error tuple or the function returns an
  :error tuple when applied to the value.

  ## Examples
      iex> {:ok, 1}
      iex> ~>> (fn x -> {:ok, x + 1} end).()
      {:ok, 2}

      iex> {:ok, 1}
      iex> ~>> (fn _ -> {:error, :reason} end).()
      {:error, :reason}

      iex> {:ok, 1}
      iex> ~>> (fn x -> {:ok, x + 1} end).()
      {:ok, 2}

      iex> {:error, :reason}
      iex> ~>> (fn x -> {:ok, x + 1} end).()
      {:error, :reason}
  """
  defmacro value_tuple ~>> tuple_function do
    handle_bind_macro(value_tuple, tuple_function)
  end

  defp handle_bind_macro({:ok, value}, {tuple_function, metadata, call_args}) do
    {tuple_function, metadata, [value | call_args]}
  end

  defp handle_bind_macro({:error, reason}, _function_ast) do
    {:error, reason}
  end

  defp handle_bind_macro(value_ast_tuple, tuple_function_ast) do
    value_ast_tuple |> Macro.expand(__ENV__) |> handle_bind_macro(tuple_function_ast)
  end
end
