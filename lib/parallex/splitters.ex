defimpl Splittable, for: List do

  def split([]), do: [[]]
  def split([x]), do: [[x]]
  def split(list) do
    len = length list
    mid = div(len, 2)
    lo_range = 0..(mid - 1)
    hi_range = mid..(len - 1)
    [
      Enum.slice(list, lo_range),
      Enum.slice(list, hi_range),
    ]
  end
end

defimpl Splittable, for: Range do

  defp normalize(lo..hi) when lo <= hi, do: lo..hi
  defp normalize(hi..lo), do: lo..hi

  def split(lo..hi) when lo <= hi do
    mid = div(hi - lo, 2) + lo
    [ lo..mid, (mid + 1)..hi ]
  end
  def split(hi..lo) when lo <= hi do
    mid = div(hi - lo, 2) + lo
    [ hi..(mid + 1), mid..lo ]
  end
end

defimpl Splittable, for: HashDict do  # Can I just use Dict?

  def split(dict) do
    dict
      |> Dict.keys
      |> Splittable.split
      |> Enum.map(&(Dict.take(dict, &1)))
  end
end

# ???: Can I use an intermediate format so I'm not converting back and forth between lists and sets/dicts?
# I could have one function return a splitting function and another return a finalizing function.

defimpl Splittable, for: HashSet do

  def split(set) do
    set
      |> Set.to_list
      |> Splittable.split
      |> Enum.map(&(Enum.into(&1, HashSet.new)))
  end
end
