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
    hmac_paths = Path.wildcard(dirpath)
  end

  defp deserialize(fragment, password) do
    Poison.Parser.parse!(fragment)
  end

end
