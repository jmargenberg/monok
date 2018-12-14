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
end
