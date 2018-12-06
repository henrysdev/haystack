defmodule SafeSplit.Reassembler.HMAC do
  
  @moduledoc """
  The SafeSplit.Reassembler.HMAC module is responsible for handling all 
  HMAC-related functions needed during reassembly.
  """

  @hmac_size 32
  
  @doc """
  Returns a tuple pertaining to the authenticity of a fragment file at a given 
  fragment file path.
  """
  def authenticate(frag_path, seq_id, hashkey) do
    frag_size = Utils.File.size(frag_path)
    frag_path
    |> File.open!()
    |> gen_correct_hmac(seq_id, frag_size, hashkey)
    |> check_hmac(frag_size)
  end

  # Returns a generated cryptographic hash of what the HMAC should look like for 
  # a given fragment.
  defp gen_correct_hmac(fragment, seq_id, frag_size, hashkey) do
    hmac = [
      Utils.File.seek_read(fragment, 0, frag_size - @hmac_size),
      to_string(seq_id),
      hashkey,
    ] |> Utils.Crypto.gen_hash()

    {fragment, hmac}
  end

  # Returns a tuple containing a boolean pertaining to if the fragment's HMAC is valid.
  defp check_hmac({fragment, correct_hmac}, frag_size) do
    valid? = Utils.File.seek_read(fragment, frag_size - @hmac_size, @hmac_size) == correct_hmac
    {fragment, valid?, frag_size}
  end

end