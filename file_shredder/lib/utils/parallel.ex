defmodule Utils.Parallel do

  @pool_size 10
  @max_overflow 0
  @transaction_timeout_ms 10_000_000
  @await_timeout_ms 100_000_000

  def pooled_map(collection, func) do
    {:ok, pool} = :poolboy.start_link(
      [
        worker_module: Utils.Parallel.Worker, 
        size: @pool_size, 
        max_overflow: @max_overflow
      ]
    )

    tasks = Enum.map collection, fn args ->
      Task.async fn ->
        :poolboy.transaction pool, fn(worker_pid) ->
          Utils.Parallel.Worker.process(worker_pid, func, args)
        end, @transaction_timeout_ms
      end
    end
    tasks
    |> Enum.map(&Task.await(&1, @await_timeout_ms))
  end

end
