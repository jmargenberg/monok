defmodule Monok do
  @moduledoc """
  #### _Monad on :ok_

  Provides the infix pipe operators `~>`, `~>>`, and `<~>` for writing clean pipelines that treat `{:ok, result}`
  and `{:error, reason}` tuples like functors, monads or applicatives.

  Also provides the functions `fmap`, `bind` and `lift` as which are functionally identical but are less cryptic and
  can be used without overriding any inifix operators which could potentially conflict with other libraries.

  ## Why would you ever do this?
  Whilst writing overriding infix operators is generally considered bad practice I thought I'd try this out
  given just how freqently `{:ok, result}` and `{:error, reason}` tuples are encountered in Elixir.

  ## Functor Pipelines
  Allows you to write clean pipelines that transforms values inside of `{:ok, value}` tuples.

  ```
  iex> {:ok, [1, 2, 3]}
  ...> ~> Enum.sum()
  ...> ~> div(2)
  {:ok, 3}
  ```

  If the input is an `{:error, reason}` tuple it is carried through the pipeline without applying any
  transformations.

  ```
  iex> {:error, :reason}
  ...> ~> Enum.sum()
  ...> ~> div(2)
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
  ...> ~>> decrement
  ...> ~>> decrement
  {:ok, 1}
  ```

  If at any point in the pipeline an `{:error, reason}` tuple is returned it is carried through without
  any of the transformation functions being applied.

  ```
  iex> decrement = fn
  ...>   x when x > 0 -> {:ok, x - 1}
  ...>   _ -> {:error, :input_too_small}
  ...>  end
  iex>
  ...> {:ok, 3}
  ...> ~>> (fn _ -> {:error, :contrived_example} end)
  ...> ~>> decrement
  ...> ~>> decrement
  {:error, :contrived_example}
  ```

  ## Mixed Pipelines
  These pipe operators don't have to be used in seperate pipelines but can be used together or even with the `|>`
  standard pipe operator.

  ```
  iex> 7
  ...> |> (&(if &1 > 5, do: {:ok, &1}, else: {:error, :too_low})).()
  ...> ~> Integer.to_string()
  ...> ~>> (&(if &1 |> String.length() > 0, do: {:ok, &1 <> "!"}, else: {:error, :empty_string}))
  {:ok, "7!"}
  ```

  ## Potential Changes
  My initial hope was to implement the operators as macros that would behave more similarily to `|>`.
  For example `{:ok, 1} ~> (&Integer.to_string/1)` could be written as `{:ok, 1} ~> Integer.to_string()`.

  Unfortunately it looks like this is infeasible using macros and in elixir but I might try again
  at some point.
  """

  @doc """
  Applies a function to a value wrapped in an ok tuple, has no effect if given an error tuple.

  ## Examples

      iex> {:ok, [1, 2, 3]}
      ...> |> Monok.fmap(&Enum.sum/1)
      {:ok, 6}

      iex> {:error, :reason}
      ...> |> Monok.fmap(&Enum.sum/1)
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

      iex> {:ok, [1, 2, 3]}
      ...> |> Monok.lift({:ok, &Enum.sum/1})
      {:ok, 6}

      iex> {:ok, 1}
      ...> |> Monok.lift({:error, :reason})
      {:error, :reason}

      iex> {:error, :reason}
      ...> |> Monok.lift({:ok, &Enum.sum/1})
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

      iex> {:ok, [1, 2, 3]}
      ...> |> Monok.bind(fn x -> {:ok, Enum.sum(x)} end)
      {:ok, 6}

      iex> {:ok, [1, 2, 3]}
      ...> |> Monok.bind(fn _ -> {:error, :reason} end)
      {:error, :reason}

      iex> {:error, :reason}
      ...> |> Monok.bind(fn x -> {:ok, Enum.sum(x)} end)
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

  Treats input as value_tuple a functor.

  Applies a function to a value wrapped in an ok tuple, has no effect if given an error tuple.

  ## Examples

      iex> {:ok, [1, 2, 3]}
      ...> ~> Enum.sum()
      {:ok, 6}

      iex> {:error, :reason}
      ...> ~> Enum.sum()
      {:error, :reason}

  """

  defmacro quote_calue_tuple ~> {function, metadata, call_args} do
    quote do
      case unquote(quote_calue_tuple) do
        {:ok, value} -> {:ok, unquote({function, metadata, [quote(do: value) | call_args]})}
        other -> other
      end
    end
  end

  @doc """
  Infix lift operator.

  Treats the function_tuple as an applicative.

  Applies a function wrapped in an :ok tuple to a value wrapped in an :ok tuple.

  Carries through an :error tuple if either the value or function arguments are given as :error tuples instead of :ok tuples.

  ## Examples

      iex> {:ok, [1, 2, 3]}
      ...>  <~> {:ok, &Enum.sum/1}
      {:ok, 6}

      iex> {:ok, 1}
      ...> <~> {:error, :reason}
      {:error, :reason}

      iex> {:error, :reason}
      ...> <~> {:ok, &Enum.sum/1}
      {:error, :reason}
  """
  def value_tuple <~> function_tuple do
    value_tuple |> lift(function_tuple)
  end

  @doc """
  Infix bind operator.

  Treats the value_tuple and tuple_function as monads.

  Applies a function that returns a value wrapped in an :ok tuple to a value wrapped in an :ok tuple.

  Carries through an :error tuple if either the value argument is given as an :error tuple or the function returns an
  :error tuple when applied to the value.

  ## Examples

      iex> {:ok, [1, 2, 3]}
      ...> ~>> (fn x -> {:ok, Enum.sum(x)} end)
      {:ok, 6}

      iex> {:ok, [1, 2, 3]}
      ...>  ~>> (fn _ -> {:error, :reason} end)
      {:error, :reason}

      iex> {:error, :reason}
      ...>  ~>> (fn x -> {:ok, Enum.sum(x)} end)
      {:error, :reason}
  """
  def value_tuple ~>> tuple_function do
    value_tuple |> bind(tuple_function)
  end
end
