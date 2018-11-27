defmodule FileShredder.Fragmentor.Dummies do

  # defp dummy(chunk_size, n) do
  #   chunk = to_string(:string.chars(0, chunk_size-1))
  #   %{"payload" => chunk}
  # end
  
  # defp gen_dummies(0, _chunk_size), do: []
  # defp gen_dummies(dummy_count, chunk_size, first_dummy_pos) do
  #   for _ <- 0..dummy_count-1, do: dummy(chunk_size)
  # end
  
  # def generate(pos_stream, dummy_count, chunk_size) do
  #   pos_stream
  #   |> Stream.concat(gen_dummies(dummy_count, chunk_size, first_dummy_pos))
  # end

end