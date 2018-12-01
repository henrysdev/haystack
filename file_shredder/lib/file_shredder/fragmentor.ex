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

  defp pad_frag(chunk, chunk_size) do
    if @debug do IO.puts("pad_frag...") end
    chunk = Utils.Crypto.pad(chunk, chunk_size)
    %{"payload" => chunk}
  end

  defp mark_dummies({seq_id, read_pos}, file_size) when read_pos >= file_size do
    {seq_id, -1}
  end
  defp mark_dummies(real_frag, _file_size), do: real_frag

  def fragment(file_path, n, password, out_dir) when n > 1 do
    hashkey = Utils.Crypto.gen_key(password)
    file_name = Path.basename(file_path)
    file_size = Utils.File.size(file_path)

    chunk_size = (Float.ceil(file_size/n) |> trunc())
    #padding = (n * (chunk_size - 1)) - file_size
    #partial_pad = rem(padding, (chunk_size - 1))
    #dummy_count = div((padding - partial_pad), (chunk_size - 1))
    #real_count = n - dummy_count
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

    IO.inspect chunk_size, label: "chunk_size"
    IO.inspect file_size, label: "file_size"
    IO.inspect n, label: "n"

    frag_paths = Stream.map(0..(n-1), fn x -> {x, x * (chunk_size)} end)
    #|> Stream.map(&mark_dummies(&1, file_size))
    |> Enum.map(&finish_frag(&1, file_info_pid, field_pos_pid))
    #|> Utils.Parallel.pooled_map(&finish_frag(&1, file_info_pid, field_pos_pid))

    {:ok, frag_paths}
  end
  def fragment(_, _, _), do: :error

  defp finish_frag({ seq_id, read_pos }, file_info_pid, field_pos_pid) do
    hashkey    = State.Map.get(file_info_pid, :hashkey)
    file_name  = State.Map.get(file_info_pid, :file_name)
    file_size  = State.Map.get(file_info_pid, :file_size)
    chunk_size = State.Map.get(file_info_pid, :chunk_size)
    frag_size  = State.Map.get(file_info_pid, :frag_size)
    out_dir    = State.Map.get(file_info_pid, :out_dir)
    file_path  = State.Map.get(file_info_pid, :file_path)
    
    frag_path = gen_frag_path(seq_id, hashkey, out_dir)
    Utils.File.create(frag_path, frag_size)

    # Fields
    file_name = file_name
    |> Utils.Crypto.encrypt(hashkey, :aes_cbc, @fname_buf_size)

    pl_length = max(0, (chunk_size - max(0, (read_pos + chunk_size) - file_size )))
    dummy? = pl_length == 0

    pl_length = pl_length
    |> Integer.to_string()
    |> Utils.Crypto.encrypt(hashkey, :aes_cbc, @pl_length_buf_size)


    file_size = file_size
    |> Integer.to_string()
    |> Utils.Crypto.encrypt(hashkey, :aes_cbc, @fsize_buf_size)

    # Payload
    encr_pl = FileShredder.Fragmentor.Payload.extract(file_path, read_pos, chunk_size, dummy?)
    |> Utils.Crypto.encrypt(hashkey, :aes_ctr)

    # HMAC
    hmac = [
      encr_pl, 
      file_name, 
      file_size, 
      pl_length, 
      hashkey,
    ] |> Utils.Crypto.gen_hash()

    # write payload to fragment file
    File.write!(frag_path, encr_pl, [:raw, :read, :write])
    
    # Write fragment data to frag file
    fragment = [
      #encr_pl, 
      file_name, 
      "<<<>>>",
      file_size, 
      "<<<>>>",
      pl_length, 
      "<<<>>>",
      hmac,
    ]
    frag_file = File.open!(frag_path, [:raw, :read, :write])
    |> Utils.File.seek_write(chunk_size, fragment)

    #File.write!(frag_path, fragment, [:raw, :read, :write])
  end

  defp gen_frag_path(seq_id, hashkey, out_dir) do
    seq_hash = Utils.Crypto.gen_multi_hash([hashkey, seq_id]) |> Base.encode16()
    Path.dirname(out_dir) <> "/" <> seq_hash <> ".frg"
  end

  defp write_out({ fragment, seq_hash }) do
    if @debug do IO.puts("write_out...") end
    seq_hash = Base.encode16(seq_hash)
    frag_path = "debug/out/#{seq_hash}.frg"
    Utils.File.write(frag_path, fragment)
    frag_path
  end

end
