defmodule SafeSplit.Reassembler.Payload do

  def extract({fragment, true, _frag_size}, seekpos_pid, hashkey) do
    pl_length = SafeSplit.Reassembler.Fields.extract_pl_length(fragment, seekpos_pid, hashkey)
    Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :payload), pl_length)
  end 

end