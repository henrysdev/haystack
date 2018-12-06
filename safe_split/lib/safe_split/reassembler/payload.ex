defmodule SafeSplit.Reassembler.Payload do
  @moduledoc """
  The SafeSplit.Reassembler.Payload module is responsible for handling all 
  payload-related functions needed during reassembly.
  """

  @doc """
  Returns the plaintext payload as an iolist for the given fragment.
  """
  def extract({fragment, true, _frag_size}, seekpos_pid, hashkey) do
    pl_length = SafeSplit.Reassembler.Fields.extract_pl_length(fragment, seekpos_pid, hashkey)
    Utils.File.seek_read(fragment, State.Map.get(seekpos_pid, :payload), pl_length)
  end 

end