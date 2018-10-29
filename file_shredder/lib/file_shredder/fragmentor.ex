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
  defp merge_rem(chunks, n, n),  do: chunks
  defp merge_rem(chunks, k, n) do
    [last, prev | rest] = Enum.reverse(chunks)
    Enum.reverse([prev <> last | rest] )
  end


  def fragment(file_path, n, password) do
    %{ size: file_size } = File.stat! file_path
    chunk_size = Integer.floor_div(file_size, n)

    chunk_fun = fn item, acc ->
      { {val, n}, idx } = item
      IO.inspect idx
      if idx < n - 1 do
        {:cont, Enum.reverse([val | acc]), []}
      else
        merge = fn 
          [] -> {:cont, [val | acc]}
          acc -> 
            [h | t] = Enum.reverse(acc)
            {:cont, [first <> val | rest]}        
        merge(acc)
        end
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    file_path
    |> File.stream!([], chunk_size)
    |> Stream.map(fn chunk -> {chunk, n} end)
    |> Stream.with_index()
    |> Stream.chunk_while([], chunk_fun, after_fun)
    |> Enum.to_list()
    
    #|> Enum.to_list
    #|> merge_rem(length(chunks), n)

    
    
    #hashkey = gen_key(password)
    #chunks = File.stream!(file_path, [], chunk_size) |> Enum.to_list
    #chunks
    #  |> merge_rem(length(chunks), n)

    #  filebytes -> filebytes
    # split into chunks (+ persist seqIDs)
    #  filebytes -> coll[{filebytes, seqID}]
    # encrypt chunks
    #  coll[{filebytes, seqID}] -> coll[{filebytes, seqID}]
  end

end
