defmodule FileShredder.Fragmentor.Payload do
  
  def extract(in_fpath, read_pos, hashkey, chunk_size, file_size) when read_pos < file_size do
    File.open!(in_fpath, [:raw, :read], fn file -> 
      Utils.File.seek_read(file, read_pos, chunk_size)
      |> Utils.Crypto.encrypt(hashkey, :aes_ctr)
    end)
  end
  def extract(_, _, _, _, _), do: []

end