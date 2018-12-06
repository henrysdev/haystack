defmodule Utils.Parallel.Worker do
  @moduledoc """
  Utils.Parallel.Worker is a module that represents a threadpool worker.
  """

  use GenServer

  @timeout_ms 1_000_000
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    {:ok, []}
  end

  def process(server, func, args) do
    GenServer.call(server, {:fetch, func, args}, @timeout_ms)
  end

  def handle_call({:fetch, func, args}, _from, state) do
    res = func.(args)
    {:reply, res, state}
  end

end