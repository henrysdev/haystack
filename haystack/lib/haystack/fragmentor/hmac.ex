defmodule Haystack.Fragmentor.HMAC do
  @moduledoc """
  The Haystack.Fragmentor.HMAC module is responsible for handling all functions 
  pertaining to HMACs during fragmentation.
  """
  
  @doc """
  Returns the generated HMAC value from the given fragment and file attributes.
  """
  def generate(frag_file, chunk_size, encr_file_name, encr_file_size, encr_pl_length, seq_id, hashkey) do
    [
      Utils.File.seek_read(frag_file, 0, chunk_size),
      encr_file_name, 
      encr_file_size, 
      encr_pl_length, 
      to_string(seq_id), 
      hashkey, 
    ] |> Utils.Crypto.gen_hash()
  end

end