defmodule FileShredder.Fragmentor do

  # DEBUG
  @debug false

  @hash_size 32
  @max_file_name_size 96
  @max_file_size_int 32
  @max_part_size 32

  def round_to_next_mult_of(curr, a) do
    (div(curr, a) + 1) * a
  end

  defp calc_part_size(chunk_size, file_size, n) do
    mem_available = div(Utils.Environment.available_memory(), 64) # approx quarter of RAM
    mem_per_frag  = 25_000_000 #div(mem_available, n)
    IO.inspect mem_per_frag, label: "mem_per_frag"
    IO.inspect chunk_size, label: "chunk_size"
    cond do
      chunk_size < mem_per_frag -> (chunk_size |> round_to_next_mult_of(16)) - 1
      true -> (mem_per_frag |> round_to_next_mult_of(16)) - 1
    end
  end

  defp gen_seq_hash(seq_id, hashkey) do
    Utils.Crypto.gen_multi_hash([hashkey, seq_id])
  end

  defp gen_seq_map({seq_id, seq_hash}, acc, hashkey) do
    Map.put(acc, seq_id, seq_hash)
  end

  defp gen_frag_path(seq_hash) do
    seq_hash = Base.encode16(seq_hash)
    file_path = "debug/out/#{seq_hash}.frg" # TODO dont hardcode path, pass in
  end

  defp make_dummy_part(part_size) do
    to_string(:string.chars(0, part_size))
    #Utils.Crypto.rand_bytes(part_size-1)
  end

  defp retrieve_pload(in_file, src_pos, part_size, file_size) do
    cond do
      file_size > src_pos -> Utils.File.seek_read(in_file, src_pos, part_size-1)
      true -> make_dummy_part(part_size-1)
    end
  end

  defp calc_total_parts(file_size, part_size, n) do
    total_parts = max(n, Float.ceil(file_size/(part_size-1)) |> trunc())
    case rem(total_parts, n) do
      0 -> total_parts
      _ -> (div(total_parts, n) + 1) * n
    end
  end

  defp det_dest(payload, src_pos, bytes_per_frag) do
    seq_id = div(src_pos, bytes_per_frag)
    write_pos = rem(src_pos, bytes_per_frag)
    IO.inspect bytes_per_frag, label: "bytes_per_frag"
    IO.inspect src_pos, label: "src_pos"
    IO.inspect write_pos, label: "write_pos"
    {seq_id, write_pos}
  end

  defp write_part(partition, seq_id, write_pos, seq_map_pid) do
    seq_hash = State.Map.get(seq_map_pid, seq_id) |> Base.encode16
    # TODO: dont hardcode path!
    frag_file = File.open!("debug/out/#{seq_hash}.frg", [:write, :read, :raw]) #File.open!("debug/out/#{seq_hash}.frg", [:write, :read])
    Utils.File.seek_write(frag_file, write_pos, partition)
  end

  defp gen_fields(file_size, file_name, seq_hash, part_size, hashkey) do
    %{
      :file_size => Utils.Crypto.encrypt(file_size|> Integer.to_string(), hashkey, @max_file_size_int),
      :file_name => Utils.Crypto.encrypt(file_name, hashkey, @max_file_name_size),
      :part_size => Utils.Crypto.encrypt(part_size |> Integer.to_string(), hashkey, @max_part_size)
    }
  end

  defp write_fields(frag_file, field_map, pos_map_pid) do
    Map.keys(field_map)
    |> Enum.map(fn field -> 
      {Map.get(field_map, field), State.Map.get(pos_map_pid, field)} end)
    |> Enum.map(fn {field_val, write_pos} ->
      Utils.File.seek_write(frag_file, write_pos, field_val) end)
  end

  defp gen_hmac(partition, seq_id, hashkey) do
    hmac_parts = [
      partition,
      seq_id,
      hashkey
    ]
    hmac = Utils.Crypto.gen_multi_hash(hmac_parts)
  end

  ###### ALLOC AND FIELDS ###### TODO: break into separate module
  defp alloc_and_fields(seq_id, file_size, file_name, part_size, hashkey, frag_size, pos_map_pid, seq_map_pid) do
    seq_id
    |> add_seq_hash(hashkey)
    |> add_to_seq_map(seq_map_pid)
    |> add_frag_path()
    |> allocate_frag(frag_size)
    |> open_frag()
    |> gen_frag_fields(file_size, file_name, part_size, hashkey)
    |> write_frag_fields(pos_map_pid)
  end

  defp add_seq_hash(seq_id, hashkey) do
    IO.puts "at add_seq_hash"
    {seq_id, gen_seq_hash(seq_id, hashkey)}
  end

  defp add_to_seq_map({seq_id, seq_hash}, seq_map_pid) do
    IO.puts "at add_to_seq_map"
    {seq_id, seq_hash, State.Map.put(seq_map_pid, seq_id, seq_hash)}
  end

  defp add_frag_path({seq_id, seq_hash, _ok}) do
    IO.puts "at add_frag_path"
    {seq_id, seq_hash, gen_frag_path(seq_hash)}
  end

  defp allocate_frag({seq_id, seq_hash, frag_path}, frag_size) do
    IO.puts "at allocate_frag"
    {seq_id, seq_hash, frag_path, Utils.File.create(frag_path, frag_size)}
  end

  defp open_frag({seq_id, seq_hash, frag_path, _ok}) do
    IO.puts "at open_frag"
    {seq_id, seq_hash, File.open!(frag_path, [:read, :write, :raw])}
  end

  defp gen_frag_fields({seq_id, seq_hash, frag_file}, file_size, file_name, part_size, hashkey) do
    IO.puts "at gen_frag_fields"
    {gen_fields(file_size, file_name, seq_hash, part_size, hashkey), frag_file}
  end

  defp write_frag_fields({field_map, frag_file}, pos_map_pid) do
    IO.puts "at write_frag_fields"
    write_fields(frag_file, field_map, pos_map_pid)
  end
  #############################


  ###### PROCESS PL PARTS ###### TODO: break into separate module
  defp process_pl_parts(src_pos, part_size, file_size, bytes_per_frag, file_path, hashkey, seq_map_pid) do
    #in_file = File.open!(file_path, [:read, :binary])
    src_pos
    |> retr_partition(part_size, file_size, file_path)
    |> add_dest_info(bytes_per_frag)
    |> encr_part(hashkey)
    |> write_out_part(seq_map_pid)
  end

  defp retr_partition(src_pos, part_size, file_size, in_file) do
    in_file = File.open!(in_file, [:read, :raw])
    IO.puts "at retrieve_partition"
    {src_pos, retrieve_pload(in_file, src_pos, part_size, file_size)}
  end
  
  defp add_dest_info({src_pos, pl_partition}, bytes_per_frag) do
    IO.puts "at add_dest_info"
    {pl_partition, det_dest(pl_partition, src_pos, bytes_per_frag)}
  end 

  defp encr_part({pl_partition, {seq_id, write_pos}}, hashkey) do
    IO.puts "at encr_part"
    {Utils.Crypto.encrypt(pl_partition, hashkey), {seq_id, write_pos}}
  end

  defp write_out_part({pl_partition, {seq_id, write_pos}}, seq_map_pid) do
    IO.puts "at write_out_part"
    {pl_partition, seq_id, write_part(pl_partition, seq_id, write_pos, seq_map_pid)}
  end
  #############################

  def fragment(file_path, n, password) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    file_size = Utils.File.size(file_path)
    IO.inspect "here 1"
    # calculate fragment and paylaod partition parameters
    chunk_size = (Float.ceil(file_size/n) |> trunc())
    part_size = calc_part_size(chunk_size, file_size, n) + 1
    IO.inspect part_size, label: "part_size"
    parts_per_frag = Float.ceil(chunk_size/(part_size-1)) |> trunc()
    frag_size = (parts_per_frag * part_size) + @max_file_size_int + @max_file_name_size + @max_part_size # TODO: add HMAC
    total_parts = calc_total_parts(file_size, part_size, n)
    bytes_per_frag = parts_per_frag * (part_size-1)


    pos_map = %{
      :file_size => frag_size - @max_file_size_int,
      :file_name => frag_size - @max_file_size_int - @max_file_name_size,
      :part_size => frag_size - @max_file_size_int - @max_file_name_size - @max_part_size
    }
    {:ok, pos_map_pid} = State.Map.start_link(pos_map)

    # initialize (empty) sequence map actor
    {:ok, seq_map_pid} = State.Map.start_link()

    # create fragment buffer files and write applicable fields
    0..(n-1)
    |> Enum.to_list()
    #|> Enum.map(&alloc_and_fields(&1, file_size, file_name, part_size, hashkey, frag_size, pos_map_pid, seq_map_pid))
    |> Utils.Parallel.pooled_map(&alloc_and_fields(&1, file_size, file_name, part_size, hashkey, frag_size, pos_map_pid, seq_map_pid))
    #|> IO.inspect()
    
    # chunk target file into payload partitions and write out to fragment files
    Enum.map(0..total_parts-1, fn x -> (part_size-1) * x end)
    #|> Enum.map(&process_pl_parts(&1, part_size, file_size, bytes_per_frag, file_path, hashkey, seq_map_pid))
    |> Utils.Parallel.pooled_map(&process_pl_parts(&1, part_size, file_size, bytes_per_frag, file_path, hashkey, seq_map_pid))
    #|> IO.inspect()
  end
  def fragment(_, _, _), do: :error

end
