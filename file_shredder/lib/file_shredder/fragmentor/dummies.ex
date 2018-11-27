defmodule FileShredder.Fragmentor.Dummies do

  def generate(stream, dummy_count, chunk_size) do
    stream
    |> Stream.concat(gen_dummies(dummy_count, chunk_size))
  end

  defp gen_dummies(0, _chunk_size), do: []
  defp gen_dummies(dummy_count, chunk_size) do
    for _ <- 0..dummy_count-1, do: dummy(chunk_size)
  end

  defp dummy(chunk_size) do
    chunk = to_string(:string.chars(0, chunk_size-1))
    %{"payload" => chunk}
  end

end