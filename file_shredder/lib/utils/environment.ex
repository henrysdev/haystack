defmodule Utils.Environment do
    
  def available_memory() do
    case :os.type do
      {:unix, :linux} -> 
        System.cmd("vmstat", ["-s", "-SM"])
        |> elem(0)
        |> String.trim()
        |> String.split()
        |> List.first()
        |> String.to_integer()
        |> Kernel.*(1_000_000) # megabytes -> bytes
      {:unix, :darwin} ->
        # TODO: fix parsing...
        System.cmd("vm_stat", [])
        4
    end
  end

  def number_of_cores() do
    :erlang.system_info(:logical_processors_available)
  end

end