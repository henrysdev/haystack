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

  defp pad_frag(chunk, chunk_size) do
    pad_amt = chunk_size - byte_size(chunk)
    chunk = chunk <> to_string(:string.chars(0, pad_amt))
    {chunk, pad_amt}
  end

  defp dummy(chunk_size) do
    pad_amt = 0
    chunk = to_string(:string.chars(0, chunk_size))
    {chunk, pad_amt}
  end

  defp gen_dummies(0, _chunk_size), do: []
  defp gen_dummies(dummy_count, chunk_size) do
    IO.inspect dummy_count
    for _ <- 0..dummy_count-1, do: dummy(chunk_size)
  end

  def fragment(file_path, n, password) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    %{ size: file_size } = File.stat! file_path
    if n > file_size do
      :error
    else
      chunk_size = Float.ceil(file_size/n) |> trunc()
      padding = (n * chunk_size) - file_size
      partial_pad = rem(padding, chunk_size)
      dummy_count = div((padding - partial_pad), chunk_size)
      non_dummy_count = n - dummy_count

      frag_paths = file_path
      |> File.stream!([], chunk_size)
      |> Stream.map(&pad_frag(&1, chunk_size)) # pad frags + add pad_amt
      |> Stream.concat(gen_dummies(dummy_count, chunk_size)) # add dummy frags
      |> Enum.to_list()
      |> IO.inspect()
      |> Stream.map(&Tuple.append(&1, file_name)) # add file_size
      |> Stream.map(&Tuple.append(&1, file_size)) # add file_size
      |> Stream.with_index() # add sequence IDs
      #|> Enum.map(&finish_frag(&1, hashkey))
      |> Utils.Parallel.pmap(&finish_frag(&1, hashkey))
      |> Enum.to_list()

      {:ok, frag_paths}
    end
  end
  def fragment(_, _, _), do: :error

  defp finish_frag({ { payload, pad_amt, file_name, file_size }, seq_id }, hashkey) do
    { payload, pad_amt, file_name, file_size }
    |> encr_payload(hashkey)
    |> encr_pad_amt(hashkey)
    |> encr_file_name(hashkey)
    |> encr_file_size(hashkey)
    |> add_seq_hash(hashkey, seq_id)
    |> add_hmac(hashkey)
    |> serialize()
    |> write_out()
  end

  defp encr_payload({ payload, pad_amt, file_name, file_size }, hashkey) do
    payload = Utils.Crypto.encrypt(payload, hashkey)
    { payload, pad_amt, file_name, file_size }
  end

  defp encr_pad_amt({ payload, pad_amt, file_name, file_size }, hashkey) do
    pad_amt = Utils.Crypto.encrypt(Integer.to_string(pad_amt), hashkey)
    { payload, pad_amt, file_name, file_size }
  end

   defp encr_file_name({ payload, pad_amt, file_name, file_size }, hashkey) do
    file_name = Utils.Crypto.encrypt(file_name, hashkey)
    { payload, pad_amt, file_name, file_size}
  end
  
  defp encr_file_size({ payload, pad_amt, file_name, file_size }, hashkey) do
    file_size = Utils.Crypto.encrypt(Integer.to_string(file_size), hashkey)
    { payload, pad_amt, file_name, file_size}
  end
  
  defp add_seq_hash({ payload, pad_amt, file_name, file_size }, hashkey, seq_id) do
    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id])
    { payload, pad_amt, file_name, file_size, seq_hash }
  end

  defp add_hmac({ payload, pad_amt, file_name, file_size, seq_hash }, hashkey) do
    hmac = Utils.Crypto.gen_multi_hash([payload, pad_amt, file_name, file_size, seq_hash, hashkey])
    { payload, pad_amt, file_name, file_size, seq_hash, hmac }
  end

  defp serialize({ payload, pad_amt, file_name, file_size, seq_hash, hmac }) do
    Poison.encode!(%{
      "payload"   => payload,
      "pad_amt"   => pad_amt,
      "file_name" => file_name,
      "file_size" => file_size,
      "seq_hash"  => seq_hash,
      "hmac"      => hmac,
    })
  end

  defp write_out(fragment) do
    file_path = "debug/out/#{:rand.uniform(4096)}.json"
    { :ok, file } = File.open(file_path, [:write])
    IO.binwrite file, fragment
    File.close file
    file_path
  end

end
