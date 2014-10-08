defmodule List.Parallel.Benchmark do
  import ExProf.Macro

  defp inputs() do
    values = [
      1,
      10,
      100,
      1000,
      10000,
      100000,
      1000000,
      # 10000000,
      # 100000000,
    ]
    values |> Enum.map &(Enum.to_list 1..&1)
  end

  defp time(fun) do
    fun |> run_and_time() |> elem(0)
  end

  defp run_and_time(fun) do
      start = :erlang.now
      result = fun.()
      stop = :erlang.now
      time = :timer.now_diff stop, start
      { time, result }
  end

  defp run(fun, :parallel) do
    Enum.map(inputs, fn x -> { length(x), time(fn -> Enum.Parallel.map(x, fun) end) } end)
  end

  defp run(fun, :sequential) do
    Enum.map(inputs, fn x -> { length(x), time(fn -> Enum.map(x, fun) end) } end)
  end

  # defp fib(n), do: Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end) |> Enum.at(n)

  def benchmark() do
    # fun = &(&1 * &1)
    fun = fn x -> :timer.sleep(1); x * x end
    # fun = &fib/1
    results = [
                { :seq, run(fun, :sequential) },
                { :par, run(fun, :parallel) },
              ]
    # System.cmd "say", ["All done"]  # A convenience for Mac OS X
    IO.inspect results
  end

  def profile() do
    profile do
      run &(&1 * &1), :parallel
    end
  end
end
