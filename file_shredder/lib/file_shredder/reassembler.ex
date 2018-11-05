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

  def reassemble(dirpath, password) do
    hashkey = Utils.Crypto.gen_key(password)

    seq_map = Path.wildcard(dirpath)
    |> Utils.Parallel.pmap(&start_reassem(&1, hashkey))
    |> Stream.filter(&valid_hmac?(&1)) # filter out invalid hmacs
    |> Enum.reduce(%{}, &gen_seq_map(&1, &2)) # reduce into sequence map


    init_frag = Map.get(seq_map, gen_seq_hash(0, hashkey))
    |> decr_field("file_name", hashkey)
    |> decr_field("file_size", hashkey)
    file_name = Map.get(init_frag, "file_name")
    { file_size, _ } = Map.get(init_frag, "file_size") |> Integer.parse()
    
    Utils.File.create(file_name, file_size)

    n = map_size(seq_map)
    chunk_size = Float.ceil(file_size/n) |> trunc()
    padding = (n * chunk_size) - file_size
    partial_pad = rem(padding, chunk_size)
    dummy_count = div((padding - partial_pad), chunk_size)

    0..(map_size(seq_map)-1)
    |> Enum.to_list()
    |> Stream.filter(&(n - dummy_count > &1))
    |> Stream.map(&{&1, Map.get(seq_map, gen_seq_hash(&1, hashkey))})
    |> Utils.Parallel.pmap(&finish_reassem(&1, hashkey, file_name, chunk_size))

    Utils.File.clear_dir(dirpath)
    { :ok, file_name }
  end

  defp start_reassem(file, hashkey) do
    file
    |> File.read!()
    |> deserialize()
    |> gen_correct_hmac(hashkey)
  end

  defp deserialize(fragment) do
    Poison.Parser.parse!(fragment)
  end

  defp gen_correct_hmac(fragment, hashkey) do
    hmac_parts = [
      Map.get(fragment, "payload"),
      Map.get(fragment, "pad_amt"),
      Map.get(fragment, "file_name"),
      Map.get(fragment, "file_size"),
      Map.get(fragment, "seq_hash"),
      hashkey
    ]
    { fragment, Utils.Crypto.gen_multi_hash(hmac_parts) }
  end

  defp valid_hmac?({ fragment, correct_hmac }) do
    Map.get(fragment, "hmac") == correct_hmac
  end

  defp gen_seq_map({ fragment, _hmac }, acc) do
    Map.put(acc, Map.get(fragment, "seq_hash"), fragment)
  end

  defp gen_seq_hash(seq_id, hashkey) do
    Utils.Crypto.gen_multi_hash([hashkey, seq_id])
  end

  defp finish_reassem({ seq_id, fragment}, hashkey, file_name, chunk_size) do
    { seq_id, fragment }
    |> reform_frag()
    |> decr_field("payload", hashkey)
    |> decr_field("pad_amt", hashkey)
    |> unpad_payload()
    |> write_payload(file_name, chunk_size)
  end

  defp reform_frag({seq_id, fragment}) do
    %{ 
      "seq_id"  => seq_id, 
      "payload" => Map.get(fragment, "payload"), 
      "pad_amt" => Map.get(fragment, "pad_amt")
    }
  end

  defp decr_field(map, field, hashkey) do
    cipherdata = Map.get(map, field)
    plaindata = Utils.Crypto.decrypt(cipherdata, hashkey)
    Map.put(map, field, plaindata)
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
    {:ok, _pos} = :file.position(out_file, seek_pos)
    :file.write(out_file, payload)
  end

end
