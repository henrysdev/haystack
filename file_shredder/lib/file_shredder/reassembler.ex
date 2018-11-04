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
      Map.get(fragment, "file_size"),
      Map.get(fragment, "seq_hash"),
      hashkey
    ]
    # verify integrity of hmac
    Map.get(fragment, "hmac") == Utils.Crypto.gen_multi_hash(hmac_parts)
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

    first_fragment = Map.get(seq_map, gen_seq_hash(0, hashkey))
    file_size = Utils.Crypto.decrypt(Map.get(first_fragment, "file_size"))
    alloc_buffer_file("target_file.txt")
    # [0..map_size(seq_map)-1]
    # |> gen_seq_hash(hashkey)
    # |> 
    #next_seq = gen_seq_hash(0, hashkey)
    #Map.has_key?(seq_map, next_seq)
    #init_frag = Map.get(seq_map, )

    #|> IO.inspect
    #|> Stream.map(&integrity_check(&1))
    #|> Enum.to_list()
  end

  defp gen_seq_hash(seq_id, hashkey) do
    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id])
  end

  defp alloc_buffer_file()

  

end
