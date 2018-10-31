defmodule FileShredder.Fragmentor do
  @moduledoc """
  Documentation for FileShredder.
  """

  @doc """
  Hello world.

  ## Examples

      iex> FileShredder.hello()
      :world

  """

  # high-order functions for generating an
  # anonymous function for fragment partitioning

  defp lazy_pad({chunk, 0}), do: {chunk, 0}
  defp lazy_pad({chunk, p}) do
    { chunk <> to_string(:string.chars(0, p)), p }
  end

  # def fragment(file_path, n, password) do
  #   %{ size: file_size } = File.stat! file_path
  #   chunk_size = Integer.floor_div(file_size, n)
  #   hashkey = Utils.Crypto.gen_key(password)
  #   file_path
  #   |> File.stream!([], chunk_size)
  #   |> Stream.with_index()
  #   |> Stream.chunk_while([], lazy_chunking(n), lazy_cleanup())
  #   |> Utils.Parallel.pmap(&finish_frag(&1, hashkey))
  # end

  def fragment(file_path, n, password) do
    hashkey = Utils.Crypto.gen_key(password)
    %{ size: file_size } = File.stat! file_path

    chunk_size = Float.ceil(file_size/n) |> trunc()
    padding = (n * chunk_size) - file_size
    partial_pad = rem(padding, chunk_size)
    dummy_count = div((padding - partial_pad), chunk_size)

    IO.inspect n, label: "n"
    IO.inspect file_size, label: "file_size"
    IO.inspect chunk_size, label: "chunk_size"
    IO.inspect padding, label: "padding"
    IO.inspect partial_pad, label: "partial_pad"
    IO.inspect dummy_count, label: "dummy_count"

    file_path
    |> File.stream!([], chunk_size)
    |> Stream.map(&{&1, chunk_size - String.length(&1)})
    |> Stream.map(&(lazy_pad(&1)))
    #|> Stream.concat(Stream.take(n-1), partial_pad(Stream.take(-1)))
    #|> Stream.map() # fill in bytes of last elem
    #|> Stream.concat() # concat new dummy pad frags
    |> Enum.to_list()
  end

  defp finish_frag({chunk, seq_id}, hashkey) do
    { chunk, seq_id }
    |> add_encr(hashkey)
    |> add_hmac(hashkey)
    |> write_out()
  end

  defp add_encr({chunk, seq_id}, hashkey) do
    { Utils.Crypto.encrypt(chunk, hashkey), seq_id }
  end
  
  defp add_hmac({chunk, seq_id}, hashkey) do
    chunk <> Utils.Crypto.gen_hmac(hashkey, seq_id)
  end

  defp write_out(fragment) do
    { :ok, file } = File.open "debug/out/#{:rand.uniform(5)}.frg", [:write]
    IO.binwrite file, fragment
    File.close file
  end

end
