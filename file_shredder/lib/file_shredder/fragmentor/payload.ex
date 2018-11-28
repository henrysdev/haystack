defmodule FileShredder.Fragmentor.Payload do
  
  defp stream_proc_payload(-1, _, _, _, frag_path) do
    IO.puts "dummy"
    Utils.Crypto.gen_hash("DUMMY")
  end
  defp stream_proc_payload(read_pos, chunk_size, hashkey, file_path, frag_path) do
    file_size = Utils.File.size(file_path) # TODO pass in from argument map

    encr_pl = File.open!(file_path)
    |> Utils.File.seek_read(read_pos, chunk_size)
    |> Utils.Crypto.encrypt(hashkey)

    File.write!(frag_path, encr_pl, [:raw, :read, :write])
    pl_hash = Utils.Crypto.gen_hash(encr_pl)
  end
  
  def process(read_pos, file_info_pid, frag_path) do
    hashkey    = State.Map.get(file_info_pid, :hashkey)
    file_path  = State.Map.get(file_info_pid, :file_path)
    chunk_size = State.Map.get(file_info_pid, :chunk_size)

    pl_hash = stream_proc_payload(read_pos, chunk_size, hashkey, file_path, frag_path)
  end

end