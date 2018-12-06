defmodule Haystack.Fragmentor.Fields do
  @moduledoc """
  The Haystack.Fragmentor.Fields module is responsible for handling all 
  functions pertaining to fields during fragmentation.
  """

  @fname_buf_size 96
  @fsize_buf_size 32
  @pl_length_buf_size 32
  @hmac_size 32

  @doc """
  Return the pre-processed/encrypted fragment field value for file name
  """
  def file_name(file_name, hashkey) do
    Utils.Crypto.encrypt(file_name, hashkey, :aes_cbc, @fname_buf_size)
  end

  @doc """
  Return the pre-processed/encrypted fragment field value for payload size
  """
  def pl_length(file_size, chunk_size, hashkey, read_pos) do    
    pl_length = max(0, (chunk_size - max(0, (read_pos + chunk_size) - file_size )))
    |> Integer.to_string()
    |> Utils.Crypto.encrypt(hashkey, :aes_cbc, @pl_length_buf_size)
  end

  @doc """
  Return the pre-processed/encrypted fragment field value for file size
  """
  def file_size(file_size, hashkey) do
    file_size
    |> Integer.to_string()
    |> Utils.Crypto.encrypt(hashkey, :aes_cbc, @fsize_buf_size)
  end

  @doc """
  Return the total size (in bytes) of the fields portion of a fragment
  """
  def get_bytes_count() do
    @fname_buf_size + @fsize_buf_size + @pl_length_buf_size + @hmac_size
  end

end