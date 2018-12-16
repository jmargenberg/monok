defmodule MonokTest do
  @moduledoc """
  Provides robust tests for verifying the correct behaviour of the infix `~>`, `~>>` and `<~>` macros.

  These tests may look like overkill but the initial macro implementations of these macros passed simpler
  but seemingly adequate tests despite failing in some of the more complex situation tested below.

  The standard fmap, bind and lift functions have also been tested with the same test data for the sake
  of consistency.
  """

  use ExUnit.Case, async: true
  import Monok

  alias MonokTest.Helper

  doctest Monok, import: true, except: [:moduledoc]

  describe "fmap" do
    @tag :standard_functions

    test "chain with :ok tuple literal as input" do
      assert {:ok, 1}
             |> fmap(&Integer.to_string/1)
             |> fmap(&(&1 <> "!")) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    @tag :complex_tuple
    test "with complex :ok tuple input" do
      assert Helper.complex_tuple(:ok, 1)
             |> fmap(&Integer.to_string/1)
             |> fmap(&(&1 <> "!")) == {:ok, "1!"},
             "function is applied to value inside of :ok tuple"
    end

    test "chain with :error tuple literal as input" do
      assert {:error, :reason}
             |> fmap(&Integer.to_string/1)
             |> fmap(&(&1 <> "!")) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as input" do
      assert Helper.complex_tuple(:error, :reason)
             |> fmap(&Integer.to_string/1)
             |> fmap(&(&1 <> "!")) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    test "chain with list literal in :ok tuple literal" do
      assert {:ok, [1, 2, 3]}
             |> fmap(&Enum.map(&1, fn x -> x + 1 end))
             |> fmap(&Enum.sum/1)
             |> fmap(&div(&1, 2)) == {:ok, 4},
             "both functions are applied to list literal inside :ok tuple"
    end

    test "chain with map literal in :ok tuple literal" do
      assert {:ok, %{foo: 1}}
             |> fmap(&Map.put(&1, :bar, 2))
             |> fmap(fn map -> Map.update(map, :bar, nil, &(&1 + 2)) end) ==
               {:ok, %{foo: 1, bar: 4}},
             "function is applied to map literal inside :ok tuple"
    end
  end

  describe "~>" do
    @describetag :infix_operators

    test "chain with :ok tuple literal as input" do
      assert {:ok, 1}
             ~> (&Integer.to_string/1)
             ~> (&(&1 <> "!")) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    @tag :complex_tuple
    test "with complex :ok tuple input" do
      assert Helper.complex_tuple(:ok, 1)
             ~> (&Integer.to_string/1)
             ~> (&(&1 <> "!")) == {:ok, "1!"},
             "function is applied to value inside of :ok tuple"
    end

    test "chain with :error tuple literal as input" do
      assert {:error, :reason}
             ~> (&Integer.to_string/1)
             ~> (&(&1 <> "!")) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as input" do
      assert Helper.complex_tuple(:error, :reason)
             ~> (&Integer.to_string/1)
             ~> (&(&1 <> "!")) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    test "chain with list literal in :ok tuple literal" do
      assert {:ok, [1, 2, 3]}
             ~> (&Enum.map(&1, fn x -> x + 1 end))
             ~> (&Enum.sum/1)
             ~> (&div(&1, 2)) == {:ok, 4},
             "both functions are applied to list literal inside :ok tuple"
    end

    test "chain with map literal in :ok tuple literal" do
      assert {:ok, %{foo: 1}}
             ~> (&Map.put(&1, :bar, 2))
             ~> (&Map.update(&1, :bar, nil, fn x -> x + 2 end)) == {:ok, %{foo: 1, bar: 4}},
             "function is applied to map literal inside :ok tuple"
    end
  end

  describe "lift" do
    @tag :standard_functions

    test "chain with :ok tuple literal as input and functions in :ok tuple" do
      assert {:ok, 1}
             |> lift({:ok, &Integer.to_string/1})
             |> lift({:ok, &(&1 <> "!")}) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    @tag :complex_tuple
    test "chain with complex :ok tuple as input and functions in :ok tuple" do
      assert Helper.complex_tuple(:ok, 1)
             |> lift({:ok, &Integer.to_string/1})
             |> lift({:ok, &(&1 <> "!")}) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    test "chain with :error tuple literal as input and functions in :ok tuple" do
      assert {:error, :reason}
             |> lift({:ok, &Integer.to_string/1})
             |> lift({:ok, &(&1 <> "!")}) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as input and functions in :ok tuple" do
      assert Helper.complex_tuple(:error, :reason)
             |> lift({:ok, &Integer.to_string/1})
             |> lift({:ok, &(&1 <> "!")}) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    test "chain with :error tuple literal as first function in chain" do
      assert {:ok, 1}
             |> lift({:error, :reason})
             |> lift({:ok, &(&1 <> "!")}) == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as first function in chain" do
      assert {:ok, 1}
             |> lift(Helper.complex_tuple(:error, :reason))
             |> lift({:ok, &(&1 <> "!")}) == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    test "chain with :error tuple literal as last function in chain" do
      assert {:ok, 1}
             |> lift({:ok, &Integer.to_string/1})
             |> lift({:error, :reason}) == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as last function in chain" do
      assert {:ok, 1}
             |> lift({:ok, &Integer.to_string/1})
             |> lift(Helper.complex_tuple(:error, :reason)) == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    test "chain with list literal in :ok tuple literal" do
      assert {:ok, [1, 2, 3]}
             |> lift({:ok, &Enum.map(&1, fn x -> x + 1 end)})
             |> lift({:ok, &Enum.sum/1})
             |> lift({:ok, &div(&1, 2)}) == {:ok, 4},
             "both functions are applied to list literal inside :ok tuple"
    end

    test "chain with map literal in :ok tuple literal" do
      assert {:ok, %{foo: 1}}
             |> lift({:ok, &Map.put(&1, :bar, 2)})
             |> lift({:ok, fn map -> Map.update(map, :bar, nil, &(&1 + 2)) end}) ==
               {:ok, %{foo: 1, bar: 4}},
             "function is applied to map literal inside :ok tuple"
    end
  end

  describe "<~>" do
    @tag :infix_operators

    test "chain with :ok tuple literal as input and functions in :ok tuple" do
      assert {:ok, 1}
             <~> {:ok, &Integer.to_string/1}
             <~> {:ok, &(&1 <> "!")} == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    @tag :complex_tuple
    test "chain with complex :ok tuple as input and functions in :ok tuple" do
      assert Helper.complex_tuple(:ok, 1)
             <~> {:ok, &Integer.to_string/1}
             <~> {:ok, &(&1 <> "!")} == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    test "chain with :error tuple literal as input and functions in :ok tuple" do
      assert {:error, :reason}
             <~> {:ok, &Integer.to_string/1}
             <~> {:ok, &(&1 <> "!")} == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as input and functions in :ok tuple" do
      assert Helper.complex_tuple(:error, :reason)
             <~> {:ok, &Integer.to_string/1}
             <~> {:ok, &(&1 <> "!")} == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    test "chain with :error tuple literal as first function in chain" do
      assert {:ok, 1}
             <~> {:error, :reason}
             <~> {:ok, &(&1 <> "!")} == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as first function in chain" do
      assert {:ok, 1}
             <~> Helper.complex_tuple(:error, :reason)
             <~> {:ok, &(&1 <> "!")} == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    test "chain with :error tuple literal as last function in chain" do
      assert {:ok, 1}
             <~> {:ok, &Integer.to_string/1}
             <~> {:error, :reason} == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as last function in chain" do
      assert {:ok, 1}
             <~> {:ok, &Integer.to_string/1}
             <~> Helper.complex_tuple(:error, :reason) == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    test "chain with list literal in :ok tuple literal" do
      assert {:ok, [1, 2, 3]}
             <~> {:ok, &Enum.map(&1, fn x -> x + 1 end)}
             <~> {:ok, &Enum.sum/1}
             <~> {:ok, &div(&1, 2)} == {:ok, 4},
             "both functions are applied to list literal inside :ok tuple"
    end

    test "chain with map literal in :ok tuple literal" do
      assert {:ok, %{foo: 1}}
             <~> {:ok, &Map.put(&1, :bar, 2)}
             <~> {:ok, fn map -> Map.update(map, :bar, nil, &(&1 + 2)) end} ==
               {:ok, %{foo: 1, bar: 4}},
             "function is applied to map literal inside :ok tuple"
    end
  end

  describe "bind" do
    @tag :standard_functions

    test "chain with :ok tuple literal as input and functions returning :ok tuples" do
      assert {:ok, 1}
             |> bind(&{:ok, Integer.to_string(&1)})
             |> bind(&{:ok, &1 <> "!"}) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    @tag :complex_tuple
    test "chain with complex :ok tuple as input and functions returning :ok tuples" do
      assert Helper.complex_tuple(:ok, 1)
             |> bind(&{:ok, Integer.to_string(&1)})
             |> bind(&{:ok, &1 <> "!"}) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    test "chain with :error tuple literal as input and functions returning :ok tuples" do
      assert {:error, :reason}
             |> bind(&{:ok, Integer.to_string(&1)})
             |> bind(&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as input and functions returning :ok tuples" do
      assert Helper.complex_tuple(:error, :reason)
             |> bind(&{:ok, Integer.to_string(&1)})
             |> bind(&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    test "chain with first function in chain returning :error tuple literal" do
      assert {:ok, 1}
             |> bind(fn _ -> {:error, :reason} end)
             |> bind(&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    @tag :complex_tuple
    test "chain with first function in chain returning complex :error tuple as " do
      assert {:ok, 1}
             |> bind(fn _ -> Helper.complex_tuple(:error, :reason) end)
             |> bind(&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    test "chain with last function in chain returning :error tuple literal" do
      assert {:ok, 1}
             |> bind(&{:ok, Integer.to_string(&1)})
             |> bind(fn _ -> {:error, :reason} end) == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    @tag :complex_tuple
    test "chain with last function in chain returning complex :error tuple" do
      assert {:ok, 1}
             |> bind(&{:ok, Integer.to_string(&1)})
             |> bind(fn _ -> Helper.complex_tuple(:error, :reason) end) == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    test "chain with list literal in :ok tuple literal" do
      assert {:ok, [1, 2, 3]}
             |> bind(&{:ok, Enum.map(&1, fn x -> x + 1 end)})
             |> bind(&{:ok, Enum.sum(&1)})
             |> bind(&{:ok, div(&1, 2)}) == {:ok, 4},
             "both functions are applied to list literal inside :ok tuple"
    end

    test "chain with map literal in :ok tuple literal" do
      assert {:ok, %{foo: 1}}
             |> bind(&{:ok, Map.put(&1, :bar, 2)})
             |> bind(fn map -> {:ok, Map.update(map, :bar, nil, &(&1 + 2))} end) ==
               {:ok, %{foo: 1, bar: 4}},
             "function is applied to map literal inside :ok tuple"
    end
  end

  describe "~>>" do
    @tag :infix_operators
    test "chain with :ok tuple literal as input and functions returning :ok tuples" do
      assert {:ok, 1}
             ~>> (&{:ok, Integer.to_string(&1)})
             ~>> (&{:ok, &1 <> "!"}) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    @tag :complex_tuple
    test "chain with complex :ok tuple as input and functions returning :ok tuples" do
      assert Helper.complex_tuple(:ok, 1)
             ~>> (&{:ok, Integer.to_string(&1)})
             ~>> (&{:ok, &1 <> "!"}) == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    test "chain with :error tuple literal as input and functions returning :ok tuples" do
      assert {:error, :reason}
             ~>> (&{:ok, Integer.to_string(&1)})
             ~>> (&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    @tag :complex_tuple
    test "chain with complex :error tuple as input and functions returning :ok tuples" do
      assert Helper.complex_tuple(:error, :reason)
             ~>> (&{:ok, Integer.to_string(&1)})
             ~>> (&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    test "chain with first function in chain returning a :error tuple literal" do
      assert {:ok, 1}
             ~>> fn _ -> {:error, :reason} end
             ~>> (&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    @tag :complex_tuple
    test "chain with first function in chain returning a complex :error tuple" do
      assert {:ok, 1}
             ~>> fn _ -> Helper.complex_tuple(:error, :reason) end
             ~>> (&{:ok, &1 <> "!"}) == {:error, :reason},
             ":error tuple is carried through without the subsequent function being applied"
    end

    test "chain with last function in chain returning a :error tuple literal" do
      assert {:ok, 1}
             ~>> (&{:ok, Integer.to_string(&1)})
             ~>> fn _ -> {:error, :reason} end == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    @tag :complex_tuple
    test "chain with last function in chain returning a complex :error tuple" do
      assert {:ok, 1}
             ~>> (&{:ok, Integer.to_string(&1)})
             ~>> fn _ -> Helper.complex_tuple(:error, :reason) end == {:error, :reason},
             ":error tuple from last function in chain is returned as result of chain"
    end

    test "chain with list literal in :ok tuple literal" do
      assert {:ok, [1, 2, 3]}
             ~>> (&{:ok, Enum.map(&1, fn x -> x + 1 end)})
             ~>> (&{:ok, Enum.sum(&1)})
             ~>> (&{:ok, div(&1, 2)}) == {:ok, 4},
             "both functions are applied to list literal inside :ok tuple"
    end

    test "chain with map literal in :ok tuple literal" do
      assert {:ok, %{foo: 1}}
             ~>> (&{:ok, Map.put(&1, :bar, 2)})
             ~>> fn map -> {:ok, Map.update(map, :bar, nil, &(&1 + 2))} end ==
               {:ok, %{foo: 1, bar: 4}},
             "function is applied to map literal inside :ok tuple"
    end
  end
end
