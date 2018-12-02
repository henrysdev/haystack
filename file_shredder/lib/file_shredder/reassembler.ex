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

  def reassemble(in_dpath, password, out_dir) do
    hashkey = Utils.Crypto.gen_key(password)

    {
      frag_size,
      seekpos_pid,
      file_name,
      file_size,
      pl_length,
    } = initial_frag_reassem(in_dpath, hashkey)

    {:ok, file_info_pid} = State.Map.start_link(
      %{
        :hashkey   => hashkey,
        :pl_length => pl_length,
        :file_name => file_name,
        :file_size => file_size,
        :frag_size => frag_size,
        :out_dir   => Utils.File.form_dirpath(out_dir)
      }
    )

    iter_frag_seq(0, hashkey, in_dpath, [])
    |> Stream.map(&{&1, dummy_frag?(&1, file_size, pl_length)})
    #|> Enum.map(&frag_reassem(&1, file_info_pid, seekpos_pid))
    |> Utils.Parallel.pooled_map(&frag_reassem(&1, file_info_pid, seekpos_pid))
  end

  defp initial_frag_reassem(in_dpath, hashkey) do
    init_seq_id = 0
    init_seq_hash = Utils.Crypto.gen_hash([hashkey, to_string(init_seq_id)])
    init_frag_path = Utils.File.gen_frag_path(init_seq_hash, in_dpath)
    frag_size = Utils.File.size(init_frag_path)
    seekpos_pid = FileShredder.Reassembler.Fields.build_seek_map(frag_size)

    %{
      :file_name => file_name,
      :file_size => file_size,
      :pl_length => pl_length,
    } = init_frag_path
    |> FileShredder.Reassembler.HMAC.authenticate(init_seq_id, hashkey)
    |> FileShredder.Reassembler.Fields.deserialize_fields(seekpos_pid)
    |> FileShredder.Reassembler.Fields.decrypt_fields(hashkey)
    |> Map.update!(:file_size, &String.to_integer(&1))
    |> Map.update!(:pl_length, &String.to_integer(&1))

    {
      frag_size,
      seekpos_pid,
      file_name,
      file_size,
      pl_length,
    }

  end

  defp iter_frag_seq(seq_id, hashkey, in_dpath, acc) do
    seq_hash  = Utils.Crypto.gen_hash([hashkey, to_string(seq_id)])
    frag_path = seq_hash |> Utils.File.gen_frag_path(in_dpath)
    case File.exists? frag_path do
      true  -> iter_frag_seq(seq_id + 1, hashkey, in_dpath, [{frag_path, seq_id, seq_hash} | acc])
      false -> acc
    end
  end

  defp dummy_frag?({_frag_path, seq_id, _seq_hash}, file_size, pl_length) do
    pl_length * seq_id >= file_size
  end

  defp frag_reassem({{frag_path, seq_id, _seq_hash}, false}, file_info_pid, seekpos_pid) do
    hashkey   = State.Map.get(file_info_pid, :hashkey)
    file_name = State.Map.get(file_info_pid, :file_name)
    pl_length = State.Map.get(file_info_pid, :pl_length)
    out_dir   = State.Map.get(file_info_pid, :out_dir)

    write_pos = seq_id * pl_length

    payload = frag_path
    |> FileShredder.Reassembler.HMAC.authenticate(seq_id, hashkey)
    |> FileShredder.Reassembler.Payload.extract(seekpos_pid, hashkey)
    |> Utils.Crypto.decrypt(hashkey, :aes_ctr)

    Utils.File.form_dirpath(out_dir) <> file_name
    |> File.open!([:raw, :read, :write], fn file -> 
      Utils.File.seek_write(file, write_pos, payload) end)

    Utils.File.delete(frag_path)
  end
  defp frag_reassem({{frag_path, _seq_id, _seq_hash}, true}, _file_info_pid, _seekpos_pid) do
    Utils.File.delete(frag_path)
  end

end
