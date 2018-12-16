ExUnit.start()

defmodule MonokTest.Helper do
  @doc """
  Returns a tuple that cannot be inferred with `Macro.expand/2`. i.e. it must be fully evaluated.

  This is for testing that macros behave correctly when recieving realistic dynamic tuple input rather than
  static tuple literals that can may be given as a identified in a quoted expression without realy evalutation.
  """
  def complex_tuple(atom, content) do
    case atom do
      # Case statement is redundant but prevents the returned tuple from being expanded to the root node of a quoted expression via Macro.expand/2
      :ok -> {:ok, content}
      other -> {other, content}
    end
  end
end
