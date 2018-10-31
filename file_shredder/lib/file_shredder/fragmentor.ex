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

  defp pad_frag(chunk, chunk_size) do
    pad_amt = chunk_size - byte_size(chunk)
    pad_bytes = to_string(:string.chars(0, pad_amt))
    chunk = chunk <> pad_bytes
    {chunk, pad_amt}
  end

  defp dummy(chunk_size) do
    pad_amt = 0
    chunk = to_string(:string.chars(0, chunk_size))
    {chunk, pad_amt}
  end

  defp gen_dummies(0, _chunk_size), do: []
  defp gen_dummies(dummy_count, chunk_size) do
    for _ <- 0..dummy_count, do: dummy(chunk_size)
  end

  def fragment(file_path, n, password) do
    hashkey = Utils.Crypto.gen_key(password)
    %{ size: file_size } = File.stat! file_path

    chunk_size = Float.ceil(file_size/n) |> trunc()
    padding = (n * chunk_size) - file_size
    partial_pad = rem(padding, chunk_size)
    dummy_count = div((padding - partial_pad), chunk_size)

    IO.inspect dummy_count

    file_path
    |> File.stream!([], chunk_size)
    |> Stream.map(&(pad_frag(&1, chunk_size))) # add pad_amt
    |> Stream.concat(gen_dummies(dummy_count, chunk_size))
    |> Stream.with_index() # add seq_id
    |> Utils.Parallel.pmap(&finish_frag(&1, hashkey))

  end

  defp finish_frag({ {chunk, seq_id}, pad}, hashkey) do
    { chunk, seq_id, pad }
    |> add_encr(hashkey)
    |> add_hmac(hashkey)
    |> serialize()
    |> write_out()
  end

  defp add_encr({chunk, seq_id, pad}, hashkey) do
    { Utils.Crypto.encrypt(chunk, hashkey), seq_id, pad }
  end
  
  defp add_hmac({chunk, seq_id, pad}, hashkey) do
    { chunk, Utils.Crypto.gen_hmac(hashkey, seq_id), pad }
  end

  defp serialize({chunk, hmac, pad}) do
    # TODO bake pad_amt into encrypted payload (serialize twice...?)
    chunk <> hmac
  end

  defp write_out(fragment) do
    { :ok, file } = File.open "debug/out/#{:rand.uniform(5)}.frg", [:write]
    IO.binwrite file, fragment
    File.close file
  end

end
