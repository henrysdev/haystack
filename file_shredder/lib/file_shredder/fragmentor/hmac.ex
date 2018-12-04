defmodule FileShredder.Fragmentor.HMAC do
  
  def generate(frag_file, chunk_size, encr_file_name, encr_file_size, encr_pl_length, seq_id, hashkey) do
    hmac = [
      Utils.File.seek_read(frag_file, 0, chunk_size),
      encr_file_name, 
      encr_file_size, 
      encr_pl_length, 
      to_string(seq_id), 
      hashkey, 
    ] |> Utils.Crypto.gen_hash()
  end

end