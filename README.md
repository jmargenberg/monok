# Monok
[![Build Status](https://travis-ci.org/jmargenberg/monok.svg?branch=master)](https://travis-ci.org/jmargenberg/monok) [![Coverage Status](https://coveralls.io/repos/github/jmargenberg/monok/badge.svg?branch=master)](https://coveralls.io/github/jmargenberg/monok?branch=master) [![Hex.pm](https://img.shields.io/hexpm/v/monok.svg)](https://hex.pm/packages/monok)

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
...> ~> (&Enum.sum/1)
...> ~> (&div(&1, 2))
{:ok, 3}
```

If the input is an `{:error, reason}` tuple it is carried through the pipeline without applying any
transformations.

```
iex> {:error, :reason}
...> ~> (&Enum.sum/1)
...> ~> (&div(&1, 2))
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
...> ~> (&Integer.to_string/1)
...> ~>> (&(if &1 |> String.length() > 0, do: {:ok, &1 <> "!"}, else: {:error, :empty_string}))
{:ok, "7!"}
```

## Potential Changes

My initial hope was to implement the pipe operators as macros that would behave more similarily to `|>`.

For example `{:ok, 1} ~> (&Integer.to_string/1)` would be written as `{:ok, 1} ~> Integer.to_string()`.

Unfortunately it looks like this is infeasible using macros in elixir but I might have another try
at some point.
