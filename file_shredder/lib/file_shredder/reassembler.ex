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


  def reassemble(dirpath, password, out_dir) do
    hashkey = Utils.Crypto.gen_key(password)
    init_seq_id = 0
    init_seq_hash = Utils.Crypto.gen_hash([hashkey, to_string(init_seq_id)])

    init_frag_path = Utils.File.gen_frag_path(init_seq_hash, dirpath)
    frag_size = Utils.File.size(init_frag_path)

    {:ok, seekpos_pid} = State.Map.start_link(
      %{
        :hmac      => frag_size - @hmac_size,
        :pl_length => frag_size - @hmac_size - @pl_length_buf_size,
        :file_size => frag_size - @hmac_size - @pl_length_buf_size - @fsize_buf_size,
        :file_name => frag_size - @hmac_size - @pl_length_buf_size - @fsize_buf_size - @fname_buf_size,
        :payload   => 0,
      }
    )

    %{
      :file_name => file_name,
      :file_size => file_size,
      :pl_length => pl_length,
    } = init_frag_path
    |> authenticate(init_seq_id, hashkey)
    |> deserialize_fields(seekpos_pid)
    |> decrypt_fields(hashkey)
    |> correct_dtypes()

    {:ok, file_info_pid} = State.Map.start_link(
      %{
        :hashkey   => hashkey,
        :pl_length => pl_length,
        :file_name => file_name,
        :file_size => file_size,
        :frag_size => frag_size,
        :out_dir   => Path.dirname(out_dir) <> "/"
      }
    )

    iter_frag_seq(0, hashkey, dirpath, [])
    |> Stream.map(&{&1, dummy_frag?(&1, file_size, pl_length)})
    #|> Enum.map(&reassem(&1, file_info_pid, seekpos_pid))
    |> Utils.Parallel.pooled_map(&reassem(&1, file_info_pid, seekpos_pid))
  end

  defp gen_frag_path(seq_hash, dirpath) do
    seq_hash = Base.encode16(seq_hash)
    Path.dirname(dirpath) <> "/" <> seq_hash  <> ".frg"
  end

  defp authenticate(frag_path, seq_id, hashkey) do
    if @debug do IO.puts( "start reassem...") end
    frag_size = Utils.File.size(frag_path)
    frag_path
    |> File.open!()
    |> gen_correct_hmac(seq_id, frag_size, hashkey)
    |> check_hmac(frag_size)
  end

  defp gen_correct_hmac(fragment, seq_id, frag_size, hashkey) do
    hmac = [
      Utils.File.seek_read(fragment, 0, frag_size - @hmac_size),
      to_string(seq_id),
      hashkey,
    ] |> Utils.Crypto.gen_hash()

    {fragment, hmac}
  end

  defp check_hmac({fragment, correct_hmac}, frag_size) do
    valid? = Utils.File.seek_read(fragment, frag_size - @hmac_size, @hmac_size) == correct_hmac
    {fragment, valid?, frag_size}
  end

  defp deserialize_fields({_, false, _}, _), do: :error
  defp deserialize_fields({fragment, true, _frag_size}, seekpos_pid) do
    if @debug do IO.puts( "at deserialize_raw...") end
    frag_fields = %{
      :file_name => Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :file_name), @fname_buf_size),
      :file_size => Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :file_size), @fsize_buf_size),
      :pl_length => Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :pl_length), @pl_length_buf_size),
    }
    File.close fragment
    frag_fields
  end

  defp decrypt_fields(:error, _), do: :error
  defp decrypt_fields(field_map, hashkey) do
    decr_aes_cbc = fn x -> Utils.Crypto.decrypt(x, hashkey, :aes_cbc) end
    Map.keys(field_map)
    |> Enum.map(fn key -> {key, Map.get(field_map, key)} end)
    |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, key, decr_aes_cbc.(val)) end)
  end

  defp correct_dtypes(fields) do
    fields
    |> Map.update!(:file_size, &String.to_integer(&1))
    |> Map.update!(:pl_length, &String.to_integer(&1))
  end

  defp iter_frag_seq(seq_id, hashkey, dirpath, acc) do
    seq_hash  = Utils.Crypto.gen_hash([hashkey, to_string(seq_id)])
    frag_path = seq_hash |> gen_frag_path(dirpath)
    case File.exists? frag_path do
      true  -> iter_frag_seq(seq_id + 1, hashkey, dirpath, [{frag_path, seq_id, seq_hash} | acc])
      false -> acc
    end
  end

  defp dummy_frag?({_frag_path, seq_id, _seq_hash}, file_size, pl_length) do
    cond do
      (pl_length) * seq_id >= file_size -> true
      true -> false
    end
  end

  defp reassem({{frag_path, seq_id, _seq_hash}, false}, file_info_pid, seekpos_pid) do
    if @debug do IO.puts( "start reassem...") end
    hashkey   = State.Map.get(file_info_pid, :hashkey)
    file_name = State.Map.get(file_info_pid, :file_name)
    pl_length = State.Map.get(file_info_pid, :pl_length)
    out_dir   = State.Map.get(file_info_pid, :out_dir)

    write_pos = seq_id * pl_length

    payload = frag_path
    |> authenticate(seq_id, hashkey)
    |> get_payload(seekpos_pid, hashkey)
    |> Utils.Crypto.decrypt(hashkey, :aes_ctr)

    out_file = File.open!(out_dir <> "/" <> file_name, [:raw, :read, :write])
    Utils.File.seek_write(out_file, write_pos, payload)
    Utils.File.delete(frag_path)
  end
  defp reassem({{frag_path, _seq_id, _seq_hash}, true}, _file_info_pid, _seekpos_pid) do
    Utils.File.delete(frag_path)
  end

  defp get_payload({fragment, true, _frag_size}, seekpos_pid, hashkey) do
    if @debug do IO.puts( "at deserialize_raw...") end
    pl_length = Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :pl_length), @pl_length_buf_size)
    |> Utils.Crypto.decrypt(hashkey, :aes_cbc)
    |> String.to_integer()
    payload = Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :payload), pl_length)
    File.close fragment
    payload
  end

end
