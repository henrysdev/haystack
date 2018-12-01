defmodule FileShredder.Fragmentor.Payload do
  
  def extract(_, _, _, true), do: []
  def extract(file_path, read_pos, chunk_size, false) do
    encr_pl = File.open!(file_path)
    |> Utils.File.seek_read(read_pos, chunk_size)
  end

end