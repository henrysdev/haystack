defmodule FileShredder do
  @moduledoc """
  Documentation for FileShredder.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FileShredder.hello()
      :world

  """
  defdelegate fragment(filepath, n, password), to: FileShredder.Fragmentor

  defdelegate reassemble(dirpath, password), to:  FileShredder.Reassembler

end
