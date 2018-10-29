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
  defdelegate fragment(file, n, password), to: FileShredder.Fragmentor

  defdelegate reassemble(dir, password), to:  FileShredder.Reassembler

end
