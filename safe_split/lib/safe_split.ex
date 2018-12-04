defmodule SafeSplit do
  @moduledoc """
  Documentation for SafeSplit.
  """

  @doc """
  Hello world.

  ## Examples

      #iex> SafeSplit.fragment()
      #:world

  """
  defdelegate fragment(filepath, n, password, outdir), to: SafeSplit.Fragmentor

  defdelegate reassemble(dirpath, password, outdir), to: SafeSplit.Reassembler

end
