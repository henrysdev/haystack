defmodule FileShredder.Fragmentor.Payload do
  
  defp stream_proc_payload(-1, _, _, _, frag_path) do
    IO.puts "dummy"
    { 0, Utils.Crypto.gen_hash("DUMMY") }
  end
  defp stream_proc_payload(read_pos, chunk_size, hashkey, file_path, frag_path) do
    file_size = Utils.File.size(file_path) # TODO pass in from argument map
    
    pad_amt = max(0, (read_pos + chunk_size) - file_size )

    encr_pl = File.open!(file_path)
    |> Utils.File.seek_read(read_pos, chunk_size)
    |> Utils.Crypto.encrypt(hashkey)

    File.write!(frag_path, encr_pl, [:raw, :read, :write])

    pl_hash = Utils.Crypto.gen_hash(encr_pl)

    { pad_amt, pl_hash }
  end
  
  def extract_and_process({seq_id, read_pos}, file_info_pid) do
    hashkey   = State.Map.get(file_info_pid, :hashkey)
    out_dir   = State.Map.get(file_info_pid, :out_dir)
    frag_size = State.Map.get(file_info_pid, :frag_size)
    file_path  = State.Map.get(file_info_pid, :file_path)
    chunk_size   = State.Map.get(file_info_pid, :chunk_size)

    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id]) |> Base.encode16()
    frag_path = Path.dirname(out_dir) <> "/" <> seq_hash <> ".frg"
    Utils.File.create(frag_path, frag_size)

    { pad_amt, pl_hash} = stream_proc_payload(read_pos, chunk_size, hashkey, file_path, frag_path)
    IO.inspect pad_amt, label: "pad_amt"
    IO.inspect pl_hash, label: "pl_hash"
    frag_path
  end

end