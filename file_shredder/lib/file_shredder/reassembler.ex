defmodule FileShredder.Reassembler do
  @moduledoc """
  Documentation for FileShredder.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FileShredder.hello()
      :world

  """
  defp deserialize(fragment) do
    Poison.Parser.parse!(fragment)
  end

  defp valid_hmac?(fragment, hashkey) do
    hmac_parts = [
      Map.get(fragment, "payload"),
      Map.get(fragment, "pad_amt"),
      Map.get(fragment, "file_name"),
      Map.get(fragment, "file_size"),
      Map.get(fragment, "seq_hash"),
      hashkey
    ]
    # verify integrity of hmac
    IO.inspect Map.get(fragment, "hmac") == Utils.Crypto.gen_multi_hash(hmac_parts)
  end

  defp gen_seq_map(fragment, acc) do
    Map.put(acc, Map.get(fragment, "seq_hash"), fragment)
  end

  def reassemble(dirpath, password) do
    hashkey = Utils.Crypto.gen_key(password)

    seq_map = Path.wildcard(dirpath)
    |> Stream.map(&File.read!(&1))
    |> Stream.map(&deserialize(&1)) # deserialize json fragment
    |> Stream.filter(&valid_hmac?(&1, hashkey)) # verify integrity
    |> Enum.reduce(%{}, &gen_seq_map(&1, &2)) # reduce into sequence map

    n = map_size(seq_map)

    init_frag = Map.get(seq_map, gen_seq_hash(0, hashkey))
    |> decr_field("file_name", hashkey)
    |> decr_field("file_size", hashkey)
    file_name = Map.get(init_frag, "file_name")
    { file_size, _ } = Map.get(init_frag, "file_size") |> Integer.parse()
    Utils.File.create(file_name, file_size)

    chunk_size = Float.ceil(file_size/n) |> trunc()

    0..(map_size(seq_map)-1)
    |> Enum.to_list()
    |> Stream.map(&{&1, Map.get(seq_map, gen_seq_hash(&1, hashkey))})
    |> Utils.Parallel.pmap(&finish_reassem(&1, hashkey, file_name, chunk_size))

  end

  defp finish_reassem({ seq_id, fragment}, hashkey, file_name, chunk_size) do
    { seq_id, fragment }
    |> reform_frag()
    |> IO.inspect
    |> decr_field("payload", hashkey)
    |> decr_field("pad_amt", hashkey)
    |> unpad_payload()
    |> write_payload(file_name, chunk_size)
  end

  defp gen_seq_hash(seq_id, hashkey) do
    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id])
  end

  defp decr_field(fragment, field, hashkey) do
    cipherdata = Map.get(fragment, field)
    plaindata = Utils.Crypto.decrypt(cipherdata, hashkey)
    Map.put(fragment, field, plaindata)
  end

  defp reform_frag({seq_id, fragment}) do
    %{ 
      "seq_id"  => seq_id, 
      "payload" => Map.get(fragment, "payload"), 
      "pad_amt" => Map.get(fragment, "pad_amt")
    }
  end

  defp unpad_payload(fragment) do
    { pad_amt, _ } = Map.get(fragment, "pad_amt") |> Integer.parse()
    payload = Map.get(fragment, "payload")
    pl_length = String.length(payload)
    payload = String.slice(payload, 0..pl_length - pad_amt - 1)
    Map.put(fragment, "payload", payload)
  end

  defp write_payload(fragment, file_name, chunk_size) do
    payload  = Map.get(fragment, "payload")
    seek_pos = Map.get(fragment, "seq_id") * chunk_size
    out_file = File.open!(file_name, [:write, :read])
    {:ok, pos} = :file.position(out_file, seek_pos)
    :file.write(out_file, payload)
  end

end
