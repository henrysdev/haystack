defmodule Utils.Environment do
    
  def available_memory() do
    System.cmd("vmstat", ["-s", "-SM"])
    |> elem(0)
    |> String.trim()
    |> String.split()
    |> List.first()
    |> String.to_integer()
    |> Kernel.*(1_000_000) # megabytes -> bytes
  end

  def number_of_cores() do
    :erlang.system_info(:logical_processors_available)
  end

end