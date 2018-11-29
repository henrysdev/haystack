defmodule FileShredder.Fragmentor.Payload do
  
  def extract(-1, file_info_pid), do: []
  def extract(read_pos, file_info_pid) do
    file_path  = State.Map.get(file_info_pid, :file_path)
    chunk_size = State.Map.get(file_info_pid, :chunk_size)

    encr_pl = File.open!(file_path)
    |> Utils.File.seek_read(read_pos, chunk_size)
  end

end