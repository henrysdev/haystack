defmodule Dev.Worker do
  use GenServer
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def fetch(server, args, func) do
    # Don't use cast: http://blog.elixirsips.com/2014/07/16/errata-dont-use-cast-in-a-poolboy-transaction/
    timeout_ms = 10_000
    GenServer.call(server, {:fetch, args, func}, timeout_ms)
  end

  def handle_call({:fetch, args, func}, _from, state) do
    res = func.(args)
    {:reply, res, state}
  end
end

defmodule Dev.PoolboyDemo do
  def run(collection \\ 1..10, args \\ "ok", func \\ fn x -> x end) do
   transaction_timeout_ms = 10_000_000
   await_timeout_ms = 100_000_000

    {:ok, pool} = :poolboy.start_link(
      [
        worker_module: Dev.Worker, 
        size: 5, 
        max_overflow: 0
      ]
    )

    tasks = Enum.map collection, fn _ ->
      Task.async fn ->
        :poolboy.transaction pool, fn(worker_pid) ->
          Dev.Worker.fetch(worker_pid, args, func)
        end, transaction_timeout_ms
      end
    end
    tasks
    |> Enum.each(&Task.await(&1, await_timeout_ms))
    |> IO.inspect()
  end
end