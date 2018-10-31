defmodule Utils.Parallel do
  
  def pmap(collection, func) do
    IO.inspect collection
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end

end