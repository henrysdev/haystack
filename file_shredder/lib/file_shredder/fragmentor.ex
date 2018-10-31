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

  # high-order functions for generating an
  # anonymous function for fragment partitioning

  defp lazy_chunking(n) do
    fn
      {val, idx}, [] when idx+1 < n ->
        {:cont, {val, idx}, []}
      {val, idx}, [] ->
        {:cont, {val, idx}}
      {val, idx}, {tail, t_idx} ->
        {:cont, {tail <> val, t_idx}}
    end
  end

  defp lazy_cleanup do
    fn acc -> {:cont, acc, []} end
  end

  # def fragment(file_path, n, password) do
  #   %{ size: file_size } = File.stat! file_path
  #   chunk_size = Integer.floor_div(file_size, n)
  #   hashkey = Utils.Crypto.gen_key(password)
  #   file_path
  #   |> File.stream!([], chunk_size)
  #   |> Stream.with_index()
  #   |> Stream.chunk_while([], lazy_chunking(n), lazy_cleanup())
  #   |> Utils.Parallel.pmap(&finish_frag(&1, hashkey))
  # end

  # def fragment(file_path, n, password) do
  #   hashkey = Utils.Crypto.gen_key(password)
  #   %{ size: file_size } = File.stat! file_path

  #   chunk_size = ceil(file_size/n)
  #   padding = (n * chunk_size) - file_size

  #   file_path
  #   |> Stream.repeatedly(&Stream.concat(&1,[0]))
  #   |> Enum.to_list
  # end

  defp finish_frag({chunk, seq_id}, hashkey) do
    { chunk, seq_id }
    |> add_encr(hashkey)
    |> add_hmac(hashkey)
    |> write_out()
  end

  defp add_encr({chunk, seq_id}, hashkey) do
    { Utils.Crypto.encrypt(chunk, hashkey), seq_id }
  end
  
  defp add_hmac({chunk, seq_id}, hashkey) do
    chunk <> Utils.Crypto.gen_hmac(hashkey, seq_id)
  end

  defp write_out(fragment) do
    { :ok, file } = File.open "debug/out/#{:rand.uniform(5)}.frg", [:write]
    IO.binwrite file, fragment
    File.close file
  end

end
