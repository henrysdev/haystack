defmodule FileShredder.CLI do
    
    # CLI Map
    #
    # [ Fragmentation ]
    # fragment -in <string/filepath> -fragcount <integer> -keyfile <path/to/keyfile> -out <string/dirpath>
    # fragment -in <string/filepath> -fragcount <integer> -password <boolean>        -out <string/dirpath>
    #
    # [ Reassembly ]
    # reassemble -in <string/dirpath> -keyfile <path/to/keyfile> -out <string/dirpath>
    # reassemble -in <string/dirpath> -password <string>         -out <string/dirpath>
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
      case opts[:keyfile] do
        nil -> FileShredder.fragment(
          opts[:in],
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
      case opts[:keyfile] do
        nil -> FileShredder.reassemble(
          opts[:in],
          pword_prompt()
        )
        _  -> FileShredder.reassemble(
          opts[:in],
          opts[:keyfile] |> Utils.File.parse_keyfile()
        )
      end
    end

    defp pword_prompt() do
      password = IO.gets "Enter a password: "
      password |> String.trim()
    end

end