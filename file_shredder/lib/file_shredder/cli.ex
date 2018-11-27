defmodule FileShredder.CLI do
    
    # CLI Map
    #
    # [ Fragmentation ]
    # fragment -in <string/filepath> -fragcount <integer> -keyfile <path/to/keyfile> -out <string/dirpath>
    # fragment -in <string/filepath> -fragcount <integer> -genkey <boolean>          -out <string/dirpath>
    # fragment -in <string/filepath> -fragcount <integer> -password <string>         -out <string/dirpath>
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
      switches = [in: :string]
      aliases  = [in: :in]
      parse = OptionParser.parse(argv, switches: switches, aliases: aliases)
      case parse do
        {opts, ["fragment"], _} -> IO.inspect opts
        {opts, ["reassemble"], _} -> IO.inspect opts
        _ -> IO.puts "Invalid parameters"
      end
    end

end