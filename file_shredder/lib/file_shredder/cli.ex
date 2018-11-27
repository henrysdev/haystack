defmodule FileShredder.CLI do
    
  # CLI Map
  #
  # [ Fragmentation ]
  # fragment -in <string/filepath> -fragcount <integer> -keyfile <path/to/keyfile> -out <string/dirpath>
  # fragment -in <string/filepath> -fragcount <integer> -out <string/dirpath>
  
  # [ Reassembly ]
  # reassemble -in <string/dirpath> -keyfile <path/to/keyfile> -out <string/dirpath>
  # reassemble -in <string/dirpath> -out <string/dirpath>
  
  # [ Help ]
  # help

  def main(argv) do
    parse_args(argv)
  end

  defp parse_args(argv) do
    switches = [
      in: :string, 
      count: :integer, 
      out: :string, 
      keyfile: :string
    ]
    aliases = [
      i: :in, 
      c: :count, 
      o: :out, 
      k: :keyfile
    ]
    parse = OptionParser.parse(argv, switches: switches, aliases: aliases)
    case parse do
      {opts,  ["fragment"], _}   -> map_params(opts, :fragment)
      {opts,  ["reassemble"], _} -> map_params(opts, :reassemble)
      {_opts, ["help" | _], _}   -> help_dialog()
      _ -> IO.puts "Invalid parameters"
    end
  end

  defp map_params(opts, :fragment) do
    # validate that all necessary params are not nil before calling function!
    case opts[:keyfile] do
      nil -> FileShredder.fragment(
        opts[:in], # 
        opts[:count],
        pword_prompt()
      )
      _  -> FileShredder.fragment(
        opts[:in],
        opts[:count],
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

  defp pword_prompt() do
    IO.write "Enter password: "
    pword1 = :io.get_password()
    IO.write "Confirm password: "
    pword2 = :io.get_password()
    case pword1 == pword2 do
      true  -> pword1
      _     -> pword_prompt(:retry)
    end
  end
  defp pword_prompt(:retry) do
    IO.puts "Passwords do not match. Try again"
    pword_prompt()
  end

  def help_dialog() do
    """
    [ Usage ]
    Fragmentation
    fragment --in <string/filepath> --count <integer> --keyfile <path/to/keyfile> --out <string/dirpath>
    fragment --in <string/filepath> --count <integer> --out <string/dirpath>
    
    Reassembly
    reassemble --in <string/dirpath> --keyfile <path/to/keyfile> --out <string/dirpath>
    reassemble --in <string/dirpath> --out <string/dirpath>
    
    [ Parameters ]
    --in =  path to the input file (for fragmentation) or the input directory (for reassembly).
    --count = number of fragments to split the file into during fragmentation.
    --keyfile = path to a file containing the plaintext password to be used for encryption (for fragmentation) or decryption(for reassembly).
    --out = path to the output directory where fragments (for fragmentation) or the original file (for reassembly) will be located.
    """ |> IO.puts()
  end

end