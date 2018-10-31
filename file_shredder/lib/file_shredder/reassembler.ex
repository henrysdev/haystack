defmodule FileShredder.Reassembler do
  @moduledoc """
  Documentation for FileShredder.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FileShredder.hello()
      :world

  """
  def reassemble(dirpath, password) do
    IO.puts("reassemble")
    hmac_paths = Path.wildcard(dirpath)
  end

end
