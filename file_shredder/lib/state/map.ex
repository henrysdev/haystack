defmodule State.Map do
  
  def start_link() do
    Agent.start_link(fn -> %{} end)
  end
  def start_link(map) do
    Agent.start_link(fn -> map end)
  end

  def get(pid, key) do
    Agent.get(pid, fn map -> Map.get(map, key) end)
  end

  def put(pid, key, val) do
    Agent.update(pid, fn map -> Map.put(map, key, val) end)
  end

end