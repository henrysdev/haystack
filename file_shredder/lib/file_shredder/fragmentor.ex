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

  def lazy_split do
    fn
      {{val, idx}, n}, [] when idx+1 < n ->
        {:cont, {val,idx}, []}
      {{val, idx}, _n}, [] ->
        {:cont, {val, idx}}
      {{val, _idx}, _n}, {tail, t_idx} ->
        {:cont, {tail <> val, t_idx}}
    end
  end

  def lazy_cleanup do
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
    |> Stream.with_index()    # add sequence IDs
    |> Stream.map(&{ &1, n }) # give all chunks a reference to n
    |> Stream.chunk_while([], lazy_split(), lazy_cleanup())
    |> Enum.to_list()

    #  filebytes -> filebytes
    # split into chunks (+ persist seqIDs)
    #  filebytes -> coll[{filebytes, seqID}]
    # encrypt chunks
    #  coll[{filebytes, seqID}] -> coll[{filebytes, seqID}]
  end

end
