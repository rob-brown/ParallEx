defmodule Benchmark.Helper do

  def benchmark_modules() do
    path = "benchmark"
    path
      |> File.ls!()
      |> Enum.map(&(Path.join(path, &1)))
      |> Kernel.ParallelRequire.files()
  end
end

defmodule Mix.Tasks.Benchmark do
  use Mix.Task

  @shortdoc "Runs the project's benchmarks"

  def run(_) do
    Benchmark.Helper.benchmark_modules
      |> Enum.each(&(Benchmarker.benchmark(&1)))
  end
end

defmodule Mix.Tasks.Profile do
  use Mix.Task

  @shortdoc "Profiles the project"

  def run(_) do
    Benchmark.Helper.benchmark_modules
      |> Enum.each(&(Benchmarker.profile(&1)))
  end
end
