defmodule MonokTest do
  use ExUnit.Case, async: true
  import Monok

  doctest Monok, import: true, except: [:moduledoc]

  setup do
    complex_tuple_func = fn atom, content ->
      case atom do
        :ok -> {:ok, content}
        other -> {other, content}
      end
    end

    %{complex_tuple_func: complex_tuple_func}
  end

  describe "~>" do
    @describetag :infix_operators

    test "chain with :ok tuple literal as input" do
      assert {:ok, 1}
             ~> Integer.to_string()
             ~> (&(&1 <> "!")).() == {:ok, "1!"},
             " functions are applied sequentially to value inside of :ok tuple"
    end

    test "chain with :error tuple literal as input" do
      assert {:error, :reason}
             ~> Integer.to_string()
             ~> (&(&1 <> "!")).() == {:error, :reason},
             ":error tuple is carried through without either function being applied"
    end

    test "chain with list literal in :ok tuple literal" do
      assert {:ok, [1, 2, 3]}
             ~> Enum.map(fn x -> x + 1 end)
             ~> Enum.sum()
             ~> div(2) == {:ok, 4},
             "both functions are applied to list literal inside :ok tuple"
    end

    test "chain with map literal in :ok tuple literal" do
      assert {:ok, %{foo: 1}}
             ~> Map.put(:bar, 2)
             ~> Map.update(:bar, nil, &(&1 + 2)) == {:ok, %{foo: 1, bar: 4}},
             "function is applied to map literal inside :ok tuple"
    end

    # commented out due to infinite compilation bug in ~> macro
    # @tag :complex_input
    # test "with complex :ok tuple input", %{complex_tuple_func: complex_tuple_func} do
    #   assert complex_tuple_func.(:ok, 1)
    #          ~> Integer.to_string()
    #          ~> (&(&1 <> "!")).() == {:ok, "1!"},
    #          "function is applied to value inside of :ok tuple"
    # end
  end
end
