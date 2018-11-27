defmodule FileShredder.CLI do
    
  # CLI Map
  #
  # [ Fragmentation ]
  # fragment -in <string/filepath> -fragcount <integer> -keyfile <path/to/keyfile> -out <string/dirpath>
  # fragment -in <string/filepath> -fragcount <integer> -out <string/dirpath>
  #
  # [ Reassembly ]
  # reassemble -in <string/dirpath> -keyfile <path/to/keyfile> -out <string/dirpath>
  # reassemble -in <string/dirpath> -out <string/dirpath>
  #
  # [ Help ]
  # help

  def main(argv) do
    parse_args(argv)
  end

  defp parse_args(argv) do
    switches = [in: :string, shards: :integer, out: :string, keyfile: :string]
    aliases  = [i: :in, c: :shards, o: :out, k: :keyfile]
    parse = OptionParser.parse(argv, switches: switches, aliases: aliases)
    case parse do
      {opts, ["fragment"], _}   -> map_params(opts, :fragment)
      {opts, ["reassemble"], _} -> map_params(opts, :reassemble)
      _ -> IO.puts "Invalid parameters"
    end
  end

  defp map_params(opts, :fragment) do
    # validate that all necessary params are not nil before calling function!
    case opts[:keyfile] do
      nil -> FileShredder.fragment(
        opts[:in], # 
        opts[:shards],
        pword_prompt()
      )
      _  -> FileShredder.fragment(
        opts[:in],
        opts[:shards],
        opts[:keyfile] |> Utils.File.parse_keyfile()
      )
    end
  end

  defp map_params(opts, :reassemble) do
    # validate that all necessary params are not nil before calling function!
    case opts[:keyfile] do
      nil -> FileShredder.reassemble(
        opts[:in],
        pword_prompt(),
        opts[:out]
      )
      _  -> FileShredder.reassemble(
        opts[:in],
        opts[:keyfile] |> Utils.File.parse_keyfile(),
        opts[:out]
      )
    end
  end

  def pword_prompt() do
    IO.write "Enter password: "
    pword1 = :io.get_password()
    IO.write "Confirm password: "
    pword2 = :io.get_password()
    case pword1 == pword2 do
      true  -> pword1
      _     -> pword_prompt(:retry)
    end
  end
  def pword_prompt(:retry) do
    IO.puts "Passwords do not match. Try again"
    pword_prompt()
  end

end