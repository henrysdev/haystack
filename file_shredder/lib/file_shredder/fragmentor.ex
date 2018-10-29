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

  def lazy_chunk do
    fn
      {{val,  n}, idx}, [] when idx+1 < n ->
        {:cont, {val,idx}, []}
      {{val, _n}, idx}, [] ->
        {:cont, {val, idx}}
      {{val, _n}, _idx}, acc ->
        {h, h_idx} = acc
        {:cont, {h <> val, h_idx}}
    end
  end

  def lazy_clean do
    fn
      [] ->  {:cont, []}
      acc -> {:cont, acc, []}
    end
  end

  def fragment(file_path, n, _password) do
    %{ size: file_size } = File.stat! file_path
    chunk_size = Integer.floor_div(file_size, n)

    file_path
    |> File.stream!([], chunk_size)
    |> Stream.map(&{ &1, n }) # give all chunks a reference to n
    |> Stream.with_index()    # add sequence IDs
    |> Stream.chunk_while([], lazy_chunk(), lazy_clean())
    |> Enum.to_list()

    #  filebytes -> filebytes
    # split into chunks (+ persist seqIDs)
    #  filebytes -> coll[{filebytes, seqID}]
    # encrypt chunks
    #  coll[{filebytes, seqID}] -> coll[{filebytes, seqID}]
  end

end
