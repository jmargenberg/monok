# Monok [![Build Status](https://travis-ci.org/jmargenberg/monok.svg?branch=master)](https://travis-ci.org/jmargenberg/monok) [![Coverage Status](https://coveralls.io/repos/github/jmargenberg/monok/badge.svg?branch=master)](https://coveralls.io/github/jmargenberg/monok?branch=master)

**_ NOTE: this library is unfinished and has several unfixed issues, feel free to look through or help out but definitely don't depend on it. _**

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

These alternative pipe operators don't have to be used in seperate pipelines but can be used in conjuction,
including with the standard `|>` pipe operator.

```
iex> 7
iex> |> (&(if &1 > 5, do: {:ok, &1}, else: {:error, :too_low})).()
iex> ~> Integer.to_string()
iex> ~>> (&(if &1 |> length() > 0, do: &1 ++ "!", else: {:error, :empty_string})).()
{:ok, "7!"}
```
