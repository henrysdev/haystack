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

  defp lazy_chunking do
    fn
      {{val, idx}, n}, [] when idx+1 < n ->
        {:cont, {val,idx}, []}
      {{val, idx}, _n}, [] ->
        {:cont, {val, idx}}
      {{val, _idx}, _n}, {tail, t_idx} ->
        {:cont, {tail <> val, t_idx}}
    end
  end

  defp lazy_cleanup do
    fn
      [] ->  {:cont, []}
      acc -> {:cont, acc, []}
    end
  end

  ################################
  # TODO: Abstract away into a Crypto Module
  defp gen_key(password) do
    password
  end

  defp encrypt(chunk, _hashkey) do
    chunk
  end

  defp gen_hmac(password, seq_id) do
    "123456789"
  end
  ################################

  defp add_encr({chunk, seq_id}, hashkey) do
    {encrypt(chunk, hashkey), seq_id}
  end
  
  defp add_hmac({chunk, seq_id}, password) do
    {chunk <> gen_hmac(password, seq_id), seq_id}
  end

  defp write_out({fragment, _seq_id}) do
    {:ok, file} = File.open "debug_out/#{:rand.uniform(16)}.frg", [:write]
    IO.binwrite file, fragment
    File.close file
  end


  def fragment(file_path, n, password) do
    %{ size: file_size } = File.stat! file_path
    chunk_size = Integer.floor_div(file_size, n)
    hashkey = gen_key(password)
    file_path
    |> File.stream!([], chunk_size)
    |> Stream.with_index()    # add sequence IDs
    # possibly not necessary to give n to all elements if we precalculate if its an extra chunk or not...
    |> Stream.map(fn chunk -> {chunk, n} end) # give all chunks a reference to n
    |> Stream.chunk_while([], lazy_chunking(), lazy_cleanup())
    # parallelizable
    |> Stream.map(fn frag -> add_encr(frag, hashkey) end)
    |> Stream.map(fn frag -> add_hmac(frag, password) end)
    |> Stream.each(fn chunk -> write_out(chunk) end)
    |> Enum.to_list()

    #  filebytes -> filebytes
    # split into chunks (+ persist seqIDs)
    #  filebytes -> coll[{filebytes, seqID}]
    # encrypt chunks
    #  coll[{filebytes, seqID}] -> coll[{filebytes, seqID}]
  end

end
