defmodule FileShredder.Fragmentor.FragStateMap do

  def start_link(frag_map) do
    Agent.start_link(fn -> frag_map end)
  end

  def put(pid, key, value) do  
    Agent.update(pid, &Map.put(&1, key, value))  
  end

  def get(pid, key) do  
    Agent.get(pid, &Map.get(&1, key))  
  end

end