defmodule FileShredder.CLI do
    
    def main(args \\ []) do
      args
      |> parse_args
      |> response
      |> IO.puts()
    end

    defp parse_args(args) do
      {opts, word, _} =
      args
      |> OptionParser.parse(switches: [upcase: :boolean])

      {opts, List.to_string(word)}
    end

    defp response({opts, word}) do
      cond do
        opts[:upcase]   -> String.upcase(word)
        opts[:downcase] -> String.downcase(word)
        true -> word
      end
    end

    # def main(["fragment", filepath, n, password]) do
    #   FileShredder.fragment(filepath, n, password)
    # end
    # def main(["reassemble", dirpath, password]) do
    #   FileShredder.reassemble(dirpath, password)
    # end
    # def main(["help"]) do
    #   IO.puts(
    #       "Welcome File Shredder.\n
    #       asdlkf"
    #   )
    # end

end