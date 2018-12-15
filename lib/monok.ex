defmodule Monok do
  @moduledoc """
  Provides simple functor, applicative and monad macros for writing pipelines involving functions
  that return the common `{:ok, result}` or `{:error, reason}` tuples.
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
  def fmap({:ok, value}, function) do
    {:ok, function.(value)}
  end

  def fmap({:error, reason}, _function) do
    {:error, reason}
  end

  @doc """
  Applies a function wrapped in an :ok tuple to a value wrapped in an :ok tuple, carries through an :error
  tuple if either the value or function arguments are given as :error tuples instead of :ok tuples.

  Examples
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
  Applies a function that returns a value wrapped in an :ok tuple to a value wrapped in an :ok tuple, carries
  through an :error tuple if either the value argument is given as an :error tuple or the function returns an
  :error tuple when applied to the value.

  Examples
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
  def bind({:ok, value}, function) do
    function.(value)
  end

  def bind({:error, reason}, _function) do
    {:error, reason}
  end

  @doc """
  Infix fmap

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
  defmacro value_tuple ~> function_ast do
    handle_fmap_macro(value_tuple, function_ast)
  end

  def handle_fmap_macro({:ok, value}, {function, metadata, call_args}) do
    {:ok, {function, metadata, [value | call_args]} |> Macro.expand(__ENV__)}
  end

  def handle_fmap_macro({:error, reason}, _function_ast) do
    {:error, reason}
  end

  def handle_fmap_macro(value_tuple_ast, function_ast) do
    value_tuple_ast |> Macro.expand(__ENV__) |> handle_fmap_macro(function_ast)
  end

  @doc """
  Infix lift

  Applies a function wrapped in an :ok tuple to a value wrapped in an :ok tuple, carries through an :error
  tuple if either the value or function arguments are given as :error tuples instead of :ok tuples.

  Examples
      iex> {:ok, 1}
      iex> <~> ({:ok, fn x -> x + 1 end})
      {:ok, 2}

      iex> {:ok, 1}
      iex> <~> {:error, :reason}
      {:error, :reason}

      iex> {:ok, 1}
      iex> <~> {:ok, fn x -> x + 1 end}
      iex> <~> {:ok, fn x -> x * 2 end}
      {:ok, 4}

      iex> {:error, :reason}
      iex> <~> {:ok, fn x -> x + 1 end}
      {:error, :reason}
  """
  defmacro value_tuple <~> function_tuple do
    quote do
      unquote(value_tuple) |> lift(unquote(function_tuple))
    end
  end

  @doc """
  Infix bind

  Applies a function that returns a value wrapped in an :ok tuple to a value wrapped in an :ok tuple, carries
  through an :error tuple if either the value argument is given as an :error tuple or the function returns an
  :error tuple when applied to the value.

  Examples
      iex> {:ok, 1}
      iex> ~>> (fn x -> {:ok, x + 1} end)
      {:ok, 2}

      iex> {:ok, 1}
      iex> ~>> (fn _ -> {:error, :reason} end)
      {:error, :reason}

      iex> {:ok, 1}
      iex> ~>> (fn x -> {:ok, x + 1} end)
      iex> ~>> (fn x -> {:ok, x * 2} end)
      {:ok, 4}

      iex> {:error, :reason}
      iex> ~>> (fn x -> {:ok, x + 1} end)
      {:error, :reason}
  """
  defmacro value_tuple ~>> tuple_function do
    quote do
      unquote(value_tuple) |> bind(unquote(tuple_function))
    end
  end
end
