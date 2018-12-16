ExUnit.start()

defmodule MonokTest.Helper do
  @doc """
  Returns a tuple that cannot be inferred with Macro.expand. i.e. it must be fully evaluated.

  This is for testing that macros behave correctly when recieving realistic dynamic tuple input rather than
  static tuple literals that can may be given as a identified in a quoted expression without realy evalutation.
  """
  def complex_tuple(atom, content) do
    case atom do
      # this
      :ok -> {:ok, content}
      other -> {other, content}
    end
  end
end
