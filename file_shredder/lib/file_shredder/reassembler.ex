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

  @fname_buf_size 96
  @fsize_buf_size 32
  @pl_length_buf_size 32
  @hmac_size 32

  defp reassem({frag_path, _seq_id, seq_hash}, hashkey, seekpos_pid, :init) do
    if @debug do IO.puts( "start reassem...") end
    frag_size = Utils.File.size(frag_path)
    frag_path
    |> File.open!()
    |> deserialize_raw(frag_size, seekpos_pid)
    |> gen_correct_hmac(seq_hash, hashkey)
    |> check_hmac()
  end
  defp reassem({{frag_path, seq_id, seq_hash}, false}, file_info_pid, seekpos_pid) do
    if @debug do IO.puts( "start reassem...") end
    hashkey    = State.Map.get(file_info_pid, :hashkey)
    file_name  = State.Map.get(file_info_pid, :file_name)
    chunk_size = State.Map.get(file_info_pid, :chunk_size)
    frag_size  = State.Map.get(file_info_pid, :frag_size)
    out_dir    = State.Map.get(file_info_pid, :out_dir)

    frag_path
    |> File.open!()
    |> deserialize_raw(frag_size, seekpos_pid)
    |> gen_correct_hmac(seq_hash, hashkey)
    |> check_hmac()
    |> reform_frag(seq_id)
    |> decr_field("payload", hashkey)
    |> unpad_payload()
    |> write_payload(file_name, chunk_size, out_dir)
    Utils.File.delete(frag_path)
  end
  defp reassem({{frag_path, _seq_id, _seq_hash}, true}, _file_info_pid, _seekpos_pid) do
    Utils.File.delete(frag_path)
  end

  defp dummy_frag?({_frag_path, seq_id, _seq_hash}, file_size, chunk_size) do
    cond do
      (chunk_size) * seq_id >= file_size -> true
      true -> false
    end
  end

  defp deserialize_raw(frag_file, frag_size, seekpos_pid) do
    # TODO: find a clean way to manage these magic numbers...
    if @debug do IO.puts( "at deserialize_raw...") end
    fields_size = @fsize_buf_size + @fname_buf_size + @hmac_size
    fragment = %{
      "payload"   => Utils.File.seek_read(frag_file, State.Map.get(seekpos_pid, :payload), frag_size - fields_size), 
      "file_size" => Utils.File.seek_read(frag_file, State.Map.get(seekpos_pid, :file_size), @fsize_buf_size),
      "file_name" => Utils.File.seek_read(frag_file, State.Map.get(seekpos_pid, :file_name), @fname_buf_size),
      "hmac"      => Utils.File.seek_read(frag_file, State.Map.get(seekpos_pid, :hmac),  @hmac_size),
    }
    File.close frag_file
    fragment
  end

  defp gen_correct_hmac(fragment, seq_hash, hashkey) do
    hmac_parts = [
      Map.get(fragment, "payload"),
      Map.get(fragment, "file_name"),
      Map.get(fragment, "file_size"),
      seq_hash,
      hashkey
    ]
    {fragment, Utils.Crypto.gen_multi_hash(hmac_parts)}
  end

  defp check_hmac({fragment, correct_hmac}) do
    {fragment, valid_hmac?({fragment, correct_hmac})}
  end

  defp valid_hmac?({fragment, correct_hmac}) do
    Map.get(fragment, "hmac") == correct_hmac
  end

  defp gen_seq_hash(seq_id, hashkey) do
    Utils.Crypto.gen_multi_hash([hashkey, seq_id])
  end

  defp gen_frag_path(seq_hash, dirpath) do
    seq_hash = Base.encode16(seq_hash)
    Path.dirname(dirpath) <> "/" <> seq_hash  <> ".frg"
  end

  defp iter_frag_seq(seq_id, hashkey, dirpath, acc) do
    seq_hash  = gen_seq_hash(seq_id, hashkey)
    frag_path = seq_hash |> gen_frag_path(dirpath)
    case File.exists? frag_path do
      true  -> iter_frag_seq(seq_id + 1, hashkey, dirpath, [{frag_path, seq_id, seq_hash} | acc])
      false -> acc
    end
  end

  def reassemble(dirpath, password, out_dir) do
    hashkey = Utils.Crypto.gen_key(password)
    init_seq_id = 0
    init_seq_hash = gen_seq_hash(init_seq_id, hashkey)

    init_frag_path = gen_frag_path(init_seq_hash, dirpath)
    frag_size = Utils.File.size(init_frag_path)

    {:ok, seekpos_pid} = State.Map.start_link(
      %{
        :hmac      => frag_size - @hmac_size,
        :file_name => frag_size - @hmac_size - @fname_buf_size,
        :file_size => frag_size - @hmac_size - @fname_buf_size - @fsize_buf_size,
        :payload   => 0,
      }
    )

    {init_frag_path, true} = {init_frag_path, init_seq_id, init_seq_hash} 
    |> reassem(hashkey, seekpos_pid, :init)

    init_frag = init_frag_path
    |> decr_field("file_name", hashkey)
    |> decr_field("file_size", hashkey)
    |> decr_field("payload", hashkey)

    chunk_size = byte_size(Map.get(init_frag, "payload")) - 1

    file_name = Map.get(init_frag, "file_name")
    {file_size, _} = Map.get(init_frag, "file_size") |> Integer.parse()
    Utils.File.create(file_name, file_size)

    {:ok, file_info_pid} = State.Map.start_link(
      %{
        :hashkey    => hashkey,
        :chunk_size => chunk_size,
        :file_name  => file_name,
        :frag_size  => frag_size,
        :out_dir    => Path.dirname(out_dir) <> "/"
      }
    )

    iter_frag_seq(0, hashkey, dirpath, [])
    |> Stream.map(&{&1, dummy_frag?(&1, file_size, chunk_size)})
    #|> Enum.map(&reassem(&1, file_info_pid, seekpos_pid))
    |> Utils.Parallel.pooled_map(&reassem(&1, file_info_pid, seekpos_pid))
  end

  defp reform_frag({fragment, true}, seq_id) do
    if @debug do IO.puts( "at reform frag...") end
    %{ 
      "seq_id"   => seq_id, 
      "payload"  => Map.get(fragment, "payload"),
    }
  end
  defp reform_frag({_fragment, _}, _seq_id) do
    IO.puts "Invalid HMAC, exiting..."
    System.halt(0)
  end

  defp decr_field(map, field, hashkey) do
    if @debug do IO.puts( "at decr_field #{field}...") end
    cipherdata = Map.get(map, field)
    plaindata = Utils.Crypto.decrypt(cipherdata, hashkey)
    Map.put(map, field, plaindata)
  end

  defp unpad_payload(fragment) do
    if @debug do IO.puts( "at unpad_payload...") end
    payload = Map.get(fragment, "payload") |> Utils.Crypto.unpad()
    Map.put(fragment, "payload", payload)
  end

  defp write_payload(fragment, file_name, chunk_size, out_dir) do
    if @debug do IO.puts( "at write_payload...") end
    payload  = Map.get(fragment, "payload")
    seek_pos = Map.get(fragment, "seq_id") * chunk_size
    out_path = out_dir <> file_name
    out_file = File.open!(out_path, [:write, :read])
    {:ok, _pos} = :file.position(out_file, seek_pos)
    :file.write(out_file, payload)
    file_name
  end

end
