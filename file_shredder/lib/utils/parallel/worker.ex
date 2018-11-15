defmodule Utils.Parallel.Worker do

  use GenServer

  @timeout_ms 1_000_000
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    {:ok, []}
  end

  def process(server, func, args) do
    # Don't use cast: http://blog.elixirsips.com/2014/07/16/errata-dont-use-cast-in-a-poolboy-transaction/
    GenServer.call(server, {:fetch, func, args}, @timeout_ms)
  end

  def handle_call({:fetch, func, args}, _from, state) do
    res = func.(args)
    {:reply, res, state}
  end

end