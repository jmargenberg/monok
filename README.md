# Monok

Provides simple functor (`|$>`), applicative (`|*>`) and monad (`|=>`) operators for writing pipelines involving functions that return the common `{:ok, result}` or `{:error, reason}` tuples.

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
