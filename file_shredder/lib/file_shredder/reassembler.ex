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
  # DEBUG
  @debug false

  @hash_size 32
  @max_file_name_size 96
  @max_file_size_int 32
  @max_part_size 32

  # defp reassem({frag_path, _seq_id, seq_hash}, hashkey, :init) do
  #   if @debug do IO.puts( "start reassem...") end
  #   frag_size = Utils.File.size(frag_path)
  #   frag_path
  #   |> File.open!()
  #   |> deserialize_raw(frag_size)
  #   |> gen_correct_hmac(seq_hash, hashkey)
  #   |> check_hmac()
  # end
  # defp reassem({{frag_path, seq_id, seq_hash}, false}, hashkey, file_name, chunk_size) do
  #   if @debug do IO.puts( "start reassem...") end
  #   frag_size = Utils.File.size(frag_path)
  #   frag_path
  #   |> File.open!()
  #   |> deserialize_raw(frag_size)
  #   |> gen_correct_hmac(seq_hash, hashkey)
  #   |> check_hmac()
  #   |> reform_frag(seq_id)
  #   |> decr_field("payload", hashkey)
  #   |> unpad_payload()
  #   |> write_payload(file_name, chunk_size)
  #   Utils.File.delete(frag_path)
  # end
  # defp reassem({{frag_path, _seq_id, _seq_hash}, true}, _hashkey, _file_name, _chunk_size) do
  #   Utils.File.delete(frag_path)
  # end

  # defp dummy_frag?({_frag_path, seq_id, _seq_hash}, file_size, chunk_size) do
  #   cond do
  #     (chunk_size) * seq_id >= file_size -> true
  #     true -> false
  #   end
  # end

  # defp deserialize_raw(frag_file, frag_size) do
  #   # TODO: find a clean way to manage these magic numbers...
  #   if @debug do IO.puts( "at deserialize_raw...") end
  #   fragment = %{
  #     "payload"   => Utils.File.seek_read(frag_file, 0, frag_size - 160), 
  #     "file_size" => Utils.File.seek_read(frag_file, frag_size - 160, @max_file_size_int),
  #     "file_name" => Utils.File.seek_read(frag_file, frag_size - 128, @max_file_name_size),
  #     "hmac"      => Utils.File.seek_read(frag_file, frag_size - 32,  @hash_size),
  #   }
  #   File.close frag_file
  #   fragment
  # end

  # defp gen_correct_hmac(fragment, seq_hash, hashkey) do
  #   hmac_parts = [
  #     Map.get(fragment, "payload"),
  #     Map.get(fragment, "file_name"),
  #     Map.get(fragment, "file_size"),
  #     seq_hash,
  #     hashkey
  #   ]
  #   {fragment, Utils.Crypto.gen_multi_hash(hmac_parts)}
  # end

  # defp check_hmac({fragment, correct_hmac}) do
  #   {fragment, valid_hmac?({fragment, correct_hmac})}
  # end

  # defp valid_hmac?({fragment, correct_hmac}) do
  #   Map.get(fragment, "hmac") == correct_hmac
  # end

  defp gen_seq_hash(seq_id, hashkey) do
    Utils.Crypto.gen_multi_hash([hashkey, seq_id])
  end

  defp gen_frag_path(seq_hash, dirpath) do
    seq_hash = Base.encode16(seq_hash)
    Path.dirname(dirpath) <> "/" <> seq_hash  <> ".frg"
  end

  defp deserialize_fields(frag_file, frag_size, hashkey) do
    # TODO: find a clean way to manage these magic numbers...
    if @debug do IO.puts( "at deserialize_fields...") end

    file_size_pos = frag_size - @max_file_size_int
    file_name_pos = file_size_pos - @max_file_name_size
    seq_hash_pos  = file_size_pos - @hash_size
    part_size_pos = seq_hash_pos - @max_part_size

    fields = %{
      "file_size" => Utils.File.seek_read(frag_file, file_size_pos, @max_file_size_int)
        |> Utils.Crypto.decrypt(hashkey),
      "file_name" => Utils.File.seek_read(frag_file, file_name_pos, @max_file_name_size)
        |> Utils.Crypto.decrypt(hashkey),
      "seq_hash" => Utils.File.seek_read(frag_file, seq_hash_pos,  @hash_size),
      "part_size" => Utils.File.seek_read(frag_file, part_size_pos, @max_part_size)
        |> Utils.Crypto.decrypt(hashkey)
    }

    File.close frag_file
    fields
  end


  def reassemble(dirpath, password) do
    hashkey = Utils.Crypto.gen_key(password)

    init_frag = gen_seq_hash(0, hashkey) |> gen_frag_path(dirpath)
    frag_size = Utils.File.size(init_frag)

    IO.inspect (File.open!(init_frag) |> deserialize_fields(frag_size, hashkey))

    # init_seq_id = 0
    # init_seq_hash = gen_seq_hash(init_seq_id, hashkey)

    # init_frag_path = gen_frag_path(init_seq_hash, dirpath)
    # {init_frag_path, true} = {init_frag_path, init_seq_id, init_seq_hash} 
    # |> reassem(hashkey, :init)

    # init_frag = init_frag_path
    # |> decr_field("file_name", hashkey)
    # |> decr_field("file_size", hashkey)
    # |> decr_field("payload", hashkey)

    # chunk_size = byte_size(Map.get(init_frag, "payload")) - 1

    # file_name = Map.get(init_frag, "file_name")
    # {file_size, _} = Map.get(init_frag, "file_size") |> Integer.parse()
    # Utils.File.create(file_name, file_size)

    # iter_frag_seq(0, hashkey, dirpath, [])
    # |> Stream.map(&{&1, dummy_frag?(&1, file_size, chunk_size)})
    # #|> Enum.map(&reassem(&1, hashkey, file_name, chunk_size))
    # |> Utils.Parallel.pooled_map(&reassem(&1, hashkey, file_name, chunk_size))
  end

  # defp iter_frag_seq(seq_id, hashkey, dirpath, acc) do
  #   seq_hash  = gen_seq_hash(seq_id, hashkey)
  #   frag_path = seq_hash |> gen_frag_path(dirpath)
  #   case File.exists? frag_path do
  #     true  -> iter_frag_seq(seq_id + 1, hashkey, dirpath, [{frag_path, seq_id, seq_hash} | acc])
  #     false -> acc
  #   end
  # end

  # defp reform_frag({fragment, true}, seq_id) do
  #   if @debug do IO.puts( "at reform frag...") end
  #   %{ 
  #     "seq_id"   => seq_id, 
  #     "payload"  => Map.get(fragment, "payload"),
  #   }
  # end
  # defp reform_frag({_fragment, _}, _seq_id) do
  #   IO.puts "Invalid HMAC, exiting..."
  #   System.halt(0)
  # end

  # defp decr_field(map, field, hashkey) do
  #   if @debug do IO.puts( "at decr_field #{field}...") end
  #   cipherdata = Map.get(map, field)
  #   plaindata = Utils.Crypto.decrypt(cipherdata, hashkey)
  #   Map.put(map, field, plaindata)
  # end

  # defp unpad_payload(fragment) do
  #   if @debug do IO.puts( "at unpad_payload...") end
  #   payload = Map.get(fragment, "payload") |> Utils.Crypto.unpad()
  #   Map.put(fragment, "payload", payload)
  # end

  # defp write_payload(fragment, file_name, chunk_size) do
  #   if @debug do IO.puts( "at write_payload...") end
  #   payload  = Map.get(fragment, "payload")
  #   seek_pos = Map.get(fragment, "seq_id") * chunk_size
  #   # TODO: Use Utils.File.seek_write instead
  #   out_file = File.open!(file_name, [:write, :read])
  #   {:ok, _pos} = :file.position(out_file, seek_pos)
  #   :file.write(out_file, payload)
  #   file_name
  # end

end
