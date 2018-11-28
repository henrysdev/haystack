defmodule FileShredder.Fragmentor do

  @moduledoc """
  Documentation for FileShredder.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FileShredder.hello()
      :world

  """
  # DEBUG
  @debug false

  @max_file_name_size 96
  @max_file_size_int 32

  defp pad_frag(chunk, chunk_size) do
    if @debug do IO.puts("pad_frag...") end
    chunk = Utils.Crypto.pad(chunk, chunk_size)
    %{"payload" => chunk}
  end

  def fragment(file_path, n, password) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    file_size = Utils.File.size(file_path)

    chunk_size = (Float.ceil(file_size/n) |> trunc()) + 1
    padding = (n * (chunk_size - 1)) - file_size
    partial_pad = rem(padding, (chunk_size - 1))
    dummy_count = div((padding - partial_pad), (chunk_size - 1))
    
    {:ok, file_info_pid} = State.Map.start_link(
      %{
        :hashkey   => hashkey,
        :file_name => file_name,
        :file_size => file_size,
      }
    )

    frag_paths = file_path
    |> File.stream!([], chunk_size - 1)
    |> Stream.map(&pad_frag(&1, chunk_size)) # pad frags
    |> FileShredder.Fragmentor.Dummies.generate(dummy_count, chunk_size)
    |> Stream.with_index() # add sequence ID
    #|> Enum.map(&finish_frag(&1, file_info_pid))
    |> Utils.Parallel.pooled_map(&finish_frag(&1, file_info_pid))

    {:ok, frag_paths}
  end
  def fragment(_, _, _), do: :error

  defp finish_frag({ fragment, seq_id }, file_info_pid) do
    hashkey   = State.Map.get(file_info_pid, :hashkey)
    file_name = State.Map.get(file_info_pid, :file_name)
    file_size = State.Map.get(file_info_pid, :file_size) |> Integer.to_string()
    fragment
    |> add_field("file_name", file_name)
    |> add_field("file_size", file_size)
    |> encr_field("payload", hashkey)
    |> encr_field("file_name", hashkey, @max_file_name_size)
    |> encr_field("file_size", hashkey, @max_file_size_int)
    |> add_seq_hash(hashkey, seq_id)
    |> add_hmac(hashkey)
    |> serialize_raw()
    |> write_out()
  end

  defp add_field(map, field, value) do
    Map.put(map, field, value)
  end
  
  defp encr_field(map, field, hashkey, pad \\ 32) do
    if @debug do IO.puts("encrypting #{field}...") end
    cipherdata = Map.get(map, field) |> Utils.Crypto.encrypt(hashkey, pad)
    Map.put(map, field, cipherdata)
  end
  
  defp add_seq_hash(fragment, hashkey, seq_id) do
    if @debug do IO.puts("add_seq_hash...") end
    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id])
    { fragment, seq_hash }
  end

  defp add_hmac({ fragment, seq_hash }, hashkey) do
    if @debug do IO.puts("add_hmac...") end
    hmac_parts = [
      Map.get(fragment, "payload"),
      Map.get(fragment, "file_name"),
      Map.get(fragment, "file_size"),
      seq_hash,
      hashkey,
    ]
    hmac = Utils.Crypto.gen_multi_hash(hmac_parts)
    { Map.put(fragment, "hmac", hmac), seq_hash }
  end

  defp serialize_raw({ fragment, seq_hash }) do
    {
      [
        Map.get(fragment, "payload"),
        Map.get(fragment, "file_size"),
        Map.get(fragment, "file_name"),
        Map.get(fragment, "hmac"),
      ],
      seq_hash
    }
  end

  defp write_out({ fragment, seq_hash }) do
    if @debug do IO.puts("write_out...") end
    seq_hash = Base.encode16(seq_hash)
    frag_path = "debug/out/#{seq_hash}.frg"
    Utils.File.write(frag_path, fragment)
    frag_path
  end

end
