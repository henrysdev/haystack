defmodule Dev.Profiler do
    
import ExProf.Macro

  @doc "analyze with profile macro"
  def analyze_fragmentor(fpath \\ "debug/in/abc.txt", n \\ 10, pword \\ "pword", out \\ "debug/out/") do
    profile do
      Haystack.fragment(fpath, n, pword, out)
      IO.puts "message\n"
    end
  end

  @doc "analyze with profile macro"
  def analyze_reassembler(dirpath \\ "debug/out/*.frg", pword \\ "pword", out \\ "debug/out") do
    profile do
      Haystack.reassemble(dirpath, pword, out)
      IO.puts "message\n"
    end
  end

  @doc "get analysis records and sum them up"
  def run_fragmentor(fpath \\ "debug/in/abc.txt", n \\ 10, pword \\ "pword") do
    {records, _block_result} = analyze_fragmentor(fpath, n, pword)
    total_percent = Enum.reduce(records, 0.0, &(&1.percent + &2))
    IO.inspect "total = #{total_percent}"
  end

  def run_reassembler(dirpath \\ "debug/out/*.frg", pword \\ "pword") do
    {records, _block_result} = analyze_reassembler(dirpath, pword)
    total_percent = Enum.reduce(records, 0.0, &(&1.percent + &2))
    IO.inspect "total = #{total_percent}"
  end

end