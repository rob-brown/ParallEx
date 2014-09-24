defprotocol Benchmarker do
  @fallback_to_any true
  def benchmark(module)
  def profile(module)
end

defimpl Benchmarker, for: Any do
  def benchmark(module), do: module.benchmark
  def profile(module), do: module.profile
end
