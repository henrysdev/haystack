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

  @max_file_name_size 96
  @max_integer_size 32

  defp pad_frag(chunk, chunk_size) do
    pad_amt = chunk_size - byte_size(chunk)
    chunk = chunk <> to_string(:string.chars(0, pad_amt))
    %{"payload" => chunk, "pad_amt" => pad_amt |> Integer.to_string()}
  end

  defp dummy(chunk_size) do
    chunk = to_string(:string.chars(0, chunk_size))
    %{"payload" => chunk, "pad_amt" => "0"}
  end

  defp gen_dummies(0, _chunk_size), do: []
  defp gen_dummies(dummy_count, chunk_size) do
    for _ <- 0..dummy_count-1, do: dummy(chunk_size)
  end

  def fragment(file_path, n, password) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    file_size = Utils.File.size(file_path)
    if n > file_size do
      :error
    else
      chunk_size = Float.ceil(file_size/n) |> trunc()
      padding = (n * chunk_size) - file_size
      partial_pad = rem(padding, chunk_size)
      dummy_count = div((padding - partial_pad), chunk_size)

      frag_paths = file_path
      |> File.stream!([], chunk_size)
      |> Stream.map(&pad_frag(&1, chunk_size)) # pad frags + add pad_amt
      |> Stream.concat(gen_dummies(dummy_count, chunk_size)) # add dummy frags
      |> Stream.map(&Map.put(&1, "file_name", file_name))
      |> Stream.map(&Map.put(&1, "file_size", file_size |> Integer.to_string()))
      |> Stream.with_index() # add sequence IDs
      # DEBUG
      #|> Enum.map(&finish_frag(&1, hashkey))
      |> Utils.Parallel.pmap(&finish_frag(&1, hashkey))
      |> Enum.to_list()

      {:ok, frag_paths}
    end
  end
  def fragment(_, _, _), do: :error

  defp finish_frag({ fragment, seq_id }, hashkey) do
    fragment
    |> encr_field("payload", hashkey)
    |> encr_field("pad_amt", hashkey, @max_integer_size)
    |> encr_field("file_name", hashkey, @max_file_name_size)
    |> encr_field("file_size", hashkey, @max_integer_size)
    |> add_seq_hash(hashkey, seq_id)
    |> add_hmac(hashkey)
    #|> serialize_json()
    |> serialize_raw()
    |> write_out()
  end
  
  defp encr_field(map, field, hashkey, pad \\ 32) do
    plaindata = Map.get(map, field)
    cipherdata = Utils.Crypto.encrypt(plaindata, hashkey, pad)
    Map.put(map, field, cipherdata)
  end
  
  defp add_seq_hash(fragment, hashkey, seq_id) do
    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id])
    Map.put(fragment, "seq_hash", seq_hash)
  end

  defp add_hmac(fragment, hashkey) do
    hmac_parts = [
      Map.get(fragment, "payload"),
      Map.get(fragment, "pad_amt"),
      Map.get(fragment, "file_name"),
      Map.get(fragment, "file_size"),
      Map.get(fragment, "seq_hash"),
      hashkey
    ]
    hmac = Utils.Crypto.gen_multi_hash(hmac_parts)
    Map.put(fragment, "hmac", hmac)
  end

  defp serialize_json(fragment) do
    Poison.encode!(fragment)
  end

  defp serialize_raw(fragment) do
    Map.get(fragment, "payload")   <>
    Map.get(fragment, "pad_amt")   <>
    Map.get(fragment, "file_size") <>
    Map.get(fragment, "file_name") <>
    Map.get(fragment, "seq_hash")  <>
    Map.get(fragment, "hmac")
  end

  defp write_out(fragment) do
    file_path = "debug/out/#{:rand.uniform(9999999999)}.json"
    { :ok, file } = File.open(file_path, [:write])
    IO.binwrite file, fragment
    File.close file
    file_path
  end

end
