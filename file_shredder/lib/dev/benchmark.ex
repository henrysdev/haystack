defmodule Dev.Benchmark do

  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  def trials(function, trials, trials, acc_time) do
    acc_time / trials
  end
  def trials(function, trials, t_complete \\ 0, acc_time \\ 0) do
    t = measure(function)
    trials(function, trials, t_complete + 1, acc_time + t)
  end

end
