defmodule HttpRequester do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def fetch(server, url) do
    # Don't use cast: http://blog.elixirsips.com/2014/07/16/errata-dont-use-cast-in-a-poolboy-transaction/
    timeout_ms = 10_000
    GenServer.call(server, {:fetch, url}, timeout_ms)
  end

  def handle_call({:fetch, url}, _from, state) do
    IO.puts "fetching #{url}"
    :timer.sleep 5000
    IO.puts "fetched #{url}"

    {:reply, "whatever", state}
  end
end

defmodule PoolboyDemo do
  def run do
   transaction_timeout_ms = 10_000_000
   await_timeout_ms = 100_000_000
  
    {:ok, pool} = :poolboy.start_link(
      [worker_module: HttpRequester, size: 5, max_overflow: 0]
    )

    tasks = Enum.map 1..20, fn(n) ->
      Task.async fn ->
        :poolboy.transaction pool, fn(http_requester_pid) ->
          HttpRequester.fetch(http_requester_pid, "url #{n}")
        end, transaction_timeout_ms
      end
    end

    tasks |> Enum.each &Task.await(&1, await_timeout_ms)
  end
end