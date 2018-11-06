defmodule Dev.Profiler do
    
import ExProf.Macro

  @doc "analyze with profile macro"
  def analyze_fragmentor do
    profile do
      FileShredder.fragment("debug/in/abc.txt", 2, "pword")
      IO.puts "message\n"
    end
  end

  @doc "analyze with profile macro"
  def analyze_reassembler do
    profile do
      FileShredder.reassemble("debug/out/*.json", "pword")
      IO.puts "message\n"
    end
  end

  @doc "get analysis records and sum them up"
  def run_fragmentor do
    {records, _block_result} = analyze_fragmentor
    total_percent = Enum.reduce(records, 0.0, &(&1.percent + &2))
    IO.inspect "total = #{total_percent}"
  end

  def run_reassembler do
    {records, _block_result} = analyze_reassembler
    total_percent = Enum.reduce(records, 0.0, &(&1.percent + &2))
    IO.inspect "total = #{total_percent}"
  end

end