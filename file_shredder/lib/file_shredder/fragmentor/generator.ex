defmodule FileShredder.Fragmentor.Generator do

  defp det_dest(file_info, part_id) do
    n = Map.get(file_info, :n)
    pl_part_size = Map.get(file_info, :pl_part_size)
    file_size = Map.get(file_info, :file_size)
    chunk_size = Map.get(file_info, :chunk_size)
    parts_per_frag = Map.get(file_info, :parts_per_frag)

    seq_id = div(part_id, parts_per_frag)
    write_pos = rem(part_id, parts_per_frag) * pl_part_size
    { seq_id, write_pos }
  end

  def build_from_stream(partition, file_info, state_map_pid, counter_pid) do
    part_id = Agent.get_and_update(counter_pid, &{&1, &1 + 1})
    
    det_dest(file_info, part_id)
    IO.inspect part_id, label: "part_id"
    
    partition
  end

end