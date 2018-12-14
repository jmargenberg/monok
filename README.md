# Monok

Provides `|$>`, `|*>` and `|=>` as alternatives to the `|>` operator that act as a simple functor, applicative and mondad operator for `{:ok, result}` and `{:error, reason}` tuples.

## Installation

The package can be installed by adding `monok` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:monok, "~> 0.1.0"}
  ]
end
```

Docs can be found at [https://hexdocs.pm/monok](https://hexdocs.pm/monok).
