defmodule FileShredder do
  @moduledoc """
  Documentation for FileShredder.
  """

  @doc """
  Hello world.

  ## Examples

      #iex> FileShredder.fragment()
      #:world

  """
  defdelegate fragment(filepath, n, password, outdir), to: FileShredder.Fragmentor

  defdelegate reassemble(dirpath, password, outdir), to: FileShredder.Reassembler

end
