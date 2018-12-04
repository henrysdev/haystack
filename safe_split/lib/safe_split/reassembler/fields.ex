defmodule SafeSplit.Reassembler.Fields do
  @fname_buf_size 96
  @fsize_buf_size 32
  @pl_length_buf_size 32
  @hmac_size 32

  def deserialize_fields({_, false, _}, _), do: :error
  def deserialize_fields({fragment, true, _frag_size}, seekpos_pid) do
    frag_fields = %{
      :file_name => Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :file_name), @fname_buf_size),
      :file_size => Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :file_size), @fsize_buf_size),
      :pl_length => Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :pl_length), @pl_length_buf_size),
    }
    File.close fragment
    frag_fields
  end

  def decrypt_fields(:error, _), do: :error
  def decrypt_fields(field_map, hashkey) do
    decr_aes_cbc = fn x -> Utils.Crypto.decrypt(x, hashkey, :aes_cbc) end
    Map.keys(field_map)
    |> Enum.map(fn key -> {key, Map.get(field_map, key)} end)
    |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, key, decr_aes_cbc.(val)) end)
  end

  def extract_pl_length(frag_file, seekpos_pid, hashkey) do
    Utils.File.seek_read(frag_file, State.Map.get(seekpos_pid, :pl_length), @pl_length_buf_size)
    |> Utils.Crypto.decrypt(hashkey, :aes_cbc)
    |> String.to_integer()
  end

  def build_seek_map(frag_size) do
    {:ok, seekpos_pid} = State.Map.start_link(
      %{
        :hmac      => frag_size - @hmac_size,
        :pl_length => frag_size - @hmac_size - @pl_length_buf_size,
        :file_size => frag_size - @hmac_size - @pl_length_buf_size - @fsize_buf_size,
        :file_name => frag_size - @hmac_size - @pl_length_buf_size - @fsize_buf_size - @fname_buf_size,
        :payload   => 0,
      }
    )
    seekpos_pid
  end

end