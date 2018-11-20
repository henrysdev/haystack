defmodule FileShredder.Fragmentor.Generator do

  defp det_dest(file_info, part_id) do
    pl_part_size = Map.get(file_info, :pl_part_size)
    parts_per_frag = Map.get(file_info, :parts_per_frag)

    seq_id = div(part_id, parts_per_frag)
    write_pos = rem(part_id, parts_per_frag) * pl_part_size
    { seq_id, write_pos }
  end

  def build_from_stream(partition, file_info, state_map_pid, counter_pid) do
    part_id = Agent.get_and_update(counter_pid, &{&1, &1 + 1})

    { seq_id, write_pos } = det_dest(file_info, part_id)
    seq_hash = State.FragMap.get(state_map_pid, seq_id) |> Base.encode16
    frag_file = File.open!("debug/out/#{seq_hash}.frg", [:write, :read])
    resp = Utils.File.seek_write(frag_file, write_pos, partition)
    partition
  end

end