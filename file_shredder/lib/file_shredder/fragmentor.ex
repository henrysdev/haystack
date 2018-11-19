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

  defp dummy(chunk_size) do
    if @debug do IO.puts("dummy...") end
    chunk = to_string(:string.chars(0, chunk_size-1)) |> Utils.Crypto.pad(chunk_size)
    %{"payload" => chunk}
  end

  defp gen_dummies(0, _chunk_size), do: []
  defp gen_dummies(dummy_count, chunk_size) do
    for _ <- 0..dummy_count-1, do: dummy(chunk_size)
  end

  def fragment(file_path, n, password) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    file_size = Utils.File.size(file_path)

    chunk_size = (Float.ceil(file_size/n) |> trunc()) + 1
    padding = (n * (chunk_size - 1)) - file_size
    partial_pad = rem(padding, (chunk_size - 1))
    dummy_count = div((padding - partial_pad), (chunk_size - 1))

    frag_paths = file_path
    |> File.stream!([], chunk_size - 1)
    |> Stream.map(&pad_frag(&1, chunk_size)) # pad frags
    |> Stream.concat(gen_dummies(dummy_count, chunk_size)) # add dummy frags
    |> Stream.with_index() # add sequence ID
    #|> Enum.map(&finish_frag(&1, hashkey, file_name, file_size))
    |> Utils.Parallel.pooled_map(&finish_frag(&1, hashkey, file_name, file_size))
    |> Enum.to_list()

    {:ok, frag_paths}
  end
  def fragment(_, _, _), do: :error

  defp finish_frag({ fragment, seq_id }, hashkey, file_name, file_size) do
    file_size = file_size |> Integer.to_string()
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
    plaindata = Map.get(map, field)
    cipherdata = Utils.Crypto.encrypt(plaindata, hashkey, pad)
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
      hashkey
    ]
    hmac = Utils.Crypto.gen_multi_hash(hmac_parts)
    { Map.put(fragment, "hmac", hmac), seq_hash }
  end

  defp serialize_raw({ fragment, seq_hash }) do
    {
      [
        Map.get(fragment, "payload"), #   <> # X
        Map.get(fragment, "file_size"), # <> # 32
        Map.get(fragment, "file_name"), # <> # 96
        Map.get(fragment, "hmac"),        # 32
      ],
      seq_hash
    }
  end

  defp write_out({ fragment, seq_hash }) do
    if @debug do IO.puts("write_out...") end
    seq_hash = Base.encode16(seq_hash)
    file_path = "debug/out/#{seq_hash}.frg"
    Utils.File.write(file_path, fragment)
    file_path
  end

end
