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

  @hash_size 32
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

  defp calc_part_size(chunk_size, file_size, n) do
    mem_available = div(Utils.Environment.available_memory(), 64) # approx quarter of RAM
    mem_per_frag = 4 #div(mem_available, n)
    cond do
      chunk_size < mem_per_frag -> chunk_size
      true -> mem_per_frag
    end
  end

  defp gen_seq_hash(seq_id, hashkey) do
    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id])
  end

  defp gen_seq_map({seq_id, seq_hash}, acc, hashkey) do
    Map.put(acc, seq_id, seq_hash) #gen_seq_hash(seq_id, hashkey))
  end

  defp gen_frag_path(seq_hash) do
    seq_hash = Base.encode16(seq_hash)
    file_path = "debug/out/#{seq_hash}.frg" # TODO dont hardcode path, pass in
  end

  defp make_dummy_part(part_size) do
    to_string(:string.chars(0, part_size))
  end

  defp retrieve_pload(in_file, src_pos, part_size, file_size) do
    IO.inspect src_pos, label: "src_pos"
    cond do
      file_size > src_pos -> Utils.File.seek_read(in_file, src_pos, part_size-1)
      true -> make_dummy_part(part_size-1)
    end
  end

  defp calc_total_parts(file_size, part_size, n) do
    total_parts = max(n, Float.ceil(file_size/part_size) |> trunc())
    case rem(total_parts, n) do
      0 -> total_parts
      _ -> (div(total_parts, n) + 1) * n
    end
  end

  defp det_dest({payload, src_pos}, bytes_per_frag) do
    IO.inspect bytes_per_frag, label: "bytes_per_frag"
    seq_id = div(src_pos, bytes_per_frag)
    write_pos = rem(src_pos, bytes_per_frag)
    { payload, seq_id, write_pos }
  end

  defp pad_payload(pload, part_size) do
    Utils.Crypto.pad(pload, part_size)
  end

  defp write_part({partition, seq_id, write_pos}, seq_map) do
    seq_hash = Map.get(seq_map, seq_id) |> Base.encode16
    frag_file = File.open!("debug/out/#{seq_hash}.frg", [:write, :read])
    resp = Utils.File.seek_write(frag_file, write_pos, partition)
  end

  def fragment(file_path, n, password) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    file_size = Utils.File.size(file_path)

    chunk_size = (Float.ceil(file_size/n) |> trunc())
    part_size = calc_part_size(chunk_size, file_size, n) + 1
    parts_per_frag = Float.ceil(chunk_size/part_size) |> trunc()
    frag_size = (parts_per_frag * part_size) + @hash_size + @hash_size + @max_file_size_int + @max_file_name_size
    total_parts = calc_total_parts(file_size, part_size, n)
    bytes_per_frag = parts_per_frag * (part_size - 1)


    seq_map = 0..(n-1)
    |> Enum.to_list()
    |> Enum.map(&{&1, gen_seq_hash(&1, hashkey)})
    |> Enum.map(&{&1, Utils.File.create(gen_frag_path(elem(&1,1)), frag_size)})
    |> Enum.map(&elem(&1,0))
    |> Enum.reduce(%{}, &gen_seq_map(&1, &2, hashkey))

    in_file = File.open!(file_path)

    Enum.map(0..total_parts-1, fn x -> (part_size-1) * x end)
    |> Enum.map(&{retrieve_pload(in_file, &1, part_size, file_size), &1})
    |> Enum.map(&{pad_payload(elem(&1,0), part_size), elem(&1,1)})
    |> Enum.map(&det_dest(&1, bytes_per_frag))
    |> IO.inspect()
    |> Enum.map(&write_part(&1, seq_map))


    # file_info = %{
    #   :n              => n,
    #   :hashkey        => hashkey,
    #   :file_name      => file_name, 
    #   :file_size      => file_size,
    #   :chunk_size     => chunk_size,
    #   :dummy_count    => dummy_count,
    #   :part_size   => part_size,
    #   :parts_per_frag => parts_per_frag,
    # }

    # # TODO: parallelizable section (until reduce)
    # seq_map = 0..(n-1)
    # |> Enum.to_list()
    # |> Enum.map(&{&1, gen_seq_hash(&1, hashkey)})
    # |> Enum.map(&{&1, Utils.File.create(gen_frag_path(elem(&1,1)), frag_size)})
    # |> Enum.map(&elem(&1,0))
    # |> Enum.reduce(%{}, &gen_seq_map(&1, &2, hashkey))

    # # instantiate Agents
    # {:ok, seq_map_pid} = State.FragMap.start_link(seq_map)
    # {:ok, counter_pid} = Agent.start(fn -> 0 end)

    # #memory_cap = div(Utils.Environment.available_memory(), 64)
    # #part_size = #:erlang.memory[:total]
  
    # # write payloads in parallel
    # frag_paths = file_path
    # |> File.stream!([], part_size)
    # |> Utils.Parallel.pooled_map(&FileShredder.Fragmentor.Generator.build_from_stream(&1, file_info, seq_map_pid, counter_pid))
    # |> Enum.to_list()



    # chunk_size = (Float.ceil(file_size/n) |> trunc()) + 1
    # padding = (n * (chunk_size - 1)) - file_size
    # partial_pad = rem(padding, (chunk_size - 1))
    # dummy_count = div((padding - partial_pad), (chunk_size - 1))

    # frag_paths = file_path
    # |> File.stream!([], chunk_size - 1)
    # |> Stream.map(&pad_frag(&1, chunk_size)) # pad frags
    # |> Stream.concat(gen_dummies(dummy_count, chunk_size)) # add dummy frags
    # |> Stream.with_index() # add sequence ID
    # #|> Enum.map(&finish_frag(&1, hashkey, file_name, file_size))
    # |> Utils.Parallel.pooled_map(&finish_frag(&1, hashkey, file_name, file_size))
    # |> Enum.to_list()

    #{:ok, frag_paths}
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
    file_path = gen_frag_path
    Utils.File.write(file_path, fragment)
    file_path
  end

end
