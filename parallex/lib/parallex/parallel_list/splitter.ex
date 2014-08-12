defmodule ParallelList.Splitter do
  use Splitter

  # ???: Is the range even necessary?
  defstruct list: [], range: 0..0

  def new([] \\ []), do: %ParallelList.Splitter{}
  def new(list) when is_list(list) do
    range = 0..(Enum.count(list) - 1)
    %ParallelList.Splitter{list: list, range: range}
  end

  def split(splitter) do
    _split splitter, Enum.count(splitter.range)
  end

  def _split(splitter, count) when count in 0..1, do: [ splitter ]
  def _split(splitter, _count) do
    lo..hi = splitter.range |> normalize_range()
    mid = div(hi - lo, 2) + lo
    list = splitter.list
    lo_range = lo..mid
    hi_range = (mid + 1)..hi
    [
      %ParallelList.Splitter{list: Enum.slice(list, shift_range(lo_range, -lo)), range: lo_range},
      %ParallelList.Splitter{list: Enum.slice(list, shift_range(hi_range, -lo)), range: hi_range},
    ]
  end

  def reduce(s, { :cont, acc }, fun) do
    _reduce s.list, s.range, acc, fun
  end

  defp _reduce([], _range, acc, _fun), do: { :done, acc }
  defp _reduce([ head | tail ], lo..hi, acc, fun) do
    s = %ParallelList.Splitter{list: tail, range: (lo + 1)..hi}
    Enumerable.reduce(s, fun.(head, acc), fun)
  end

  def member?(splitter, value) do
    { :ok, Enum.member?(splitter.list, value) }
  end

  def count(splitter) do
    { :ok, Enum.count(splitter.list) }
  end

  def into(%ParallelList.Splitter{list: orig_list, range: lo..hi}) do
    { [], fn
      acc, {:cont, x} ->
        [ x | acc ]
      acc, :done ->
        ParallelList.Splitter.new(orig_list ++ Enum.reverse(acc))
      _, :halt ->
        :ok
    end}
  end

  defp normalize_range(lo..hi) when lo <= hi, do: lo..hi
  defp normalize_range(hi..lo), do: lo..hi

  defp shift_range(lo..hi, delta), do: (lo + delta)..(hi + delta)
end
