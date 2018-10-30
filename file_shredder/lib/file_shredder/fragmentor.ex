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
    fn
      []  -> {:cont, []}
      acc -> {:cont, acc, []}
    end
  end

    
  defp spawn_worker(chunk_of_work, function) do
    Task.async(fn -> Enum.map(chunk_of_work, function) end)
  end

  defp join_worker(chunk_of_work) do
    Task.await(chunk_of_work)
  end

  def pmap(collection, process_count, function) do
    coll_size  = Enum.count(collection)
    chunk_size = Integer.floor_div(coll_size, process_count)
    IO.inspect collection
    collection
      |> Enum.chunk_every(chunk_size)
      |> Enum.map(&(spawn_worker(&1, function)))
      |> Enum.map(&(join_worker(&1)))
      |> Enum.concat()
  end

  defp add_encr({chunk, seq_id}, hashkey) do
    {FileShredder.CryptoUtils.encrypt(chunk, hashkey), seq_id}
  end
  
  defp add_hmac({chunk, seq_id}, password) do
    {chunk <> FileShredder.CryptoUtils.gen_hmac(password, seq_id), seq_id}
  end

  defp write_out({fragment, _seq_id}) do
    {:ok, file} = File.open "debug/out/#{:rand.uniform(160)}.frg", [:write]
    IO.binwrite file, fragment
    File.close file
  end

  defp work(fragment, password, hashkey) do
    fragment
    |> add_encr(hashkey)
    |> add_hmac(password)
    |> write_out()
  end


  def fragment(file_path, n, password) do
    %{ size: file_size } = File.stat! file_path
    chunk_size = Integer.floor_div(file_size, n)
    hashkey = FileShredder.CryptoUtils.gen_key(password)
    frags = file_path
    |> File.stream!([], chunk_size)
    |> Stream.with_index()
    |> Stream.chunk_while([], lazy_chunking(n), lazy_cleanup())
    |> Enum.to_list()

    #pmap(frags, 2, fn frag -> work(frag, password, hashkey) end)
    # parallelizable
    # |> Stream.map(fn frag -> add_encr(frag, hashkey) end)
    # |> Stream.map(fn frag -> add_hmac(frag, password) end)
    # |> Stream.each(fn chunk -> write_out(chunk) end)
    # |> Enum.to_list()
  end

end
