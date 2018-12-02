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

  @fname_buf_size 96
  @fsize_buf_size 32
  @pl_length_buf_size 32
  @hmac_size 32

  def fragment(file_path, n, password, out_dir) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    file_size = Utils.File.size(file_path)

    chunk_size = (Float.ceil(file_size/n) |> trunc())
    frag_size = chunk_size + @fname_buf_size + @fsize_buf_size + @pl_length_buf_size + @hmac_size
    
    {:ok, file_info_pid} = State.Map.start_link(
      %{
        :hashkey    => hashkey,
        :file_name  => file_name,
        :file_size  => file_size,
        :chunk_size => chunk_size,
        :out_dir    => out_dir,
        :frag_size  => frag_size,
        :file_path  => file_path,
      }
    )

    {:ok, field_pos_pid} = State.Map.start_link(
      %{
        :hmac      => frag_size - @hmac_size,
        :file_name => frag_size - @hmac_size - @fname_buf_size,
        :file_size => frag_size - @hmac_size - @fname_buf_size - @fsize_buf_size
      }
    )

    frag_paths = Stream.map(0..(n-1), fn x -> {x, x * (chunk_size)} end)
    #|> Enum.map(&finish_frag(&1, file_info_pid, field_pos_pid))
    |> Utils.Parallel.pooled_map(&finish_frag(&1, file_info_pid, field_pos_pid))

    {:ok, frag_paths}
  end
  def fragment(_, _, _, _), do: :error

  defp finish_frag({ seq_id, read_pos }, file_info_pid, field_pos_pid) do
    hashkey    = State.Map.get(file_info_pid, :hashkey)
    file_name  = State.Map.get(file_info_pid, :file_name)
    file_size  = State.Map.get(file_info_pid, :file_size)
    chunk_size = State.Map.get(file_info_pid, :chunk_size)
    frag_size  = State.Map.get(file_info_pid, :frag_size)
    out_dir    = State.Map.get(file_info_pid, :out_dir)
    file_path  = State.Map.get(file_info_pid, :file_path)
    
    frag_path = Utils.Crypto.gen_hash([hashkey, seq_id])
    |> Utils.File.gen_frag_path(out_dir)
    
    Utils.File.create(frag_path, frag_size)

    pl_length = max(0, (chunk_size - max(0, (read_pos + chunk_size) - file_size )))
    dummy? = pl_length == 0

    # Fields
    file_name = Utils.Crypto.encrypt(file_name, hashkey, :aes_cbc, @fname_buf_size)

    pl_length = pl_length
    |> Integer.to_string()
    |> Utils.Crypto.encrypt(hashkey, :aes_cbc, @pl_length_buf_size)

    file_size = file_size
    |> Integer.to_string()
    |> Utils.Crypto.encrypt(hashkey, :aes_cbc, @fsize_buf_size)

    # Payload
    encr_pl = file_path
    |> FileShredder.Fragmentor.Payload.extract(read_pos, chunk_size, dummy?)
    |> Utils.Crypto.encrypt(hashkey, :aes_ctr)

    # write payload to fragment file
    frag_file = File.open!(frag_path, [:raw, :read, :write])
    Utils.File.seek_write(frag_file, 0, encr_pl)

    # HMAC
    hmac = [
      Utils.File.seek_read(frag_file, 0, chunk_size),
      file_name, 
      file_size, 
      pl_length, 
      seq_id, 
      hashkey, 
    ] |> Utils.Crypto.gen_hash()

    # Write fragment data to frag file
    fragment = [
      file_name, 
      file_size, 
      pl_length, 
      hmac,
    ]
    
    Utils.File.seek_write(frag_file, chunk_size, fragment)

    File.close frag_file
  end

end
