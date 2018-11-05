defmodule Utils.Parallel do
  
  def pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await(&1, 100000))
  end

end