defmodule FileShredder.Fragmentor.Payload do
  
  defp process_in_chunks() do
    # 1. Stream content from source_file[read_pos] -> temporary scratch file
    # 2. Encrypt file with block cipher using Unix system commands
    # 3. return hash of the temp file
  end
  
  def extract_and_process({seq_id, read_pos}, file_info_pid) do
    hashkey   = State.Map.get(file_info_pid, :hashkey)
    out_dir   = State.Map.get(file_info_pid, :out_dir)
    frag_size = State.Map.get(file_info_pid, :frag_size)

    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id]) |> Base.encode16()

    frag_path = Path.dirname(out_dir) <> "/" <> seq_hash
    Utils.File.create(frag_path, frag_size)

    frag_path
  end

end