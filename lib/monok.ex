defmodule Monok do
  @moduledoc """
  Provides simple functor (`|$>`), applicative (`|*>`) and monad (`|=>`) operators for writing pipelines
  involving functions that return the common `{:ok, result}` or `{:error, reason}` tuples.
  """

  @doc """
  Applies a function to a value wrapped in an ok tuple, has no effect if given an error tuple.

  ## Examples

      iex> {:ok, 1}
      iex> |> Monok.fmap(fn x -> x + 1 end)
      {:ok, 2}

      iex> {:ok, 1}
      iex> |> Monok.fmap(fn x -> x + 1 end)
      iex> |> Monok.fmap(fn x -> x * 2 end)
      {:ok, 4}

      iex> {:error, :reason}
      iex> |> Monok.fmap(fn x -> x + 1 end)
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
      iex> |> Monok.lift({:ok, fn x -> x + 1 end})
      {:ok, 2}

      iex> {:ok, 1}
      iex> |> Monok.lift({:error, :reason})
      {:error, :reason}

      iex> {:ok, 1}
      iex> |> Monok.lift({:ok, fn x -> x + 1 end})
      iex> |> Monok.lift({:ok, fn x -> x * 2 end})
      {:ok, 4}

      iex> {:error, :reason}
      iex> |> Monok.lift({:ok, fn x -> x + 1 end})
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
      iex> |> Monok.bind(fn x -> {:ok, x + 1} end)
      {:ok, 2}

      iex> {:ok, 1}
      iex> |> Monok.bind(fn _ -> {:error, :reason} end)
      {:error, :reason}

      iex> {:ok, 1}
      iex> |> Monok.bind(fn x -> {:ok, x + 1} end)
      iex> |> Monok.bind(fn x -> {:ok, x * 2} end)
      {:ok, 4}

      iex> {:error, :reason}
      iex> |> Monok.bind(fn x -> {:ok, x + 1} end)
      {:error, :reason}
  """
  def bind({:ok, value}, function) do
    function.(value)
  end

  def bind({:error, reason}, _function) do
    {:error, reason}
  end
end
