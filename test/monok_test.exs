defmodule MonokTest do
  use ExUnit.Case, async: true

  doctest Monok, import: true, except: [:moduledoc]
end
