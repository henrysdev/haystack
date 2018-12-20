defmodule Dev.Benchmark do

  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  def trials(_function, trials, trials, acc_time), do: acc_time / trials
  def trials(function, trials, completed \\ 0, acc_time \\ 0) do
    t = measure(function)
    trials(function, trials, completed + 1, acc_time + t)
  end

end
