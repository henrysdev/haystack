defmodule FileShredder.Reassembler.HMAC do
  @hmac_size 32
  
  def authenticate(frag_path, seq_id, hashkey) do
    frag_size = Utils.File.size(frag_path)
    frag_path
    |> File.open!()
    |> gen_correct_hmac(seq_id, frag_size, hashkey)
    |> check_hmac(frag_size)
  end

  defp gen_correct_hmac(fragment, seq_id, frag_size, hashkey) do
    hmac = [
      Utils.File.seek_read(fragment, 0, frag_size - @hmac_size),
      to_string(seq_id),
      hashkey,
    ] |> Utils.Crypto.gen_hash()

    {fragment, hmac}
  end

  defp check_hmac({fragment, correct_hmac}, frag_size) do
    valid? = Utils.File.seek_read(fragment, frag_size - @hmac_size, @hmac_size) == correct_hmac
    {fragment, valid?, frag_size}
  end

end